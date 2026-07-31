-- W2 identifies a parent by platform_user_id; commit_child_name takes the
-- internal id. A thin resolver, so the gates (plausible shape, confidence,
-- never overwrite) apply on that path too instead of W2 falling back to
-- write_child_name, which has none of them.
-- Applied via Supabase migration `commit_child_name_by_platform`.

create or replace function public.commit_child_name_by_platform(
  p_platform_user_id text, p_name text,
  p_age_note text default null, p_confidence text default 'low')
returns jsonb language plpgsql volatile security definer
set search_path to 'pg_catalog','public'
as $function$
declare v_id uuid;
begin
  select f.id into v_id from public.followers f
  where f.platform_user_id = p_platform_user_id limit 1;
  if v_id is null then
    return jsonb_build_object('committed', false, 'reason', 'no_such_parent');
  end if;
  return public.commit_child_name(v_id, p_name, p_age_note, p_confidence);
end;
$function$;

comment on function public.write_child_name(text, text) is
  'DEPRECATED. Superseded by commit_child_name_by_platform(): no plausibility gate, no confidence requirement.';

revoke all on function public.commit_child_name_by_platform(text, text, text, text) from anon, authenticated, public;
grant execute on function public.commit_child_name_by_platform(text, text, text, text) to service_role;
