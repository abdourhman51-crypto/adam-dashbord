begin;

-- ============================================================
-- A situation whose key is 'other' is not grounding.
--
-- Two of the first six seeds ever sent went to families whose
-- recorded situation is literally 'other' — رقية and ينير — and
-- both received lighting-and-bedtime advice their record does not
-- support. can_ground_seed passed them because a situation row
-- EXISTS; it never checked that the row SAYS anything.
--
-- That is grounding in name only, and it breaks the reason to
-- believe at the exact moment it is being demonstrated. The claim
-- is "ADAM knows nothing about children, it knows about YOUR
-- child". A seed invented from 'other' is a book talking.
--
-- 'other' still counts as evidence that a hard moment exists — it
-- just cannot be the SOLE basis for telling a family what to do.
-- Silence is the correct output until they say what it is.
-- ============================================================
create or replace function public.can_ground_seed(p_parent_id uuid)
returns jsonb
language sql stable security definer
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
  -- A named situation is preferred over 'other' even when 'other'
  -- carries more evidence: what a seed needs is a situation it can
  -- write a sentence about.
  select s.id, s.key, s.window_start, s.window_end,
         (s.key is not null and s.key <> 'other') as is_specific
  from public.situations s
  join child on child.id = s.child_id
  where s.status in ('candidate','confirmed')
  order by (s.key is not null and s.key <> 'other') desc,
           (s.status = 'confirmed') desc, s.evidence_count desc, s.last_observed desc
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
    (select count(*) from sit) > 0                    as has_situation,
    coalesce((select is_specific from sit), false)     as has_specific_situation,
    (select count(*) from outcome) > 0                 as has_outcome,
    (select count(*) from pat)     > 0                 as has_pattern,
    (select name from child) is not null               as has_name
)
select jsonb_build_object(
  'can_ground',  b.has_name and (b.has_specific_situation or b.has_outcome or b.has_pattern),
  'child_id',    (select id   from child),
  'child_name',  (select name from child),
  'situation',   (select to_jsonb(sit)     from sit),
  'last_outcome',(select to_jsonb(outcome) from outcome),
  'pattern',     (select pattern_label from pat),
  'basis', (
    select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select 'child_name'    as x where b.has_name                union all
      select 'situation'          where b.has_specific_situation  union all
      select 'prior_outcome'      where b.has_outcome             union all
      select 'pattern'            where b.has_pattern
    ) t
  ),
  'missing', (
    select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select 'child_name' as x where not b.has_name
      union all
      select 'any_of_situation_outcome_pattern'
        where not (b.has_specific_situation or b.has_outcome or b.has_pattern)
      union all
      -- Named out loud so the reason for silence is legible in a log.
      select 'situation_is_only_other'
        where b.has_situation and not b.has_specific_situation
          and not (b.has_outcome or b.has_pattern)
    ) t
  )
)
from basis b;
$function$;

comment on function public.can_ground_seed(uuid) is
  'Whether ADAM knows enough about THIS family to say something only true of them. A situation whose key is ''other'' is not grounding: it records that a hard moment exists without saying what it is, and a seed built on it is a book talking.';

commit;
