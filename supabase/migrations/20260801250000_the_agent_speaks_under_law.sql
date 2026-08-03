begin;

-- ============================================================
-- The one voice nobody was checking.
--
-- Every composed message in the product passes
-- gate_composed_reply. The conversational reply — the message
-- parents actually receive, hundreds of times a day, the only
-- one most of them will ever read — passes nothing. It goes from
-- the model to Telegram untouched.
--
-- WHY THIS IS NOT gate_composed_reply
--
-- The obvious move is to point the existing gate at this path.
-- That would be wrong, and the founder already named why: the
-- deepest problem in this product is a templated voice. The
-- existing gate enforces a LINE BUDGET and a UNIQUENESS RULE
-- alongside vocabulary, and both of those, applied to open
-- conversation, push every reply toward the same safe shape —
-- three lines, one measured token, indistinguishable from the
-- last one. That is the disease, not the cure.
--
-- So: vocabulary only. What ADAM may never SAY, never how long
-- he may say it or how distinctive it must be.
--
-- WHAT THE BLOCKING LIST IS, AND HOW IT WAS CHOSEN
--
-- Not by judgement. Every candidate rule was replayed against
-- all 2,233 replies ADAM has ever sent, and the first draft was
-- thrown away because of what that showed:
--
--   blunt rule   53 blocked (2.37%) — 1 reply in 42
--   of which     ~40 were GOOD answers
--
-- «احتواء» (33 hits) is internal jargon here and ordinary Arabic
-- for holding a child emotionally. «وافتحي ذراعيكِ» tripped the
-- ban on «افتح». «إلحاحه على الـ 50 ريالاً» is a father talking
-- about pocket money, not ADAM quoting a price. Shipping that
-- draft would have cost forty tired parents a real answer in
-- order to catch thirteen violations.
--
-- The rule below blocks 15 of 2,234 — 0.67% — and every single
-- one is ADAM selling:
--
--   sell:price 9 · sell:impersonate 9 · sell:close 8
--   brand:guarantee 4 · brand:superiority 4 · internal:latin 0
--
-- (Those sum to more than 15 because one selling reply usually
-- breaks three rules at once, which is what selling looks like.)
--
--
--   sell:price          a price ADAM has no business speaking (P17)
--   sell:close          a closing line — «جاهزة لنبدأ؟» (§3.7)
--   sell:impersonate    «تواصلي معي» beside the t.me link. AD-1 is
--                       explicit: فريق آدم is the cashier, ADAM is
--                       not, and he may not pose as them.
--   brand:guarantee     «كلمة آدم» — a refund promise invented in
--                       the brand's own name, which nobody at the
--                       company ever made
--   brand:superiority   «آدم وحده يفعل هذا»
--   internal:latin      seed / harvest / journey (§2.8)
--
-- Everything else copy_violations finds — machinery words like
-- «خطة» and «نظام» — is RECORDED AND ALLOWED. They are brand
-- violations and also ordinary Arabic. In a week there will be a
-- count instead of an opinion, and the line can move on evidence.
-- A gate tuned by guessing is a gate someone switches off.
--
-- AND THIS IS NOT A HISTORICAL PROBLEM
--
-- Sixteen of these came from 2026-07-10, under the old sales
-- prompt. But the trickle continues — 1 to 2 a day through
-- 07-31, after the prompt was rewritten. A prompt asks; a gate
-- refuses. Only one of them is load-bearing.
-- ============================================================


-- ------------------------------------------------------------
-- Where the evidence accumulates.
--
-- Deliberately not a column on anything: this is measurement,
-- and measurement that shares a table with product state gets
-- read as product state within a month.
-- ------------------------------------------------------------
create table if not exists public.reply_gate_log (
  id           bigint generated always as identity primary key,
  parent_id    uuid references public.followers(id) on delete cascade,
  blocked      boolean not null,
  violations   text[]  not null,
  body_len     integer,
  created_at   timestamptz not null default now()
);

create index if not exists reply_gate_log_created_idx
  on public.reply_gate_log (created_at desc);

comment on table public.reply_gate_log is
  'Every conversational reply that tripped the vocabulary gate, blocked or not. Exists so the blocking line can be moved on evidence rather than opinion: machinery words are recorded and allowed today, and the count decides whether they are blocked tomorrow. Never read as product state.';


-- ------------------------------------------------------------
-- gate_agent_reply — vocabulary only, and only the words that
-- can never be right.
--
-- Volatile on purpose: it writes the log. Callers get one round
-- trip, not two, because a gate that costs an extra call on the
-- hottest path in the product is a gate that gets removed for
-- latency.
-- ------------------------------------------------------------
create or replace function public.gate_agent_reply(
  p_parent_id uuid,
  p_body      text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_all     text[];
  v_hard    text[];
  v_blocked boolean;
begin
  if coalesce(btrim(p_body), '') = '' then
    -- Silence is the one output that is always wrong (§E9). An empty
    -- reply is not a vocabulary problem, but this is the last place
    -- that can see it before Telegram does.
    return jsonb_build_object('ok', false, 'blocked', true,
                              'violations', jsonb_build_array('empty'),
                              'fallback_key', 'rescue');
  end if;

  -- Everything the copy law can see, for the record.
  v_all := public.copy_violations(p_body);

  -- And separately, the narrow set that may never reach a parent. This is
  -- NOT a filter over v_all: copy_violations is tuned for STORED copy,
  -- where a human chose every word and a false positive costs nothing.
  -- Here a false positive costs a parent their answer, so the blocking
  -- rules are their own, and each one was measured against every reply
  -- ADAM has ever sent before it was allowed in.
  v_hard := '{}';

  -- A price. Grouped digits (2,300 / 14,000) are a price in this product
  -- and nothing else. A currency word needs three digits beside it, so
  -- «إلحاحه على الـ 50 ريالاً» — a father describing pocket money —
  -- survives, and «150 جنيه مصري» does not.
  if p_body ~ '[0-9]{1,3},[0-9]{3}'
     or (p_body ~ '(دينار|جنيه|درهم|ريال|دج)' and p_body ~ '[0-9٠-٩]{3}') then
    v_hard := v_hard || 'sell:price'::text;
  end if;

  -- A closing line. «اشتراك» is not «اشترك»: the noun survives, so a
  -- parent can still be told where subscription details live.
  if p_body ~ '(جاهزة? لنبدأ|جاهزة لتبدئي|اشترك|احصل على|جرّب الآن|النسخة الكاملة|الباقة)' then
    v_hard := v_hard || 'sell:close'::text;
  end if;

  -- AD-1: فريق آدم is the cashier and ADAM is not. Pointing a parent to
  -- them is correct and stays allowed; posing as them is not.
  if p_body ilike '%t.me%' and p_body ~ 'تواصل(ي|وا)? مع(ي|نا)' then
    v_hard := v_hard || 'sell:impersonate'::text;
  end if;

  -- A refund promise nobody at the company ever made, in the brand's name.
  if p_body ~ 'كلمة آدم' then
    v_hard := v_hard || 'brand:guarantee'::text;
  end if;

  if p_body ~ 'آدم وحده' then
    v_hard := v_hard || 'brand:superiority'::text;
  end if;

  if p_body ~* '(seed|harvest|engine|journey|funnel|tier|aha|llm|mirror)' then
    v_hard := v_hard || 'internal:latin'::text;
  end if;

  v_blocked := cardinality(v_hard) > 0;

  -- The log carries both: what the copy law saw, and what actually stopped
  -- the message. Without the second, next month's decision to widen or
  -- narrow the rules would again be a matter of opinion.
  v_all := (select coalesce(array_agg(distinct x order by x), '{}')
            from unnest(v_all || v_hard) x);

  if cardinality(v_all) > 0 then
    insert into public.reply_gate_log (parent_id, blocked, violations, body_len)
    values (p_parent_id, v_blocked, v_all, length(p_body));
  end if;

  return jsonb_build_object(
    'ok',          not v_blocked,
    'blocked',     v_blocked,
    'violations',  to_jsonb(v_all),
    'blocking',    to_jsonb(v_hard),
    -- Never the rescue. The rescue says "I did not understand this",
    -- and that would be false: ADAM understood perfectly and then said
    -- something he is not allowed to say. Blaming the parent for our
    -- own violation is the exact opposite of P11.
    'fallback_key', case when v_blocked then 'reply_withheld' else null end);
end;
$function$;

comment on function public.gate_agent_reply(uuid, text) is
  'The vocabulary gate for the conversational reply. Vocabulary ONLY — no line budget, no uniqueness — because both of those applied to open conversation produce the templated voice this product is trying to escape. Blocks price, promotional and internal-term violations, which can never be right; records machinery words without blocking, so the line can move on evidence.';


-- ------------------------------------------------------------
-- What a parent gets instead.
--
-- Not the rescue. The rescue means "I did not understand", and
-- on this path that is a lie — the model understood and then
-- reached for a forbidden word. Saying "I did not understand"
-- would move our fault onto the parent.
--
-- This says less than the truth but nothing false: it declines,
-- it does not explain itself (P24), it does not apologise into a
-- paragraph, and it leaves the one obvious action exactly where
-- it always is (L1).
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('reply_withheld', 'rescue', 'fixed',
   'هذه تستحق جواباً أدقّ ممّا كنت سأقول.' || chr(10) ||
   'احكوا لي أكثر عمّا حدث، وأنا معكم.',
   '[]'::jsonb, 2, false,
   'Sent when the conversational reply tripped a constitutional vocabulary rule (price, sales verb, internal term). Deliberately NOT the rescue: the rescue claims ADAM did not understand, which on this path is false and moves our fault onto the parent. Says less than the truth, nothing false, and keeps the one obvious action.')
on conflict (key) do update
  set body_ar = excluded.body_ar, category = excluded.category,
      tier = excluded.tier, max_lines = excluded.max_lines, note = excluded.note;


revoke all on function public.gate_agent_reply(uuid, text) from anon, authenticated, public;
grant execute on function public.gate_agent_reply(uuid, text) to service_role;
revoke all on public.reply_gate_log from anon, authenticated;
grant select, insert on public.reply_gate_log to service_role;

commit;
