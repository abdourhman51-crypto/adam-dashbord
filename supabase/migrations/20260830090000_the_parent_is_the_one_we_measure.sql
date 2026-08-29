begin;

-- ============================================================
-- The thing we measure is the parent, not the child.
--
-- WHY THIS EXISTS
--
-- 5,712 messages of real conversation were read before this file
-- was written. The largest single theme was not any child
-- behaviour: 49 of 186 families (26%) wrote about THEIR OWN
-- loss of control — shouting, hitting, and the regret after.
-- One mother wrote, unprompted:
--
--   «ندم، وأودّ أن لا أضربها وأن أعاملها بلطف، ولكن لا أستطيع.»
--
-- and the phrase «لقيتُ نفسي بضربه» recurred across families —
-- they do not decide to hit, they find that they have. That is
-- a description of losing control, not of cruelty, and it is
-- what the product now measures.
--
-- THE ONE NUMBER
--
-- Not "calm nights" (the child's outcome, which the parent does
-- not control) but «كم مرة أوشكتِ ولم تنفجري» — the parent's own
-- victory. `held` is the row that matters; `erupted` exists so
-- the count is honest rather than flattering.
--
-- WHY A SEPARATE TABLE FROM daily_logs
--
-- daily_logs is one row per parent per day and carries the
-- Seed/Harvest pair. A parent can nearly lose it three times in
-- one day, and each of those is a distinct event worth counting.
-- Forcing them into the day row would either lose events or
-- corrupt the pair's invariants.
--
-- WHAT IS NOT HERE, DELIBERATELY
--
-- No severity score, no judgement, and no field that could ever
-- render as a verdict on the parent. An `erupted` row is data
-- for a curve, never a mark against them — §16's crisis path
-- remains the only route for anything that is actually unsafe,
-- and this table must never be used to approximate it.
-- ============================================================


create table if not exists public.parent_moments (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid not null references public.followers(id) on delete cascade,
  occurred_on date not null default current_date,

  -- held: nearly lost it and did not. THE number the product sells.
  -- erupted: lost it. Recorded so the curve is honest, never to score them.
  kind        text not null check (kind in ('held','erupted')),

  -- where it came from, so the panic button's real usage can be
  -- measured against the 15% falsification threshold set for it.
  source      text not null check (source in ('panic_button','evening','confession')),

  note        text,
  created_at  timestamptz not null default now(),

  constraint chk_moment_note_clean check (
    note is null or cardinality(public.copy_violations(note)) = 0)
);

create index if not exists idx_parent_moments_recent
  on public.parent_moments (parent_id, occurred_on desc, created_at desc);

comment on table public.parent_moments is
  'One row per moment a parent nearly lost control. `held` is the product''s north-star event; `erupted` keeps the count honest. Never a score, never a verdict — derived from 26% of real conversations being about the parent''s own loss of control.';
comment on column public.parent_moments.kind is
  'held = nearly did and did not (what we sell). erupted = did (so the curve does not flatter).';
comment on column public.parent_moments.source is
  'panic_button | evening | confession — lets the panic button be measured against its own falsification threshold.';

alter table public.parent_moments enable row level security;
revoke all on public.parent_moments from anon, authenticated;
grant select, insert on public.parent_moments to service_role;


-- ------------------------------------------------------------
-- record_parent_moment — the only write path.
--
-- Refuses an unknown kind or source rather than coercing, same
-- rule as commit_incident(): a gate that rounds to the nearest
-- valid value is not a gate.
-- ------------------------------------------------------------
create or replace function public.record_parent_moment(
  p_parent_id uuid,
  p_kind      text,
  p_source    text default 'evening',
  p_note      text default null)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_id   uuid;
  v_viol text[];
begin
  if p_kind not in ('held','erupted') then
    return jsonb_build_object('recorded', false, 'reason', 'unknown_kind');
  end if;
  if p_source not in ('panic_button','evening','confession') then
    return jsonb_build_object('recorded', false, 'reason', 'unknown_source');
  end if;
  if not exists (select 1 from public.followers where id = p_parent_id) then
    return jsonb_build_object('recorded', false, 'reason', 'unknown_parent');
  end if;

  if p_note is not null then
    v_viol := public.copy_violations(p_note);
    if cardinality(v_viol) > 0 then
      return jsonb_build_object('recorded', false, 'reason', 'vocabulary', 'violations', v_viol);
    end if;
  end if;

  insert into public.parent_moments (parent_id, kind, source, note)
  values (p_parent_id, p_kind, p_source, nullif(btrim(p_note), ''))
  returning id into v_id;

  return jsonb_build_object('recorded', true, 'moment_id', v_id, 'kind', p_kind);
end;
$function$;

comment on function public.record_parent_moment(uuid, text, text, text) is
  'The only way a parent moment is written. Refuses an unknown kind or source rather than coercing it.';


-- ------------------------------------------------------------
-- get_parent_curve — the one number, and the one comparison.
--
-- Weeks are rolling 7-day windows ending today, NOT calendar
-- weeks: a parent who opens this on a Tuesday should see the
-- last seven days, not two days of a calendar week that would
-- make their progress look imaginary.
--
-- `ready` is false until there is a previous week to compare
-- against. A curve drawn from four days is a curve that will
-- mislead them in whichever direction the noise happens to go.
-- ------------------------------------------------------------
create or replace function public.get_parent_curve(p_parent_id uuid)
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
  with m as (
    select kind, occurred_on
    from public.parent_moments
    where parent_id = p_parent_id
      and occurred_on > current_date - 28
  ),
  agg as (
    select
      count(*) filter (where kind='held'    and occurred_on >  current_date - 7)  as held_now,
      count(*) filter (where kind='erupted' and occurred_on >  current_date - 7)  as erupt_now,
      count(*) filter (where kind='held'    and occurred_on <= current_date - 7
                                            and occurred_on >  current_date - 14) as held_prev,
      count(*) filter (where kind='erupted' and occurred_on <= current_date - 7
                                            and occurred_on >  current_date - 14) as erupt_prev,
      count(*) filter (where kind='held')                                          as held_total,
      min(occurred_on)                                                             as first_day
    from m
  )
  select jsonb_build_object(
    'ready',      (first_day is not null and first_day <= current_date - 7),
    'heldWeek',   held_now,
    'eruptWeek',  erupt_now,
    'heldPrev',   held_prev,
    'eruptPrev',  erupt_prev,
    'heldTotal',  held_total,
    -- negative delta = fewer eruptions than last week = the win
    'eruptDelta', erupt_now - erupt_prev,
    'firstDay',   first_day
  ) from agg;
$function$;

comment on function public.get_parent_curve(uuid) is
  'Rolling 7-day windows, not calendar weeks — a parent opening this mid-week must see their real last seven days. `ready` stays false until a full previous week exists, because a curve from four days misleads in whichever direction the noise falls.';

revoke all on function public.record_parent_moment(uuid, text, text, text) from public;
revoke all on function public.get_parent_curve(uuid) from public;
grant execute on function public.record_parent_moment(uuid, text, text, text) to service_role;
grant execute on function public.get_parent_curve(uuid) to service_role;

commit;
