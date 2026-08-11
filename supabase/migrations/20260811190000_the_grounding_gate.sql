-- ============================================================
-- The grounding gate — ADAM cannot get a hallucinated claim past it.
-- Design: docs/adam-under-the-microscope.md, The ADAM Contract.
--
-- Not a prompt instruction. A deterministic, offline-tested function that
-- runs on every reply, on the same call the vocabulary law already makes,
-- and rejects three narrow, high-precision classes of unsupported claim:
--
--   memory:announced   — "I remember" / "as I have recorded" phrasing.
--                         Unconditional: this is never true in a system
--                         that composes fresh each time, at any level.
--   memory:past_reference — "last time we talked" / a previous session.
--                         Unconditional, same reasoning.
--   pattern:unfounded  — a repetition/count claim ("this is the third
--                         time") without notice_a_pattern in the fresh,
--                         independently-derived knowledge_depth() —
--                         i.e. level < 3. Re-derived here rather than
--                         trusted from the prompt, because the whole
--                         point is that the model cannot talk its way
--                         past what the product actually knows.
--
-- ------------------------------------------------------------
-- Calibrated against real production replies, not guessed
--
-- Every pattern below was run against all 2,378 real ADAM replies in
-- n8n_chat_histories before being written this way. Two false-positive
-- classes were found and designed around:
--
--   "سأتذكر" (future promise: "I will remember") matched a naive
--   "أتذكر" pattern. Excluded with a negative lookbehind on س.
--
--   "لاحظت" alone is unusable: of 7 real hits, ALL SEVEN were either a
--   question TO the parent ("هل لاحظت..."), a script ADAM was
--   suggesting the PARENT say to their child ("قولي له: لاحظت أنّك..."),
--   or a description of the CHILD noticing something — never ADAM
--   claiming its own memory. It is not in the blocked set.
--
--   "هذه المرة" (ordinary "this time") matched a naive repetition
--   pattern; it is not a count claim. Narrowed to the ordinal-plus-مرة
--   and digit-plus-مرات constructions the product's own worked example
--   uses ("هذه ثالث مرة هذا الأسبوع") — zero false positives across the
--   full history at that precision.
--
-- General causal/psychological explanations ("الصراخ يحدث لأن جسمكِ...")
-- were deliberately tested and NOT blocked: they are the 2026-08-04
-- warmth rewrite's actual working technique, appear throughout real
-- (good) replies, and a blanket ban would over-block exactly like the
-- first draft of copy_violations did (53 of 2,233, ~40 good answers) —
-- the reason that rule was narrowed to a measured 0.67%. A generic
-- reframe that invents no specific fact about this child is not the
-- hallucination this gate exists to catch; a claimed memory or an
-- invented count is.
-- ============================================================

begin;

create or replace function public.gate_grounded_reply(
  p_parent_id uuid,
  p_body      text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_hard  text[] := '{}';
  v_kd    jsonb;
  v_moves jsonb;
begin
  if coalesce(btrim(p_body), '') = '' then
    return jsonb_build_object('ok', true, 'blocked', false, 'violations', '[]'::jsonb);
  end if;

  -- memory:announced — a claim of existing, present-tense memory or
  -- records. Never true: nothing is recalled, everything is composed
  -- fresh from get_agent_context each time. The (^|[^س]) exclusion keeps
  -- the honest future promise "سأتذكر" (I will remember, going forward)
  -- alive — it is not a claim about the past.
  if p_body ~ '(^|[^س])أتذكّر' or p_body ~ '(^|[^س])أتذكر'
     or p_body ~ 'بحسب ما سجّلته' or p_body ~ 'حسب سجلات[يى]'
     or p_body ~ 'كما (أخبرتموني|أخبرتني|قلتم لي|قلت لي) سابقاً' then
    v_hard := v_hard || 'memory:announced'::text;
  end if;

  -- memory:past_reference — a specific previous session that does not
  -- exist. ADAM has no session boundary; every message is "now."
  if p_body ~ 'في محادثتنا السابقة' or p_body ~ 'في حديثنا السابق'
     or p_body ~ 'المرة الماضية' or p_body ~ 'آخر مرة تحدث(نا|ّنا)'
     or p_body ~ 'سبق أن (ذكرتم|ذكرت|قلتم|قلت)' then
    v_hard := v_hard || 'memory:past_reference'::text;
  end if;

  -- pattern:unfounded — a repetition/count claim with nothing behind it.
  -- Gated on the SAME now_possible array knowledge_depth() would hand
  -- the prompt — re-derived here, fresh, so a model cannot simply assert
  -- notice_a_pattern was granted. Level < 3 (no confirmed pattern) means
  -- this class of claim is always fabricated.
  if p_body ~ '(ثاني|ثالث|رابع|خامس) مرة (هذا|في)'
     or p_body ~ '[0-9٠-٩]+ مرات هذا'
     or p_body ~ 'من [0-9٠-٩]+ (أيام|ليالٍ|ليالي)' then
    v_kd    := public.knowledge_depth(p_parent_id);
    v_moves := coalesce(v_kd->'now_possible', '[]'::jsonb);
    if not (v_moves ? 'notice_a_pattern') then
      v_hard := v_hard || 'pattern:unfounded'::text;
    end if;
  end if;

  return jsonb_build_object(
    'ok',         cardinality(v_hard) = 0,
    'blocked',    cardinality(v_hard) > 0,
    'violations', to_jsonb(v_hard));
end;
$function$;

comment on function public.gate_grounded_reply(uuid, text) is
  'The anti-hallucination guardrail: deterministic, calibrated against all 2,378 real replies in n8n_chat_histories, not the prompt''s word. Blocks unconditional memory-announcement and past-session-reference phrasing, and repetition/count claims not backed by a fresh, independently-derived knowledge_depth() (notice_a_pattern, level 3+). Deliberately does NOT block general causal/psychological reframes — tested and found to be the actual working technique of the 2026-08-04 warmth rewrite, not the hallucination this gate targets.';

revoke all on function public.gate_grounded_reply(uuid, text) from anon, authenticated, public;
grant execute on function public.gate_grounded_reply(uuid, text) to service_role;


-- ------------------------------------------------------------
-- gate_agent_reply calls it. One httpRequest node in W1 already calls
-- gate_agent_reply; nothing in n8n changes. The vocabulary/commercial
-- checks below are copied verbatim from 20260801250000 — untouched,
-- only the ⭐ addition and the merge into v_all/v_hard are new.
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
  v_ground  jsonb;
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

  -- ⭐ The grounding gate: memory claims, past-session references, and
  -- unfounded repetition counts. A hallucinated FACT, unlike a price or
  -- a sales verb, is invisible to copy_violations — this is the check
  -- that actually looks at what the product knows.
  v_ground := public.gate_grounded_reply(p_parent_id, p_body);
  if coalesce((v_ground->>'blocked')::boolean, false) then
    v_hard := v_hard || (select array_agg(x) from jsonb_array_elements_text(v_ground->'violations') x);
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
    -- something he is not allowed to say (or invented a fact he does
    -- not have) — the same reasoning covers both, so both share the
    -- one honest fallback.
    'fallback_key', case when v_blocked then 'reply_withheld' else null end);
end;
$function$;

comment on function public.gate_agent_reply(uuid, text) is
  'The one gate between the conversational agent and Telegram. Empty replies are always rejected. copy_violations is logged for the record; a narrow, precision-measured hard-blocking set (price, sales close, impersonation, brand guarantee/superiority, internal Latin terms, and — since 2026-08-11 — memory claims, past-session references, and unfounded repetition counts via gate_grounded_reply) actually withholds the reply. reply_withheld, never rescue: ADAM understood the parent and then violated a rule; blaming the parent for that is the opposite of P11.';

revoke all on function public.gate_agent_reply(uuid, text) from anon, authenticated, public;
grant execute on function public.gate_agent_reply(uuid, text) to service_role;

commit;
