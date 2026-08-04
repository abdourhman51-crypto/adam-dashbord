begin;

-- ============================================================
-- The 59 cannot be waited for.
--
-- country_state() gave ADAM three honest answers, and /journey
-- asks the question when a parent walks into it. That fixes the
-- sentence. It does not fix the cohort.
--
--   59 parents with an unknown country
--   32 of them active in the last 21 days
--   29 of them have spoken three times or more
--    9 of them have named their child
--
-- These are not lurkers. They are engaged families, and they are
-- the ONE group ADAM can never write to first: get_rhythm_due
-- joins country_timezone, so with no clock there is no honest
-- hour, and with no honest hour there is no message. They are
-- locked out of the only mechanism that makes ADAM ADAM, and
-- they cannot let themselves back in, because the door is a menu
-- item they have no reason to tap.
--
-- Waiting for them to open /journey is waiting for a parent to
-- ask about a price in order to receive a free thing.
--
-- WHY THIS IS ONE LINE AND NOT A FLOW
--
-- The precedent is proactive_first_footer: one sentence, once
-- ever, appended to a message that was going to be sent anyway.
-- It obeys every law — one send, one moment, and the buttons ARE
-- the answer (L2), so there is no typing and no second step.
--
-- It is also the only question in the product that states its own
-- reason in the same breath, because the reason is the entire
-- justification for asking: we want to know WHEN to write, not
-- where to bill. A parent who reads it as billing would be right
-- to refuse, so the sentence must not be about money at all.
--
-- ONCE. EVER. Whatever the answer.
--
-- The debt is a fact about the PERSON (country_asked_at), not
-- about the message — the exact error that cost six families the
-- consent footer on 2026-08-01, where "is this the first seed?"
-- became false the instant the seed sent, footer or no footer.
-- Stamped when ASKED, not when answered: a parent who ignores it
-- has answered.
-- ============================================================

alter table public.followers
  add column if not exists country_asked_at timestamptz;

comment on column public.followers.country_asked_at is
  'When ADAM asked this parent where they are. Set when ASKED, never when answered — ignoring the question is an answer, and asking twice would make it a form. A fact about the person, not about a message: the message-shaped version of this idea silently cancelled a debt to six families.';


-- ------------------------------------------------------------
-- should_ask_country — narrow on purpose.
--
-- Three conditions, and each one removes a way to be annoying:
--
--   unknown       we do not ask people we can already place.
--   never asked   once, ever.
--   has spoken    a stranger who has said one thing is not owed
--                 a question; they are owed an answer.
--
-- Deliberately NOT gated on a named child. That would be the
-- tidier rule and it would be wrong: the clock is what unlocks
-- the rhythm, and the rhythm is what earns the name. Requiring
-- the name first makes the two facts wait for each other.
-- ------------------------------------------------------------
create or replace function public.should_ask_country(p_parent_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
  select
    coalesce((public.country_state(p_parent_id)->>'state') = 'unknown', false)
    and exists (select 1 from public.followers f
                 where f.id = p_parent_id and f.country_asked_at is null)
    and coalesce((select e.human_messages from public.v_parent_engagement e
                   where e.parent_id = p_parent_id), 0) >= 3;
$function$;

comment on function public.should_ask_country(uuid) is
  'Whether this parent should be asked where they are, once ever. Narrow by design: unknown country, never asked, and has actually spoken. A parent we can already place is never asked, because we do not ask for what we already have.';


-- ------------------------------------------------------------
-- record_country_ask — settles the debt at the moment of asking.
-- ------------------------------------------------------------
create or replace function public.record_country_ask(p_parent_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  update public.followers
     set country_asked_at = now()
   where id = p_parent_id and country_asked_at is null;
  return found;
end;
$function$;

comment on function public.record_country_ask(uuid) is
  'Stamps the country question as asked. Idempotent: a second call returns false and does not move the timestamp, so a retried send can never turn one question into two.';


-- ------------------------------------------------------------
-- The sentence itself.
--
-- What it does NOT say is the design:
--   no price, no country list in prose, no «الرحلة», no apology,
--   no explanation of how ADAM works (P24).
--
-- What it does say is the true reason, which is about time, not
-- money. «متى أكتب لكم» is exactly what the clock buys.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('country_ask_footer', 'reference', 'fixed',
   'سؤال واحد، حتى أعرف متى أكتب لكم: من أي بلد أنتم؟',
   jsonb_build_array(
     jsonb_build_object('label','الجزائر',  'cb','set_country_DZ'),
     jsonb_build_object('label','مصر',     'cb','set_country_EG'),
     jsonb_build_object('label','المغرب',   'cb','set_country_MA'),
     jsonb_build_object('label','بلد آخر', 'cb','set_country_OTHER'),
     -- The escape hatch. A question ADAM asks uninvited must be one the
     -- parent can decline, or it is not a question. chk_escape_hatch
     -- refused this row until it was here — see the note below on why
     -- that refusal was the most useful thing that happened today.
     jsonb_build_object('label','شيء آخر', 'cb','other')),
   1, false,
   'Appended once, ever, to a reply that was being sent anyway, for a parent whose country we do not know. Not about price: without a local clock the daily rhythm has no honest hour, so these families can never be written to first. The buttons are the answer (L2) — no typing, no second step.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      tier = excluded.tier, max_lines = excluded.max_lines, note = excluded.note;


-- ------------------------------------------------------------
-- A law that only guards the stored copy is half a law.
--
-- chk_escape_hatch refused country_ask_footer for having four
-- buttons and no way out. It was right, and the same check then
-- exposed something it could never have caught: the /journey
-- answer for an unknown country builds its buttons AT RUNTIME,
-- inside get_conversation_moment, so it never passes through the
-- constraint at all. It shipped this morning with four countries
-- and no «شيء آخر» — a parent who opened /journey out of
-- curiosity had no way to leave without answering.
--
-- Composed copy escapes the constraints that guard stored copy.
-- Every runtime-built button set in the product is now listed in
-- country_state_test.sql and checked there, because the database
-- cannot check what it never stores.
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
  m         public.conversation_moments%rowtype;
  v_cs      jsonb;
  v_body    text;
  v_buttons jsonb;
  v_nl      text := chr(10);
begin
  select * into m from public.conversation_moments where key = p_key;
  if not found then
    return jsonb_build_object('found', false, 'key', p_key);
  end if;

  if m.requires_commerce and p_parent_id is not null
     and not coalesce(public.commerce_allowed(p_parent_id), true) then
    return jsonb_build_object('found', true, 'key', p_key, 'allowed', false,
                              'reason', 'commerce_blocked');
  end if;

  v_body    := m.body_ar;
  v_buttons := m.buttons;

  if p_key = 'menu_journey' then
    v_cs := public.country_state(p_parent_id);

    if (v_cs->>'state') = 'supported' then
      -- The price is read from supported_countries, per country, at read
      -- time. It is stored in exactly one place and spoken in exactly one.
      v_body :=
        'المرافقة اليومية التي بيننا الآن تبقى كما هي — مجاناً، دائماً.' || v_nl || v_nl ||
        'وحين يظهر هدف واضح لطفلكم — ليالٍ أهدأ، أو صباح بلا معركة —' || v_nl ||
        'يمكن أن نبني له رحلة: نمشي إليه يوماً بيوم حتى نصل،' || v_nl ||
        'أو حتى نعرف أنه لا يصلح، وأقولها لكم بصراحة.' || v_nl || v_nl ||
        'الرحلة الواحدة: ' || (v_cs->>'price') || '.' || v_nl || v_nl ||
        'التفاصيل وطرق الدفع — فريق آدم يسعده مساعدتكم:' || v_nl ||
        'https://t.me/Abdouleg';
      v_buttons := '[]'::jsonb;

    elsif (v_cs->>'state') = 'unknown' then
      -- We do not know where they are. Saying "not yet in your country"
      -- here would be a sentence we cannot stand behind. Ask instead --
      -- and the answer also unblocks the daily rhythm, which needs a
      -- local clock before it can write at an honest hour.
      v_body :=
        'المرافقة الكاملة تختلف من بلد لآخر — السعر وطريقة الدفع محليّان.' || v_nl || v_nl ||
        'من أي بلد أنتم؟';
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','الجزائر',  'cb','set_country_DZ'),
        jsonb_build_object('label','مصر',     'cb','set_country_EG'),
        jsonb_build_object('label','المغرب',   'cb','set_country_MA'),
        jsonb_build_object('label','بلد آخر', 'cb','set_country_OTHER'),
        -- Added after the fact. Without it this branch asked a question
        -- with no way out, which is the one thing the button law exists
        -- to prevent, and it got here by being composed instead of stored.
        jsonb_build_object('label','شيء آخر', 'cb','other'));

    else
      v_body :=
        'آدم يرافقكم بالكامل، كما يرافق الجميع.' || v_nl ||
        'كل ما بيننا الآن يبقى كما هو، دون نقص.' || v_nl || v_nl ||
        'والرحلات المدفوعة لم تصل بلدكم بعد، لسبب واحد:' || v_nl ||
        'لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.' || v_nl ||
        'وحين تتوفّر، تصلكم رسالة.';
      v_buttons := '[{"label":"أخبروني حين يصل","cb":"waitlist_join"},{"label":"شيء آخر","cb":"other"}]'::jsonb;
    end if;

  elsif v_body is null then
    v_body := public.compose_menu_body(p_key, p_parent_id);
  end if;

  if v_body is null or btrim(v_body) = '' then
    return jsonb_build_object('found', false, 'key', p_key,
                              'reason', 'composed_to_nothing');
  end if;

  return jsonb_build_object(
    'found', true, 'key', m.key, 'allowed', true, 'category', m.category,
    'tier', m.tier, 'body', v_body, 'buttons', v_buttons,
    'buttons_forbidden', m.buttons_forbidden, 'max_lines', m.max_lines);
end;
$function$;


revoke all on function public.should_ask_country(uuid) from anon, authenticated, public;
revoke all on function public.record_country_ask(uuid) from anon, authenticated, public;
grant execute on function public.should_ask_country(uuid) to service_role;
grant execute on function public.record_country_ask(uuid) to service_role;

commit;
