begin;

-- ============================================================
-- Child name capture — the one thing that unblocks the rhythm.
-- (architecture §2.4 level 1, §2.5)
--
-- Live state before this migration: 299 parents, 3 children,
-- ONE parent with a named child. W1 never wrote to `children`,
-- so for 298 of 299 parents knowledge_depth() is 0 and
-- can_ground_seed() is false — and get_situation_batch() only
-- considers parents who already have a named child, so situation
-- detection could not start either.
--
-- The whole rhythm hangs off this single fact. Nothing else in
-- the chain is broken; it has simply never had a name to work
-- with.
--
-- ON §2.8. This reads conversation, which proactive messages may
-- never do. That is consistent, not an exception: the rule is
-- that proactive messages may not be GROUNDED in what a parent
-- disclosed. A name is identity, and family_tokens() classes it
-- as `identity` — which is explicitly never sufficient on its own
-- to justify a proactive message. Extraction reads the
-- conversation; grounding still may not.
-- ============================================================


-- ------------------------------------------------------------
-- child_name_plausible — the shape gate.
--
-- An LLM reading a distressed parent's free text will sometimes
-- return a sentence, a relation word, or a fragment of whatever
-- was being described. None of those are names, and a wrong name
-- is worse than no name: it is spoken back to the parent in every
-- Seed thereafter.
--
-- So the shape is checked in SQL, where it gives the same answer
-- twice (§2.2 tier 1), rather than trusted from the model.
-- ------------------------------------------------------------
create or replace function public.child_name_plausible(p_name text)
returns boolean
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select
    p_name is not null
    and btrim(p_name) <> ''
    and char_length(btrim(p_name)) between 2 and 24
    -- One or two words. Arabic given names are not sentences.
    and array_length(regexp_split_to_array(btrim(p_name), '\s+'), 1) <= 2
    -- No digits, no punctuation, no Latin. A name that needs these is not a name.
    and btrim(p_name) !~ '[0-9]'
    and btrim(p_name) !~ '[[:punct:]]'
    and btrim(p_name) !~ '[A-Za-z]'
    -- Relation words and placeholders. The model reaches for these when it
    -- has not actually found a name, and they are the exact strings
    -- v_child_record already treats as "no name".
    and btrim(p_name) not in (
      'الطفل','الطفلة','طفلي','طفلتي','ابني','ابنتي','بنتي','ولدي',
      'الولد','البنت','الصغير','الصغيرة','أخي','أختي','زوجي','زوجتي',
      'أمي','أبي','نفسي','أنا','هو','هي');
$function$;

comment on function public.child_name_plausible(text) is
  'Shape gate for an extracted child name: 1-2 words, 2-24 chars, no digits, punctuation or Latin, and not a relation word or placeholder. A wrong name is worse than no name because it is spoken back to the parent in every Seed thereafter.';


-- ------------------------------------------------------------
-- get_child_name_batch — who is worth asking the model about.
--
-- Parents with enough conversation to have plausibly said a name,
-- and no named child yet. Returns the recent turns so the caller
-- does not assemble context of its own.
--
-- Only the parent's own messages are returned. ADAM's replies
-- would feed his own guesses back to him, and a name he invented
-- once would then be extracted as fact.
-- ------------------------------------------------------------
create or replace function public.get_child_name_batch(p_limit integer default 25)
returns table (
  parent_id        uuid,
  platform_user_id text,
  human_messages   integer,
  transcript       text)
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
  select
    f.id,
    f.platform_user_id,
    coalesce(e.human_messages, 0)::integer,
    (select string_agg(t.content, E'\n' order by t.created_at desc)
       from (
         select h.created_at, btrim(h.message->>'content') as content
         from public.n8n_chat_histories h
         where public.normalise_session_key(h.session_id) = f.platform_user_id
           and h.message->>'type' = 'human'
           and btrim(coalesce(h.message->>'content','')) <> ''
         order by h.created_at desc
         limit 40
       ) t)
  from public.followers f
  join public.v_parent_engagement e on e.parent_id = f.id
  where coalesce(e.human_messages, 0) >= 2
    and not exists (
      select 1 from public.children c
      where c.follower_id = f.id
        and public.child_name_plausible(c.name))
    and not exists (
      select 1 from public.erasure_requests er
      where er.parent_id = f.id and er.completed_at is not null)
  order by e.last_message_at desc nulls last
  limit p_limit;
$function$;

comment on function public.get_child_name_batch(integer) is
  'Parents with conversation but no plausibly-named child, with their own recent turns. ADAM''s replies are excluded on purpose: feeding his own guesses back to him would let a name he invented once be extracted as fact.';


-- ------------------------------------------------------------
-- commit_child_name — the only sanctioned way a name is written.
--
-- Refuses rather than raises, so a batch of 25 does not abort on
-- one bad extraction.
--
-- NEVER OVERWRITES an existing plausible name. If ADAM already
-- knows the child as يوسف, a later low-quality extraction may not
-- replace it. Correcting a name is a conversation with the
-- parent, not a background job.
-- ------------------------------------------------------------
create or replace function public.commit_child_name(
  p_parent_id  uuid,
  p_name       text,
  p_age_note   text default null,
  p_confidence text default 'low')
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_name     text := btrim(regexp_replace(coalesce(p_name,''), '\s+', ' ', 'g'));
  v_existing uuid;
  v_blank    uuid;
  v_child    uuid;
begin
  if not exists (select 1 from public.followers f where f.id = p_parent_id) then
    return jsonb_build_object('committed', false, 'reason', 'no_such_parent');
  end if;

  -- Only a confident extraction may write. "Probably يوسف" is not a name.
  if coalesce(p_confidence, 'low') <> 'high' then
    return jsonb_build_object('committed', false, 'reason', 'low_confidence');
  end if;

  if not public.child_name_plausible(v_name) then
    return jsonb_build_object('committed', false, 'reason', 'implausible_name');
  end if;

  select c.id into v_existing
  from public.children c
  where c.follower_id = p_parent_id
    and public.child_name_plausible(c.name)
  limit 1;

  if v_existing is not null then
    return jsonb_build_object('committed', false, 'reason', 'already_named',
                              'child_id', v_existing);
  end if;

  -- Reuse a nameless row if one exists — W1 may have created a child
  -- shell — rather than leaving an orphan beside the named one.
  select c.id into v_blank
  from public.children c
  where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at
  limit 1;

  if v_blank is not null then
    update public.children
       set name     = v_name,
           age_note = coalesce(nullif(btrim(p_age_note), ''), age_note)
     where id = v_blank
    returning id into v_child;
  else
    insert into public.children (follower_id, name, age_note, is_primary)
    values (p_parent_id, v_name, nullif(btrim(p_age_note), ''), true)
    returning id into v_child;
  end if;

  return jsonb_build_object('committed', true, 'child_id', v_child, 'name', v_name);
end;
$function$;

comment on function public.commit_child_name(uuid, text, text, text) is
  'The only sanctioned way a child name is written. Requires high confidence and a plausible shape, and NEVER overwrites an existing plausible name — correcting a name is a conversation with the parent, not a background job. Returns a refusal rather than raising, so one bad extraction does not abort a batch.';


revoke all on function public.child_name_plausible(text)                    from anon, authenticated, public;
revoke all on function public.get_child_name_batch(integer)                 from anon, authenticated, public;
revoke all on function public.commit_child_name(uuid, text, text, text)     from anon, authenticated, public;

grant execute on function public.child_name_plausible(text)                 to service_role;
grant execute on function public.get_child_name_batch(integer)              to service_role;
grant execute on function public.commit_child_name(uuid, text, text, text)  to service_role;

commit;
