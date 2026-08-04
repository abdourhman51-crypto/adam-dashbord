begin;

-- ============================================================
-- can_ground_seed — the Knowledge gate (arch §2.5, §5.3)
-- Tier-1 SQL per §2.2: deterministic, must give the same answer
-- twice, therefore not an LLM's decision to make.
--
-- Grounding requires a child name AND at least one of:
-- a situation, a prior outcome, or a detected pattern.
-- When it returns false, the correct behaviour is SILENCE,
-- not a generic Seed — so `missing` tells the caller which
-- single question would unblock it.
-- ============================================================
create or replace function public.can_ground_seed(p_parent_id uuid)
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
with child as (
  select c.id, nullif(btrim(c.name), '') as name
  from public.children c
  where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at
  limit 1
),
sit as (
  select s.id, s.key, s.window_start, s.window_end
  from public.situations s
  join child on child.id = s.child_id
  where s.status in ('candidate','confirmed')
  order by (s.status = 'confirmed') desc, s.evidence_count desc, s.last_observed desc
  limit 1
),
outcome as (
  select d.step_given, d.night_result, d.step_status, d.log_date
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and (d.night_result is not null or d.step_status is not null)
  order by d.log_date desc
  limit 1
),
pat as (
  select p.pattern_label
  from public.child_patterns p
  join child on child.id = p.child_id
  where coalesce(p.status,'active') <> 'dismissed'
  order by p.evidence_count desc nulls last, p.last_observed desc
  limit 1
),
basis as (
  select
    (select count(*) from sit)     > 0 as has_situation,
    (select count(*) from outcome) > 0 as has_outcome,
    (select count(*) from pat)     > 0 as has_pattern,
    (select name from child) is not null as has_name
)
select jsonb_build_object(
  'can_ground',  b.has_name and (b.has_situation or b.has_outcome or b.has_pattern),
  'child_id',    (select id   from child),
  'child_name',  (select name from child),
  'situation',   (select to_jsonb(sit)     from sit),
  'last_outcome',(select to_jsonb(outcome) from outcome),
  'pattern',     (select pattern_label from pat),
  'basis', (
    select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select 'child_name'    as x where b.has_name      union all
      select 'situation'          where b.has_situation union all
      select 'prior_outcome'      where b.has_outcome   union all
      select 'pattern'            where b.has_pattern
    ) t
  ),
  'missing', (
    select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select 'child_name' as x where not b.has_name
      union all
      select 'any_of_situation_outcome_pattern'
        where not (b.has_situation or b.has_outcome or b.has_pattern)
    ) t
  )
)
from basis b;
$function$;

comment on function public.can_ground_seed(uuid) is
  'The Knowledge gate (arch §2.5). Returns whether a Seed may be composed for this parent, what it can be grounded on, and what is missing. Tier-1 SQL by design: the send/do-not-send decision must be deterministic. can_ground=false means send nothing — never a generic Seed (P11).';

revoke all on function public.can_ground_seed(uuid) from anon, authenticated, public;
grant execute on function public.can_ground_seed(uuid) to service_role;

commit;
