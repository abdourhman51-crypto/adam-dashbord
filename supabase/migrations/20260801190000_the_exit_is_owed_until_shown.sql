begin;

-- ============================================================
-- The exit is owed until it has actually been shown.
--
-- W3 ran at 13:00:23 and sent six seeds — the first proactive
-- messages in the product's life. The workflow carrying the
-- consent footer was published at 13:03. Three minutes.
--
-- Six families therefore received a message ADAM started, with
-- no line telling them how to stop it.
--
-- The cause is a modelling error, not a race. The footer was
-- conditioned on "is this the first seed?" — a fact about the
-- MESSAGE, which becomes false the instant the message is sent
-- whether or not the footer actually went with it. It should
-- have been conditioned on "has this parent been shown the
-- exit?" — a fact about the PARENT, which stays true until it is
-- genuinely satisfied.
--
-- Facts about messages cannot be repaired. Facts about people
-- self-heal.
--
-- The debt now lives on followers.proactive_footer_at and is
-- paid by whichever proactive message comes next — for those six
-- that is tonight's harvest. No extra message, no apology, no
-- noise.
-- ============================================================

alter table public.followers
  add column if not exists proactive_footer_at timestamptz;

comment on column public.followers.proactive_footer_at is
  'When this parent was actually shown how to stop proactive messages. Null means the exit is still owed and the next proactive message must carry it. Deliberately a fact about the parent, not about any one message: a send that fails to carry it leaves the debt standing.';

-- No backfill. Nobody has been shown it: the only run that sent seeds
-- predates the publish, and inventing a timestamp here would silently
-- write off a debt to six real families.

-- Both recorders settle it, so no send path can forget and no workflow
-- change is needed to keep it honest.
create or replace function public.record_harvest_sent(p_day_id uuid)
returns boolean language plpgsql security definer
set search_path to 'pg_catalog','public'
as $function$
declare v_ok boolean; v_parent uuid;
begin
  update public.daily_logs
     set harvest_sent_at = now(), updated_at = now()
   where id = p_day_id
     and seed_sent_at is not null
     and harvest_sent_at is null
  returning true, follower_id into v_ok, v_parent;

  if coalesce(v_ok, false) then
    update public.followers
       set proactive_footer_at = coalesce(proactive_footer_at, now())
     where id = v_parent;
  end if;

  return coalesce(v_ok, false);
end;
$function$;

-- record_seed_sent gains the same one statement; the rest is unchanged
-- and is reproduced verbatim so this file is the whole function.
create or replace function public.record_seed_sent(
  p_parent_id uuid, p_local_date date, p_seed_text text,
  p_grounded_on jsonb, p_situation_id uuid default null::uuid,
  p_child_id uuid default null::uuid)
returns jsonb language plpgsql security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_day_id uuid; v_aha text[] := '{}'; v_first boolean;
begin
  if p_grounded_on is null
     or jsonb_typeof(p_grounded_on) <> 'array'
     or jsonb_array_length(p_grounded_on) = 0 then
    raise exception 'seed_not_grounded'
      using errcode = 'check_violation',
            hint = 'A Seed must record the Knowledge it came from (P11). Silence is the correct output when it cannot.';
  end if;

  insert into public.daily_logs as d
    (follower_id, log_date, source, seed_text, seed_grounded_on,
     seed_sent_at, situation_id, child_id)
  values
    (p_parent_id, p_local_date, 'rhythm', p_seed_text, p_grounded_on,
     now(), p_situation_id, p_child_id)
  on conflict (follower_id, log_date) do update
    set source           = 'rhythm',
        seed_text        = excluded.seed_text,
        seed_grounded_on = excluded.seed_grounded_on,
        seed_sent_at     = coalesce(d.seed_sent_at, now()),
        situation_id     = coalesce(excluded.situation_id, d.situation_id),
        child_id         = coalesce(excluded.child_id, d.child_id),
        updated_at       = now()
  returning d.id into v_day_id;

  update public.followers
     set proactive_footer_at = coalesce(proactive_footer_at, now())
   where id = p_parent_id;

  if p_grounded_on ? 'child_name' then
    v_first := not exists (
      select 1 from public.aha_moments
      where parent_id = p_parent_id and kind = 'A1' and first_occurrence);
    insert into public.aha_moments(parent_id, child_id, kind, moment_class, first_occurrence, day_id)
      values (p_parent_id, p_child_id, 'A1', 'free_value', v_first, v_day_id);
    v_aha := v_aha || case when v_first then 'A1_first' else 'A1' end;
  end if;

  if p_grounded_on ? 'prior_outcome' then
    v_first := not exists (
      select 1 from public.aha_moments
      where parent_id = p_parent_id and kind = 'A2' and first_occurrence);
    insert into public.aha_moments(parent_id, child_id, kind, moment_class, first_occurrence, day_id)
      values (p_parent_id, p_child_id, 'A2', 'free_value', v_first, v_day_id);
    v_aha := v_aha || case when v_first then 'A2_first' else 'A2' end;
  end if;

  return jsonb_build_object('day_id', v_day_id, 'aha', to_jsonb(v_aha));
end;
$function$;

commit;
