begin;

-- ============================================================
-- Phase 1 — نوبات الغضب, ages 3-8.
--
-- THE ONE THING THIS LAYER EXISTS TO SAY
--
-- A tantrum is not one behaviour. It is two, and they need
-- OPPOSITE responses:
--
--   نوبة طلب    the child still has the wheel. They watch you,
--               they can speak, it stops the moment they get
--               what they wanted. Holding the line works.
--
--   نوبة انهيار the nervous system has flooded. They do not see
--               you, words do not arrive, and it does NOT stop
--               when you give in — which is the tell parents
--               misread most. Reducing input works. Discipline
--               here pours fuel on it.
--
-- Parents read the second as the first and respond with
-- discipline, which escalates it. That single misread is behind
-- a large share of the evenings this product exists to change,
-- and correcting it is the first thing ADAM can do that a search
-- engine, a reel, or a general assistant cannot: it needs to
-- know which one THIS child is having, tonight.
--
-- WHY A CLOSED CATALOG RATHER THAN A PROMPT
--
-- Same argument as situation_catalog. If the reading vocabulary
-- lives in a prompt, every composition invents its own; two
-- readings of the same incident disagree, and the product becomes
-- a horoscope — plausible every time, useful never. The keys are
-- closed here, the observable tells are stored here, and the
-- composer may only choose among them.
--
-- WHY 3-8 IS A HARD GATE AND NOT A PREFERENCE
--
-- What is true of a three-year-old is false of a nine-year-old.
-- At 3 a daily tantrum is developmentally ordinary; at 8 it
-- carries a message worth reading. A reading engine with no age
-- gate would reassure the parent who should be looked at more
-- closely, and alarm the parent who needs to hear "this is his
-- age". can_read_incident() refuses outside the band rather than
-- guessing, and returns what is missing so ADAM can ask the one
-- question that would unblock it (§9.3).
--
-- WHAT IS NOT BUILT HERE, DELIBERATELY
--
-- No severity scoring, no escalation classifier, no "is this a
-- disorder" signal. Those are clinical judgements this product
-- does not make and must never appear to make. §16's crisis path
-- stays the only route out, untouched by this file.
-- ============================================================


-- ------------------------------------------------------------
-- The two kinds. Every field here is something a parent can
-- OBSERVE and report — not something to be inferred. A tell the
-- parent cannot check is a tell that turns the reading into a
-- guess with confident wording.
-- ------------------------------------------------------------
create table if not exists public.tantrum_kind_catalog (
  key          text primary key,
  label_ar     text not null,
  tell_ar      text not null,   -- how a parent tells this one apart, in the moment
  response_ar  text not null,   -- the principle, not a script
  sort_order   integer not null,

  constraint chk_kind_copy_clean check (
    cardinality(public.copy_violations(label_ar))    = 0 and
    cardinality(public.copy_violations(tell_ar))     = 0 and
    cardinality(public.copy_violations(response_ar)) = 0)
);

comment on table public.tantrum_kind_catalog is
  'The CLOSED two-kind reading of a tantrum. Tells are observable by the parent in the moment; a tell that must be inferred would make the reading a guess in confident wording.';

insert into public.tantrum_kind_catalog (key, label_ar, tell_ar, response_ar, sort_order) values
  ('demand', 'نوبة طلب',
   'يراقبكم وينظر إلى ردّكم، يقدر على الكلام أثناءها، وتتوقّف فور حصوله على ما أراد.',
   'الثبات الهادئ على الحدّ نفسه. جملة واحدة قصيرة تُقال مرة، ثم صمت — بلا تفاوض وبلا درس أثناءها.',
   1),
  ('flood', 'نوبة انهيار',
   'غائب عنكم ولا يراكم، صراخ بلا كلمات وجسد متصلّب، ولا تهدأ حتى لو أعطيتموه ما طلب.',
   'تقليل كل شيء: كلمات أقل، صوت أخفض، ضوء وحركة أقل، وقرب بلا لمس مفروض. لا تعليم الآن — لا يصل.',
   2),
  ('unclear', 'لم تتّضح بعد',
   'الإشارات مختلطة، أو لم يُرَ منها ما يكفي.',
   'وصف ما حدث وحده، بلا حكم. سؤال واحد يوضّح الصورة خير من قراءة مبنيّة على فراغ.',
   3)
on conflict (key) do update
  set label_ar    = excluded.label_ar,
      tell_ar     = excluded.tell_ar,
      response_ar = excluded.response_ar,
      sort_order  = excluded.sort_order;


-- ------------------------------------------------------------
-- What was underneath it. Five, closed.
--
-- `body` is first on purpose and is the most common by a wide
-- margin. It is also the one parents skip, because it is boring
-- and because naming it feels like being told they neglected
-- something. The wording carries no blame for exactly that
-- reason — a driver a parent refuses to hear is a driver ADAM
-- cannot use.
-- ------------------------------------------------------------
create table if not exists public.tantrum_driver_catalog (
  key          text primary key,
  label_ar     text not null,
  tell_ar      text not null,   -- what makes this one likely
  prevent_ar   text not null,   -- the move that belongs BEFORE, not during
  sort_order   integer not null,

  constraint chk_driver_copy_clean check (
    cardinality(public.copy_violations(label_ar))   = 0 and
    cardinality(public.copy_violations(tell_ar))    = 0 and
    cardinality(public.copy_violations(prevent_ar)) = 0)
);

comment on table public.tantrum_driver_catalog is
  'The CLOSED set of what sits under a tantrum. Each carries a prevention move that belongs BEFORE the eruption — the only window where a parent has real leverage.';

insert into public.tantrum_driver_catalog (key, label_ar, tell_ar, prevent_ar, sort_order) values
  ('body', 'الجسد',
   'قرب موعد النوم أو الأكل، بعد يوم طويل، أو بعد مكان فيه ضجيج وناس كثيرون.',
   'أكل صغير أو راحة قصيرة قبل الوقت الصعب بربع ساعة — قبل أن يبدأ، لا بعده.',
   1),
  ('shift', 'الانتقال',
   'بدأت لحظة انتقاله من شيء إلى شيء: من اللعب إلى الأكل، من البيت إلى الخارج، من الشاشة إلى النوم.',
   'تنبيه قبل الانتقال بخمس دقائق، ثم تذكير قبله بدقيقة. الانتقال المفاجئ وحده يصنع نوبة.',
   2),
  ('grip', 'حاجته أن يختار',
   'يومه كله مقرّر عنه، والنوبة تأتي عند أمر مباشر أو حين لا يبقى له أي خيار.',
   'اختياران محدودان تختارونهما أنتم: «القميص الأزرق أو الأخضر؟» الاختيار صغير، والأثر ليس صغيراً.',
   3),
  ('bond', 'يطلبكم أنتم',
   'بعد غياب أو انشغال، أو بعد أن أخذ أخوه انتباهكم — ويأتي السلوك مقلوباً لأنه لا يعرف كيف يطلب.',
   'خمس دقائق كاملة له وحده قبل الوقت الصعب، بلا هاتف وبلا مقاطعة. أقصر ممّا يبدو، وأقوى.',
   4),
  ('words', 'لا يملك الكلمة',
   'يحسّ بشيء كبير ولا يقدر أن يسمّيه — أكثر ما يكون بين الثالثة والخامسة.',
   'سمّوا أنتم ما يبدو عليه بجملة قصيرة: «صعب عليك تسيب اللعب.» التسمية وحدها تخفض الموجة.',
   5)
on conflict (key) do update
  set label_ar   = excluded.label_ar,
      tell_ar    = excluded.tell_ar,
      prevent_ar = excluded.prevent_ar,
      sort_order = excluded.sort_order;


-- ------------------------------------------------------------
-- The arc. Four phases, and the reason this table exists is the
-- single most common parenting error in this whole domain:
--
--   parents teach at the peak.
--
-- The lesson lands nowhere, the child escalates, the parent
-- concludes that nothing works. `backfire_ar` is here so ADAM can
-- name what NOT to do — which is more useful than one more thing
-- to do, and is the half every tip library leaves out.
-- ------------------------------------------------------------
create table if not exists public.tantrum_phase_catalog (
  key          text primary key,
  label_ar     text not null,
  works_ar     text not null,
  backfire_ar  text not null,
  sort_order   integer not null,

  constraint chk_phase_copy_clean check (
    cardinality(public.copy_violations(label_ar))    = 0 and
    cardinality(public.copy_violations(works_ar))    = 0 and
    cardinality(public.copy_violations(backfire_ar)) = 0)
);

comment on table public.tantrum_phase_catalog is
  'The four phases of a tantrum. backfire_ar exists because naming what not to do is more useful than one more thing to do, and is the half a tip library always omits.';

insert into public.tantrum_phase_catalog (key, label_ar, works_ar, backfire_ar, sort_order) values
  ('before', 'قبل الانفجار',
   'هنا وحدها توجد قدرة حقيقية: علامة تسبقها دائماً — نبرة، حركة، نظرة — وحركة صغيرة عندها تُنهيها قبل أن تبدأ.',
   'انتظار أن تبدأ ثم محاولة إيقافها. الوقت الوحيد المربح يمرّ بلا استعمال.',
   1),
  ('peak', 'الذروة',
   'السلامة والحضور فقط: قربٌ، صوت أخفض، كلمات أقل. لا شيء آخر ينفع، وهذا ليس فشلاً منكم.',
   'الشرح، السؤال، التهديد، أو العقاب. كلّها تطيل النوبة لأن الكلام لا يصل أصلاً في هذه اللحظة.',
   2),
  ('down', 'الهبوط',
   'العودة إليه قبل العودة للموضوع: قربٌ صامت، ماء، حضن إن قبله. جسده يحتاج أن يرجع أولاً.',
   'الدرس هنا. لم يهدأ بعد بما يكفي ليسمع، وستُعيدونها من أولها.',
   3),
  ('after', 'بعد أن يهدأ تماماً',
   'جملة واحدة قصيرة، لاحقاً لا فوراً: ماذا حدث، وماذا نفعل المرة القادمة. هنا يتعلّم فعلاً.',
   'العودة الطويلة للموضوع، أو التذكير به مرات. الدرس الطويل يمحو نفسه.',
   4)
on conflict (key) do update
  set label_ar    = excluded.label_ar,
      works_ar    = excluded.works_ar,
      backfire_ar = excluded.backfire_ar,
      sort_order  = excluded.sort_order;


-- ------------------------------------------------------------
-- «هل هذا طبيعي؟»
--
-- This is stored copy, not something composed, and that is the
-- point. It is the highest-anxiety question a parent carries and
-- the one where an invented answer does the most damage — in
-- both directions. Three bands, each true of its band and false
-- of the others, which is what makes saying it worth anything.
-- ------------------------------------------------------------
create table if not exists public.tantrum_age_expectation (
  band         text primary key check (band in ('3_4','5_6','7_8')),
  label_ar     text not null,
  normal_ar    text not null,
  watch_ar     text not null,

  constraint chk_age_copy_clean check (
    cardinality(public.copy_violations(label_ar))  = 0 and
    cardinality(public.copy_violations(normal_ar)) = 0 and
    cardinality(public.copy_violations(watch_ar))  = 0)
);

comment on table public.tantrum_age_expectation is
  'What is ordinary at each age band, stored rather than composed. The highest-anxiety question a parent carries is the worst one to answer from invention.';

insert into public.tantrum_age_expectation (band, label_ar, normal_ar, watch_ar) values
  ('3_4', 'الثالثة والرابعة',
   'في هذا العمر النوبة متوقّعة، ومرة أو مرتان في اليوم ليست علامة خلل. الجزء الذي يكبح الغضب لم ينضج بعد — لا يعاندكم، لا يقدر.',
   'ما يستحق الانتباه ليس عددها، بل أن تطول كثيراً جداً أو يؤذي فيها نفسه.'),
  ('5_6', 'الخامسة والسادسة',
   'تقلّ تدريجياً في هذا العمر، وتصير أقرب إلى طلب ومساومة منها إلى انهيار كامل. تراجعها ليس خطاً مستقيماً — تعود عند التعب والتغيير.',
   'ما يستحق الانتباه أن تعود بقوة بعد فترة هدوء طويلة، فغالباً تحتها تغيّر جديد.'),
  ('7_8', 'السابعة والثامنة',
   'في هذا العمر صارت أقلّ شيوعاً، فحين تتكرّر فهي تحمل رسالة أوضح: نوم ناقص متراكم، ضغط في المدرسة، أو مكان يشعر أنه فقده بين إخوته.',
   'ما يستحق الانتباه تكرارها اليومي مع تغيّر في النوم أو الأكل أو الرغبة في المدرسة.')
on conflict (band) do update
  set label_ar  = excluded.label_ar,
      normal_ar = excluded.normal_ar,
      watch_ar  = excluded.watch_ar;


-- ------------------------------------------------------------
-- tantrum_age_band — STABLE, not IMMUTABLE: it reads the clock.
-- Returns null outside 3-8 rather than clamping to the nearest
-- band, because a clamped answer is a confident wrong answer.
-- ------------------------------------------------------------
create or replace function public.tantrum_age_band(p_birth_year integer)
returns text
language sql
stable
set search_path to 'pg_catalog','public'
as $function$
  select case
    when p_birth_year is null then null
    when (extract(year from now())::integer - p_birth_year) between 3 and 4 then '3_4'
    when (extract(year from now())::integer - p_birth_year) between 5 and 6 then '5_6'
    when (extract(year from now())::integer - p_birth_year) between 7 and 8 then '7_8'
    else null
  end;
$function$;

comment on function public.tantrum_age_band(integer) is
  'The 3-8 band, or null outside it. Null rather than the nearest band: a clamped answer would be a confident wrong one.';


-- ------------------------------------------------------------
-- incidents — a hard moment the parent described, and what ADAM
-- read in it.
--
-- raw_text is what the parent said. It is a DISCLOSURE, and §2.8
-- governs it: family_tokens() must never read this table, so a
-- proactive message can never quote it back. The reading may be
-- spoken; the disclosure may not.
-- ------------------------------------------------------------
create table if not exists public.incidents (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid not null references public.followers(id) on delete cascade,
  child_id    uuid not null references public.children(id)  on delete cascade,
  occurred_on date not null default current_date,

  raw_text    text not null,
  source      text not null check (source in ('text','voice')),

  kind_key    text references public.tantrum_kind_catalog(key),
  driver_key  text references public.tantrum_driver_catalog(key),
  phase_key   text references public.tantrum_phase_catalog(key),
  reading_ar  text,

  created_at  timestamptz not null default now(),

  -- The reading is spoken to a parent, so it obeys the same law
  -- every other spoken string obeys. One standard, one function.
  constraint chk_reading_clean check (
    reading_ar is null or cardinality(public.copy_violations(reading_ar)) = 0)
);

create index if not exists idx_incidents_parent_recent
  on public.incidents (parent_id, occurred_on desc, created_at desc);

comment on table public.incidents is
  'A hard moment as the parent described it, plus the reading ADAM returned. raw_text is a disclosure under §2.8 — family_tokens() must never read this table, so no proactive message can quote it back.';
comment on column public.incidents.raw_text is
  'What the parent said, verbatim (or transcribed from voice). DISCLOSURE — never a source for proactive copy.';
comment on column public.incidents.source is
  'text | voice. Voice is the primary path: a parent types Arabic slowly and speaks their dialect quickly.';

alter table public.incidents enable row level security;
revoke all on public.incidents from anon, authenticated;
grant select, insert, update on public.incidents to service_role;

grant select on public.tantrum_kind_catalog,
                public.tantrum_driver_catalog,
                public.tantrum_phase_catalog,
                public.tantrum_age_expectation
  to service_role;


-- ------------------------------------------------------------
-- can_read_incident — the gate, same shape as can_ground_seed().
--
-- Returns WHY it refuses, so the caller can ask the one question
-- that would unblock it instead of guessing or staying silent for
-- an unexplained reason.
-- ------------------------------------------------------------
create or replace function public.can_read_incident(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_child   public.children%rowtype;
  v_band    text;
  v_missing text[] := array[]::text[];
begin
  select * into v_child
  from public.children
  where follower_id = p_parent_id
  order by is_primary desc, created_at asc
  limit 1;

  if not found then
    return jsonb_build_object('can_read', false, 'missing', array['child']);
  end if;

  if nullif(btrim(coalesce(v_child.name, '')), '') is null then
    v_missing := v_missing || 'child_name'::text;
  end if;

  v_band := public.tantrum_age_band(v_child.birth_year);

  if v_child.birth_year is null then
    v_missing := v_missing || 'birth_year'::text;
  elsif v_band is null then
    -- Known age, outside 3-8. Not a missing fact — a scope refusal,
    -- and it is reported distinctly so the caller does not ask for
    -- an age it already has.
    return jsonb_build_object(
      'can_read', false,
      'reason',   'out_of_band',
      'child_id', v_child.id,
      'missing',  array[]::text[]);
  end if;

  if cardinality(v_missing) > 0 then
    return jsonb_build_object('can_read', false, 'reason', 'incomplete', 'missing', v_missing);
  end if;

  return jsonb_build_object(
    'can_read',   true,
    'child_id',   v_child.id,
    'child_name', btrim(v_child.name),
    'age_band',   v_band,
    'missing',    array[]::text[]);
end;
$function$;

comment on function public.can_read_incident(uuid) is
  'Phase 1 gate: a named child aged 3-8. Distinguishes a missing fact (ask for it) from an out-of-band age (do not ask — the fact is known and the answer is still no).';


-- ------------------------------------------------------------
-- get_tantrum_frame — tier-1 assembly, per §2.2.
--
-- Everything the composer is allowed to choose among, in one
-- read. It exists so the composer never invents a category: if a
-- key is not in this payload, there is no wording for it.
-- ------------------------------------------------------------
create or replace function public.get_tantrum_frame(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_gate jsonb;
  v_band text;
begin
  v_gate := public.can_read_incident(p_parent_id);

  if not (v_gate->>'can_read')::boolean then
    return jsonb_build_object('ready', false, 'gate', v_gate);
  end if;

  v_band := v_gate->>'age_band';

  return jsonb_build_object(
    'ready',      true,
    'child_id',   v_gate->>'child_id',
    'child_name', v_gate->>'child_name',
    'age',        (select to_jsonb(a) from public.tantrum_age_expectation a where a.band = v_band),
    'kinds',      (select jsonb_agg(to_jsonb(k) order by k.sort_order)
                   from public.tantrum_kind_catalog k),
    'drivers',    (select jsonb_agg(to_jsonb(d) order by d.sort_order)
                   from public.tantrum_driver_catalog d),
    'phases',     (select jsonb_agg(to_jsonb(p) order by p.sort_order)
                   from public.tantrum_phase_catalog p),
    -- What this family has already shown. A second incident that
    -- reads the same way as the first is the beginning of a
    -- pattern, and is the only thing here that is EARNED rather
    -- than supplied — which is what §2.6 counts as `measured`.
    'recent',     coalesce((select jsonb_agg(jsonb_build_object(
                              'occurred_on', i.occurred_on,
                              'kind',        i.kind_key,
                              'driver',      i.driver_key))
                            from (select * from public.incidents
                                  where parent_id = p_parent_id
                                    and kind_key is not null
                                  order by occurred_on desc, created_at desc
                                  limit 5) i), '[]'::jsonb));
end;
$function$;

comment on function public.get_tantrum_frame(uuid) is
  'The complete, closed vocabulary a reading may draw on, in one read. A key absent from this payload has no wording, which is how the reading stays a reading rather than an invention.';


-- ------------------------------------------------------------
-- commit_incident — the ONLY write path.
--
-- Refuses rather than coercing. An unknown key does not fall back
-- to `unclear`: a gate whose default is "close enough" stops
-- being a gate, and the caller would never learn it sent
-- something the catalog does not contain.
-- ------------------------------------------------------------
create or replace function public.commit_incident(
  p_parent_id uuid,
  p_raw_text  text,
  p_source    text default 'text',
  p_kind      text default null,
  p_driver    text default null,
  p_phase     text default null,
  p_reading   text default null)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_gate  jsonb;
  v_viol  text[];
  v_id    uuid;
begin
  if nullif(btrim(coalesce(p_raw_text, '')), '') is null then
    return jsonb_build_object('committed', false, 'reason', 'empty_text');
  end if;

  if p_source not in ('text','voice') then
    return jsonb_build_object('committed', false, 'reason', 'unknown_source');
  end if;

  v_gate := public.can_read_incident(p_parent_id);
  if not (v_gate->>'can_read')::boolean then
    return jsonb_build_object('committed', false, 'reason', coalesce(v_gate->>'reason','not_ready'), 'gate', v_gate);
  end if;

  if p_kind is not null and not exists (select 1 from public.tantrum_kind_catalog where key = p_kind) then
    return jsonb_build_object('committed', false, 'reason', 'unknown_kind');
  end if;
  if p_driver is not null and not exists (select 1 from public.tantrum_driver_catalog where key = p_driver) then
    return jsonb_build_object('committed', false, 'reason', 'unknown_driver');
  end if;
  if p_phase is not null and not exists (select 1 from public.tantrum_phase_catalog where key = p_phase) then
    return jsonb_build_object('committed', false, 'reason', 'unknown_phase');
  end if;

  -- The reading is checked BEFORE it is stored, and a violation is
  -- a reading not saved — not a reading saved with a warning.
  if p_reading is not null then
    v_viol := public.copy_violations(p_reading);
    if cardinality(v_viol) > 0 then
      return jsonb_build_object('committed', false, 'reason', 'vocabulary', 'violations', v_viol);
    end if;
  end if;

  insert into public.incidents
    (parent_id, child_id, raw_text, source, kind_key, driver_key, phase_key, reading_ar)
  values
    (p_parent_id, (v_gate->>'child_id')::uuid, btrim(p_raw_text), p_source,
     p_kind, p_driver, p_phase, p_reading)
  returning id into v_id;

  return jsonb_build_object(
    'committed',   true,
    'incident_id', v_id,
    'child_name',  v_gate->>'child_name',
    'age_band',    v_gate->>'age_band',
    'kind',        p_kind,
    'driver',      p_driver,
    'phase',       p_phase);
end;
$function$;

comment on function public.commit_incident(uuid, text, text, text, text, text, text) is
  'The only way an incident is recorded. Refuses an unknown key rather than coercing it to `unclear` — a gate that rounds to the nearest valid value is not a gate.';

revoke all on function public.can_read_incident(uuid)  from public;
revoke all on function public.get_tantrum_frame(uuid)  from public;
revoke all on function public.commit_incident(uuid, text, text, text, text, text, text) from public;
grant execute on function public.can_read_incident(uuid) to service_role;
grant execute on function public.get_tantrum_frame(uuid) to service_role;
grant execute on function public.commit_incident(uuid, text, text, text, text, text, text) to service_role;


-- ------------------------------------------------------------
-- The panic button used to live here as four conversation_moments
-- (now_entry / now_flood / now_demand / now_after). They were
-- removed on 2026-08-30 and never reached production.
--
-- Two reasons, and the second is the important one:
--
-- 1. The button now lives entirely inside the mini app
--    (components/PanicButton.tsx) with its scripts inline, because
--    a parent mid-crisis cannot wait for a round trip. Nothing in
--    the bot routes those callbacks, so shipping them would have
--    created exactly the dead buttons conversation_law_test guards
--    against.
--
-- 2. They were written about the CHILD's tantrum. Reading 5,712
--    real messages showed the first problem is the PARENT's own
--    loss of control (49 of 186 families), so the scripts were
--    rewritten to address the parent — see
--    20260830090000_the_parent_is_the_one_we_measure.sql.
-- ------------------------------------------------------------

commit;
