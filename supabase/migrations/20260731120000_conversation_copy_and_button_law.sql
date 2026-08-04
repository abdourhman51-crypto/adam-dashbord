begin;

-- ============================================================
-- The Conversation layer: copy, buttons, and the rules that
-- cannot be broken by whoever writes the next prompt.
-- (architecture §3, §9, §0.7)
--
-- WHY THIS IS A TABLE AND NOT A PROMPT
--
-- §0.7 bans thirteen machinery words and seven promotional verbs
-- from every user-facing string, and §3.1 requires "شيء آخر" on
-- every button set. Both were, until now, sentences in a document.
--
-- This project has twice learned what that is worth. message_count
-- sat frozen at 0 because a counter was a convention. safe_for_record
-- needed a transaction-bound audit row because a prompt-level rule
-- is not a rule. A style guide that lives only in a document is the
-- same class of thing: it holds until someone is in a hurry.
--
-- So the vocabulary bans become CHECK constraints, and a violating
-- string cannot be stored. The word اشتراك in a live message is
-- now a constraint violation at write time rather than something
-- a parent finds first.
--
-- ONE RULE, BOTH TIERS. copy_violations() is called by the CHECK on
-- fixed copy AND is callable at runtime on whatever the LLM just
-- composed. Fixed and generated text are held to the same standard
-- by the same function, which is the only way the standard stays
-- one standard.
-- ============================================================


-- ------------------------------------------------------------
-- content_line_count — P6's line budget, counted honestly.
-- Blank lines are spacing, not content; §9's approved messages
-- use them and should not be punished for breathing.
-- ------------------------------------------------------------
create or replace function public.content_line_count(p_text text)
returns integer
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select count(*)::integer
  from regexp_split_to_table(coalesce(p_text, ''), E'\n') as l
  where btrim(l) <> '';
$function$;

comment on function public.content_line_count(text) is
  'Non-empty lines in a message. Blank lines are spacing, not content (P6).';


-- ------------------------------------------------------------
-- copy_violations — §0.7 made mechanical.
--
-- Returns every reason a string may not be said to a parent, not
-- just the first. A writer fixing one word at a time across five
-- round trips is a writer who stops using the check.
--
-- Substring matching, not word boundaries, and that is deliberate:
-- Arabic attaches ال و ب ل as prefixes, so \y would let الاشتراك
-- through while catching اشتراك. Stems were chosen so substring
-- matching does not overreach — دج was dropped from the currency
-- list because دجاج is a word a parent may hear about at dinner.
-- ------------------------------------------------------------
create or replace function public.copy_violations(p_text text)
returns text[]
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select coalesce(array_agg(v order by v), array[]::text[])
  from (
    -- Machinery. The parent is in a relationship, not operating a tool.
    select 'machinery:' || w as v
    from unnest(array[
      'ذاكرة','تقارير','تقرير','متابعة','خطة','ذكاء','اشتراك',
      'ميزات','نظام','تحليل','دفتر','أتمتة','تتبّع','تتبع'
    ]) as w
    where coalesce(p_text,'') like '%' || w || '%'

    union all
    -- The promotional register (P21). Any verb instructing acquisition.
    select 'promotional:' || w
    from unnest(array[
      'افتح','فعّل','اشترك','احصل على','جرّب الآن','النسخة الكاملة','الباقة'
    ]) as w
    where coalesce(p_text,'') like '%' || w || '%'

    union all
    -- Internal lexicon (§0.7 hard rule). These belong in specs and
    -- code. One in a live string is a defect, in either script.
    select 'internal:' || w
    from unnest(array['احتواء','محرّك','محرك']) as w
    where coalesce(p_text,'') like '%' || w || '%'

    union all
    select 'internal:latin'
    where coalesce(p_text,'') ~* '(seed|harvest|engine|journey|funnel|tier|aha|llm|mirror)'

    union all
    -- Price. ADAM never speaks one (P17). Every real price is three
    -- digits or more, in either numeral system; approved copy writes
    -- small counts as words ("خمس ليالٍ من سبع").
    select 'price:digits'
    where coalesce(p_text,'') ~ '[0-9]{3}' or coalesce(p_text,'') ~ '[٠-٩]{3}'

    union all
    select 'price:currency:' || w
    from unnest(array['دينار','جنيه','درهم','ريال']) as w
    where coalesce(p_text,'') like '%' || w || '%'
  ) t;
$function$;

comment on function public.copy_violations(text) is
  'Every reason a string may not be said to a parent: machinery vocabulary, the promotional register, internal lexicon, price. §0.7 and P17 made mechanical. Used by the CHECK on fixed copy AND callable at runtime on LLM output, so both tiers are held to one standard.';


-- ------------------------------------------------------------
-- buttons_wellformed — shape only, so the law below reads clearly.
-- ------------------------------------------------------------
create or replace function public.buttons_wellformed(p_buttons jsonb)
returns boolean
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select p_buttons is not null
     and jsonb_typeof(p_buttons) = 'array'
     and not exists (
       select 1 from jsonb_array_elements(p_buttons) as b
       where jsonb_typeof(b) <> 'object'
          or coalesce(btrim(b->>'label'), '') = ''
          or coalesce(btrim(b->>'cb'), '')    = ''
          or cardinality(public.copy_violations(b->>'label')) > 0
     );
$function$;

comment on function public.buttons_wellformed(jsonb) is
  'A button array where every entry has a non-empty label and callback, and no label violates §0.7. Button labels are user-facing strings and are held to the same vocabulary law as message bodies.';


-- ------------------------------------------------------------
-- conversation_moments — every moment ADAM has, and its law.
-- ------------------------------------------------------------
create table if not exists public.conversation_moments (
  key               text primary key,
  category          text     not null check (category in (
                      'greeting','rescue','rhythm','goal','strain','crisis',
                      'menu','review','referral')),
  tier              text     not null check (tier in ('fixed','composed')),
  body_ar           text,
  buttons           jsonb    not null default '[]'::jsonb,
  buttons_forbidden boolean  not null default false,
  max_lines         smallint not null default 3 check (max_lines between 1 and 12),
  requires_commerce boolean  not null default false,
  note              text     not null,
  created_at        timestamptz not null default now(),

  -- Fixed copy is stored and checked here. Composed copy is written by
  -- the LLM at send time and checked by the same function then.
  constraint chk_tier_body check (
    (tier = 'fixed'    and body_ar is not null) or
    (tier = 'composed' and body_ar is null)),

  -- §3.1: "شيء آخر" on every button set, without exception. A button
  -- set without an escape is an interrogation.
  constraint chk_escape_hatch check (
    buttons_forbidden
    or jsonb_array_length(buttons) = 0
    or buttons @> '[{"cb":"other"}]'::jsonb),

  -- §9.6, the one exception to Decision 014, recorded so that nobody
  -- adds a button back to satisfy 014. A parent who has just disclosed
  -- violence must not be handed a set of options to choose from.
  constraint chk_crisis_has_no_buttons check (
    not buttons_forbidden or jsonb_array_length(buttons) = 0),

  constraint chk_buttons_wellformed check (public.buttons_wellformed(buttons)),

  -- §0.7 and P17. The reason this layer is a table.
  constraint chk_body_clean check (
    body_ar is null or cardinality(public.copy_violations(body_ar)) = 0),

  -- P6. Three content lines, and the exceptions are named rather than
  -- available: only a goal becoming visible, a review, or a crisis may
  -- run long. A rescue reply can never quietly grow into an essay.
  constraint chk_line_budget check (
    max_lines <= 3 or category in ('goal','review','crisis')),
  constraint chk_body_within_budget check (
    body_ar is null or public.content_line_count(body_ar) <= max_lines),

  -- Crisis is the one category that must never be gated on commerce,
  -- and never gates commerce on itself.
  constraint chk_crisis_not_commercial check (
    category <> 'crisis' or requires_commerce = false)
);

comment on table public.conversation_moments is
  'Every moment ADAM has, with its copy, its buttons, and the constraints from §0.7/§3.1/§9 enforced in the data. Fixed copy is stored; composed copy is written at send time and validated by the same copy_violations() function. A violating string cannot be stored.';

comment on column public.conversation_moments.tier is
  'fixed = the exact words, from architecture §9. composed = the LLM writes it, and copy_violations() is applied to the output before sending.';

comment on column public.conversation_moments.buttons_forbidden is
  'True only for crisis. §9.6 is the single place in the product where a button set is absent, including "شيء آخر", and this column exists so the absence is deliberate rather than an oversight someone helpfully corrects.';


-- ------------------------------------------------------------
-- The moments themselves.
-- ------------------------------------------------------------
insert into public.conversation_moments (key, category, tier, body_ar, buttons, buttons_forbidden, max_lines, requires_commerce, note) values

('first_contact', 'greeting', 'fixed',
 E'السلام عليكم 🌿\nأنا آدم.\nماذا حدث؟ الكتابة أو التسجيل الصوتي — كلاهما يصل.',
 '[]'::jsonb, false, 3, false,
 '§9.1. No name, country or age request. The keyboard and menu are already visible, which is what makes the commercial model impossible to be surprised by later.'),

('rescue', 'rescue', 'composed', null,
 '[{"label":"كيف أفعلها بالضبط؟","cb":"how_exactly"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 3, false,
 '§9.2. Cause without blame, one small thing specific to tonight, how it will be recognisable. "كيف أفعلها بالضبط؟" must get a complete answer — knowledge is free (§3.2).'),

('seed', 'rhythm', 'composed', null,
 '[]'::jsonb, false, 3, false,
 '§9.3. Composed from grounded Knowledge only; record_seed_sent rejects an ungrounded one. No buttons: a morning thought is not a question.'),

('seed_thin_knowledge', 'rhythm', 'fixed',
 E'صباح الخير 🌿\nحتى تكون التجربة على مقاس ابنك: ما اسمه، وكم عمره؟',
 '[]'::jsonb, false, 3, false,
 '§9.3. Sent ONCE when can_ground_seed() refuses, never repeated daily. Silence beats a generic tip (§2.5).'),

('harvest_ask', 'rhythm', 'fixed',
 'كيف كانت التجربة اليوم؟',
 '[{"label":"نجحت","cb":"ck_step_ok"},{"label":"جرّبناها وما نجحت","cb":"ck_step_failed"},{"label":"ما صارت الفرصة","cb":"ck_step_skip"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 1, false,
 '§9.4. The child name and the experiment are interpolated at send time. "جرّبناها" is first-person plural: gender-free, and it stops implying the outcome belonged to the parent alone (§0.7).'),

('harvest_reply_ok', 'rhythm', 'fixed',
 E'هذه خطوة حقيقية.\nنبني عليها غداً.',
 '[]'::jsonb, false, 2, false,
 '§9.4.'),

('harvest_reply_failed', 'rhythm', 'fixed',
 E'المحاولة نفسها تغيّر شيئاً.\nغداً زاوية أخرى.',
 '[]'::jsonb, false, 2, false,
 '§9.4. Never treated as a failure — the attempt is the unit of progress.'),

('harvest_reply_skip', 'rhythm', 'fixed',
 E'لا بأس.\nليس كل يوم يحتمل تجربة.',
 '[]'::jsonb, false, 2, false,
 '§9.4. Must never carry disappointment. A parent who feels judged for not trying stops answering, and the Harvest is the entire proof engine.'),

('goal_visible', 'goal', 'composed', null,
 '[{"label":"كيف نبدأ؟","cb":"how_start"},{"label":"ليس الآن","cb":"not_now"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 8, true,
 '§9.5. The single most important message in the commercial model, and it contains no commerce. Composed because the goal is this family''s. "ليس الآن" costs nothing and is never followed up.'),

('referral', 'referral', 'fixed',
 E'تفاصيل الرحلة وطرق الدفع — فريق آدم يسعده مساعدتك:\nhttps://t.me/Abdouleg\n\nوأنا أبقى معك في كل ما يخصّ علاقتك بطفلك.',
 '[]'::jsonb, false, 3, true,
 '§6.7 / AD-1. The last thing ADAM says about it, ever, unless asked. The closing line is the point: a division of labour, not an exit. The child name is interpolated at send time.'),

('strain_l2', 'strain', 'fixed',
 E'هذا كثير على شخص واحد.\n\nلا شيء مطلوب اليوم — لا تجربة ولا خطوة.\nأنا هنا فقط.',
 '[]'::jsonb, false, 3, false,
 '§9.6. No Seed the next morning, no goal, no commercial surface, and nothing announced. The parent never senses a mode change (§0.7).'),

('strain_l3', 'crisis', 'fixed',
 E'أنا هنا.\nهذا الحِمل أثقل من أن يُحمل وحده.\nأنا هنا. ولا شيء مطلوب الآن.',
 '[]'::jsonb, true, 4, false,
 '§9.6. buttons_forbidden. The category-specific line and any vetted referral are appended at send time. ADAM never invents a helpline: a wrong number given to a parent in danger is worse than none (§16 D2).'),

('review_stage4', 'review', 'fixed',
 E'إن أحببت أن نعمل على هذا أيضاً، يمكننا أن نبني له رحلة تناسب وضعكم الآن.\n\nوإن اكتفيت بالمرافقة اليومية، أبقى معك كما كنت تماماً.',
 '[{"label":"نعم، نعمل عليه","cb":"review_yes"},{"label":"نكمل كما نحن","cb":"review_stay"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 4, true,
 '§6.6. Skipped entirely in unsupported countries and at L2/L3. No follow-up, no second mention, ever.'),

-- ---- Menu taps. One per meaning the Telegram surface can emit, so
-- ---- the UX/Conversation contract is closed rather than assumed.

('menu_child', 'menu', 'composed', null, '[]'::jsonb, false, 3, false,
 'Fixed menu item 1. What ADAM knows about this child, in the parent''s words back to them.'),

('menu_progress', 'menu', 'composed', null, '[]'::jsonb, false, 3, false,
 'Fixed menu item 2. Below three logged evenings this is the honest empty state, never a chart (§4.5).'),

('menu_settings', 'menu', 'fixed',
 E'متى يصلك الكلام، ومتى نصمت — كما تحب.\nويمكن الإيقاف في أي وقت، ويبقى الحديث مفتوحاً.',
 '[{"label":"أوقات أهدأ","cb":"quiet_hours"},{"label":"إيقاف الرسائل","cb":"pause"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 3, false,
 'Fixed menu item 4. Pausing must never cost the conversation — that is what makes it safe to use.'),

('menu_privacy', 'menu', 'fixed',
 E'ما تقوله يبقى بينكم وبيني.\nويمكن حذف كل شيء متى شئت، دون أسئلة.',
 '[{"label":"حذف كل بياناتي","cb":"erase"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 3, false,
 'Fixed menu item 5. "دون أسئلة" is binding: erasure is not a retention conversation.'),

('menu_open_question', 'menu', 'composed', null, '[]'::jsonb, false, 3, false,
 'Changing item, meaning=open_question. Describes what is currently possible; never promotes (P21).'),

('menu_journey_progress', 'menu', 'composed', null, '[]'::jsonb, false, 3, false,
 'Changing item, meaning=journey_progress. Where the journey stands, against its own falsifiable goal.'),

('menu_next_goal', 'menu', 'composed', null, '[]'::jsonb, false, 3, false,
 'Changing item, meaning=next_goal. What the data suggests comes after — discovered, not offered.'),

('menu_resume', 'menu', 'fixed',
 E'الرسائل متوقفة الآن، والحديث مفتوح كما هو.\nومتى أردت، نعود إلى الإيقاع اليومي.',
 '[{"label":"نعود من الغد","cb":"resume_tomorrow"},{"label":"نبقى كما نحن","cb":"stay_paused"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 3, false,
 'Changing item, meaning=resume. No "we miss you" (§4.5). Staying paused is a first-class answer.'),

('menu_lighten_load', 'menu', 'composed', null, '[]'::jsonb, false, 3, false,
 'Changing item, meaning=lighten_load. Shown at strain L2/L3 in place of anything commercial (P1, AD-2). Composed, because what would lighten the load is specific to what was said. Nothing here may read as a task.'),

('menu_waitlist', 'menu', 'fixed',
 E'آدم لم يصل إلى بلدكم بعد بشكل كامل.\nوكل ما نفعله معاً الآن يبقى كما هو، دون نقص.',
 '[{"label":"أخبروني حين يصل","cb":"waitlist_join"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
 false, 3, false,
 'Changing item, meaning=waitlist. §4.7: the free experience is full and identical, and the second line says so plainly rather than leaving it to be inferred.')

on conflict (key) do nothing;


-- ------------------------------------------------------------
-- get_conversation_moment — what to say, and what may be tapped.
--
-- Refuses commercial moments the parent may not receive, rather
-- than returning them and trusting the caller to check. Every
-- engine that forgets a guard is a guard that does not exist.
-- ------------------------------------------------------------
create or replace function public.get_conversation_moment(
  p_key       text,
  p_parent_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  m public.conversation_moments%rowtype;
begin
  select * into m from public.conversation_moments where key = p_key;
  if not found then
    return jsonb_build_object('found', false, 'key', p_key);
  end if;

  if m.requires_commerce and p_parent_id is not null
     and not coalesce(public.commerce_allowed(p_parent_id), true) then
    -- Not an error and not a substitute message. The caller asked
    -- whether this may be said; the answer is no.
    return jsonb_build_object(
      'found', true, 'key', p_key, 'allowed', false,
      'reason', 'commerce_blocked');
  end if;

  return jsonb_build_object(
    'found',   true,
    'key',     m.key,
    'allowed', true,
    'category', m.category,
    'tier',     m.tier,
    'body',     m.body_ar,
    'buttons',  m.buttons,
    'buttons_forbidden', m.buttons_forbidden,
    'max_lines', m.max_lines);
end;
$function$;

comment on function public.get_conversation_moment(text, uuid) is
  'What ADAM may say at a given moment, and what may be tapped. Returns allowed=false for a commercial moment a parent may not receive, rather than returning it and trusting the caller to check.';


-- ------------------------------------------------------------
-- validate_outgoing — the gate composed text must pass.
--
-- The whole point of copy_violations() being one function: the
-- LLM's output is held to the rule the table is held to.
-- ------------------------------------------------------------
create or replace function public.validate_outgoing(
  p_key  text,
  p_body text)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_max   smallint;
  v_lines integer;
  v_viol  text[];
begin
  select max_lines into v_max from public.conversation_moments where key = p_key;
  v_max   := coalesce(v_max, 3);
  v_lines := public.content_line_count(p_body);
  v_viol  := public.copy_violations(p_body);

  if cardinality(v_viol) > 0 then
    return jsonb_build_object('ok', false, 'reason', 'vocabulary',
                              'violations', to_jsonb(v_viol));
  end if;

  if v_lines > v_max then
    return jsonb_build_object('ok', false, 'reason', 'too_long',
                              'lines', v_lines, 'max_lines', v_max);
  end if;

  if coalesce(btrim(p_body), '') = '' then
    return jsonb_build_object('ok', false, 'reason', 'empty');
  end if;

  return jsonb_build_object('ok', true, 'lines', v_lines);
end;
$function$;

comment on function public.validate_outgoing(text, text) is
  'The gate every composed message passes before sending. Applies copy_violations() and the moment''s line budget to LLM output, so generated text is held to the same law as stored copy. A failure is a message not sent, not a message sent with a warning logged.';


alter table public.conversation_moments enable row level security;
create policy service_read on public.conversation_moments
  for select to service_role using (true);
grant select on public.conversation_moments to service_role;

revoke all on function public.content_line_count(text)              from anon, authenticated, public;
revoke all on function public.copy_violations(text)                 from anon, authenticated, public;
revoke all on function public.buttons_wellformed(jsonb)             from anon, authenticated, public;
revoke all on function public.get_conversation_moment(text, uuid)   from anon, authenticated, public;
revoke all on function public.validate_outgoing(text, text)         from anon, authenticated, public;

grant execute on function public.content_line_count(text)            to service_role;
grant execute on function public.copy_violations(text)               to service_role;
grant execute on function public.buttons_wellformed(jsonb)           to service_role;
grant execute on function public.get_conversation_moment(text, uuid) to service_role;
grant execute on function public.validate_outgoing(text, text)       to service_role;

commit;
