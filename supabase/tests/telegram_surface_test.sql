\set ON_ERROR_STOP on
begin;

create or replace function pg_temp.mk(p_country text, p_msgs int, p_last_days int default 0)
returns uuid language plpgsql as $$
declare v uuid; i int;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, p_country) returning id into v;
  insert into public.checkin_state (parent_id) values (v);
  for i in 1..p_msgs loop
    insert into public.n8n_chat_histories (session_id, message, created_at)
    values ((select platform_user_id from public.followers where id=v),
            '{"type":"human"}'::jsonb, now() - make_interval(days => p_last_days));
  end loop;
  return v;
end $$;

create or replace function pg_temp.add_child(p uuid, p_name text) returns uuid
language sql as $$
  insert into public.children (follower_id, name, is_primary)
  values (p, p_name, true) returning id;
$$;

create or replace function pg_temp.add_nights(p uuid, n int, calm int) returns void
language plpgsql as $$
declare i int;
begin
  for i in 1..n loop
    insert into public.daily_logs (follower_id, log_date, night_result)
    values (p, current_date - i, case when i <= calm then 'calm' else 'hard' end);
  end loop;
end $$;

create table pg_temp.results (label text, expect_state text, got jsonb);

do $$
declare p uuid; c uuid;
begin
  -- 1. brand_new
  p := pg_temp.mk('DZ', 1);
  insert into pg_temp.results values ('brand_new','brand_new', public.get_telegram_surface(p));

  -- 2. no_child_name  (messages, no child)
  p := pg_temp.mk('DZ', 8);
  insert into pg_temp.results values ('no_child_name','no_child_name', public.get_telegram_surface(p));

  -- 3. no_situation
  p := pg_temp.mk('DZ', 8); c := pg_temp.add_child(p,'يوسف');
  insert into pg_temp.results values ('no_situation','no_situation', public.get_telegram_surface(p));

  -- 4. gathering (situation, 2 nights)
  p := pg_temp.mk('DZ', 8); c := pg_temp.add_child(p,'يوسف');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',3);
  perform pg_temp.add_nights(p, 2, 1);
  insert into pg_temp.results values ('gathering','gathering', public.get_telegram_surface(p));

  -- 5. rhythm (7 nights, 4 calm, no journey ever)
  p := pg_temp.mk('DZ', 20); c := pg_temp.add_child(p,'يوسف');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',5);
  perform pg_temp.add_nights(p, 7, 4);
  insert into pg_temp.results values ('rhythm','rhythm', public.get_telegram_surface(p));

  -- 6. journey_active
  p := pg_temp.mk('EG', 30); c := pg_temp.add_child(p,'سارة');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'study','confirmed',5);
  perform pg_temp.add_nights(p, 7, 5);
  insert into public.stages (parent_id,child_id,problem_key,status) values (p,c,'study','active');
  insert into pg_temp.results values ('journey_active','journey_active', public.get_telegram_surface(p));

  -- 7. journey_ended_no_next
  p := pg_temp.mk('EG', 30); c := pg_temp.add_child(p,'سارة');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',5);
  perform pg_temp.add_nights(p, 7, 6);
  insert into public.stages (parent_id,child_id,problem_key,status) values (p,c,'sleep','completed');
  insert into pg_temp.results values ('journey_ended','journey_ended_no_next', public.get_telegram_surface(p));

  -- 8. paused, otherwise rhythm  -> modifier must outrank state
  p := pg_temp.mk('DZ', 20); c := pg_temp.add_child(p,'يوسف');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',5);
  perform pg_temp.add_nights(p, 7, 4);
  update public.checkin_state set paused_until = current_date + 5 where parent_id = p;
  insert into pg_temp.results values ('paused','rhythm', public.get_telegram_surface(p));

  -- 9. strain L2, otherwise rhythm -> no commercial item
  p := pg_temp.mk('DZ', 20); c := pg_temp.add_child(p,'يوسف');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',5);
  perform pg_temp.add_nights(p, 7, 4);
  insert into public.parent_strain (parent_id, level) values (p, 2);
  insert into pg_temp.results values ('strain_L2','rhythm', public.get_telegram_surface(p));

  -- 10. unsupported country, otherwise rhythm -> waitlist, everything else identical
  -- TN, not SA: same UTC offset as DZ, so this compares supported against
  -- unsupported without also comparing two different calendar days.
  p := pg_temp.mk('TN', 20); c := pg_temp.add_child(p,'يوسف');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',5);
  perform pg_temp.add_nights(p, 7, 4);
  insert into pg_temp.results values ('unsupported','rhythm', public.get_telegram_surface(p));

  -- 11. dormant returner
  p := pg_temp.mk('DZ', 20, 40); c := pg_temp.add_child(p,'يوسف');
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',5);
  insert into pg_temp.results values ('dormant','gathering', public.get_telegram_surface(p));

  -- 12. nonexistent parent
  insert into pg_temp.results values ('missing','(none)', public.get_telegram_surface(gen_random_uuid()));
end $$;

\pset format unaligned
\echo '=== STATE / CHANGING ITEM / PINNED ==='
select label
    || E'\n  state    : ' || coalesce(got->>'state','-') || '   (expected ' || expect_state || ')'
    || E'\n  item     : ' || coalesce(got->'menu'->2->>'label','-')
       || '  [' || coalesce(got->'menu'->2->>'meaning','-') || ']'
    || E'\n  progress : ' || coalesce(got->>'progress_line','-')
    || E'\n  pinned   : ' || replace(coalesce(got->'pinned'->>'text','-'), E'\n', ' / ')
    || E'\n  mods     : ' || coalesce(got->>'modifiers','-')
    || E'\n'
from pg_temp.results;

\echo '=== ASSERTIONS ==='
select label,
       case when expect_state = '(none)'
              then case when (got->>'exists')::boolean is false then 'PASS' else 'FAIL' end
            when got->>'state' = expect_state then 'PASS' else 'FAIL state' end as state_check
from pg_temp.results;

\echo '=== HARD GUARANTEES ==='
-- Only PARENT-VISIBLE strings. UUIDs in the payload are not shown to anyone
-- and contain digit runs that would make a naive scan meaningless.
select 'no price in any visible string' as guarantee,
       case when bool_and(
              coalesce(got->'pinned'->>'text','') || ' ' ||
              coalesce(got->>'progress_line','') || ' ' ||
              coalesce((select string_agg(m->>'label',' ') from jsonb_array_elements(got->'menu') m),'') || ' ' ||
              coalesce((select string_agg(k #>> '{}',' ') from jsonb_array_elements(got->'keyboard') k),'')
              !~ '(دينار|جنيه|درهم|دج|درهماً|جنيهاً|[0-9]|٢٣٠٠|٤٩٠|١١٠|2300|2,300|490|110)')
            then 'PASS' else 'FAIL' end as result from pg_temp.results
union all
-- These three used to assert that a modifier RELABELS the menu's changing
-- item: paused -> "resume", strain -> "lighten_load", unsupported ->
-- "waitlist". That is the behaviour docs/telegram-logic.md L4 forbids, and
-- it is the behaviour the founder hit — pressing the menu on a strained
-- account answered "أن نخفّف الحمل قليلاً", which announced a suppression
-- they had never been told about. A modifier now changes what is POSSIBLE
-- and never what is DISPLAYED, so the assertions invert: the modifier must
-- be readable in `modifiers` and invisible everywhere a parent looks.
select 'paused is in modifiers, not in the copy',
       case when (select (got->'modifiers'->>'paused')::boolean
                    from pg_temp.results where label='paused')
             and (select got->'pinned'->>'text' from pg_temp.results where label='paused')
                   !~ '(متوقف|أوقف|نعود)'
            then 'PASS' else 'FAIL' end
union all
select 'strain L2 blocks commerce silently',
       case when not (select (got->'modifiers'->>'commerce_allowed')::boolean
                        from pg_temp.results where label='strain_L2')
             and (select got->'pinned'->>'text' from pg_temp.results where label='strain_L2')
                   !~ '(الحمل|الحِمل|نخفّف)'
            then 'PASS' else 'FAIL' end
union all
select 'unsupported is invisible until she asks',
       case when not (select (got->'modifiers'->>'country_supported')::boolean
                        from pg_temp.results where label='unsupported')
             and (select got->'pinned'->>'text' from pg_temp.results where label='unsupported')
                   !~ '(قائمة الانتظار|بلدك|لم يصل)'
            then 'PASS' else 'FAIL' end
union all
select 'unsupported keeps full experience',
       case when (select got->>'progress_line' from pg_temp.results where label='unsupported')
               = (select got->>'progress_line' from pg_temp.results where label='rhythm')
            then 'PASS' else 'FAIL' end
union all
select 'no child -> no placeholder in pinned',
       case when (select got->'pinned'->>'text' from pg_temp.results where label='no_child_name') !~ 'طفلك'
            then 'PASS' else 'FAIL' end
union all
-- Was: "menu always 5 items, exactly 1 changing". Telegram's native ☰ is now
-- the only navigation, so the in-chat menu must be empty in every state —
-- otherwise there are two lists of the same actions and neither is trusted.
select 'no second navigation, in any state',
       case when bool_and(jsonb_array_length(got->'menu') = 0
                          and jsonb_array_length(got->'keyboard') = 0)
                 filter (where (got->>'exists')::boolean)
            then 'PASS' else 'FAIL' end
from pg_temp.results
union all
-- Was «ليلتان», then «ليلتين», now «مرّتين». The dual is still accusative —
-- what changed is the noun: the enemy is a repeating story, not a time of
-- day, so a parent whose story is the school run must not read "nights".
select 'dual form, and it is not a night',
       case when (select got->>'progress_line' from pg_temp.results where label='gathering')
                   like '%مرّتين%'
             and (select got->>'progress_line' from pg_temp.results where label='gathering')
                   !~ '(ليلة|ليلت|ليال)'
            then 'PASS' else 'FAIL' end
union all
select 'dormant flagged',
       case when (select (got->'modifiers'->>'dormant')::boolean from pg_temp.results where label='dormant')
            then 'PASS' else 'FAIL' end;

rollback;
