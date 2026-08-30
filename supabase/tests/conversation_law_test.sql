\set ON_ERROR_STOP on
begin;

-- A rule you have never seen reject anything is a rule you are hoping for.
-- Each case below tries to store something the constitution forbids and
-- asserts the database refuses it.

create table pg_temp.r (n int generated always as identity, name text, result text);

create or replace function pg_temp.rejects(p_name text, p_sql text) returns void
language plpgsql as $$
begin
  begin
    execute p_sql;
    insert into pg_temp.r (name, result) values (p_name, 'FAIL — accepted');
  exception
    when check_violation then
      insert into pg_temp.r (name, result) values (p_name, 'PASS');
    when others then
      insert into pg_temp.r (name, result) values (p_name, 'FAIL — ' || sqlerrm);
  end;
end $$;

create or replace function pg_temp.accepts(p_name text, p_sql text) returns void
language plpgsql as $$
begin
  begin
    execute p_sql;
    insert into pg_temp.r (name, result) values (p_name, 'PASS');
  exception when others then
    insert into pg_temp.r (name, result) values (p_name, 'FAIL — ' || sqlerrm);
  end;
end $$;

\echo '=== THE VOCABULARY LAW BITES ==='
do $$
declare base text := $f$insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, buttons_forbidden, max_lines, note)
  values (%L, %L, 'fixed', %L, %L::jsonb, %L, %s, 'test')$f$;
begin
  perform pg_temp.rejects('machinery word: اشتراك',
    format(base,'t1','menu','يمكنك تجديد الاشتراك من هنا','[]',false,3));

  perform pg_temp.rejects('machinery word: خطة',
    format(base,'t2','menu','هذه خطة الأسبوع','[]',false,3));

  perform pg_temp.rejects('machinery word: تقرير',
    format(base,'t3','menu','هذا تقرير الليلة','[]',false,3));

  perform pg_temp.rejects('promotional verb: احصل على',
    format(base,'t4','menu','احصل على المرافقة الكاملة','[]',false,3));

  perform pg_temp.rejects('promotional verb: اشترك',
    format(base,'t5','menu','اشترك اليوم','[]',false,3));

  perform pg_temp.rejects('prefixed form الاشتراك is still caught',
    format(base,'t6','menu','الاشتراك متاح','[]',false,3));

  perform pg_temp.rejects('price digits (Western)',
    format(base,'t7','menu','الرحلة بـ 2300','[]',false,3));

  perform pg_temp.rejects('price digits (Arabic-Indic)',
    format(base,'t8','menu','الرحلة بـ ٤٩٠','[]',false,3));

  perform pg_temp.rejects('currency word',
    format(base,'t9','menu','مئة درهم فقط','[]',false,3));

  perform pg_temp.rejects('internal lexicon in Latin',
    format(base,'t10','menu','Your Journey starts now','[]',false,3));

  perform pg_temp.rejects('internal lexicon in Arabic: احتواء',
    format(base,'t11','menu','هذه لحظة احتواء','[]',false,3));

  -- The bans must not overreach onto approved copy.
  perform pg_temp.accepts('approved word خطوة survives (not خطة)',
    format(base,'ok1','rhythm','هذه خطوة حقيقية','[]',false,3));

  perform pg_temp.accepts('approved word نفعله survives (not فعّل)',
    format(base,'ok2','menu','كل ما يمكن أن نفعله معاً','[]',false,3));

  perform pg_temp.accepts('دجاج survives — دج was dropped from currency',
    format(base,'ok3','rhythm','رفض الدجاج على العشاء','[]',false,3));

  perform pg_temp.accepts('small counts written as words survive',
    format(base,'ok4','rhythm','خمس ليالٍ هادئة من سبع','[]',false,3));
end $$;

\echo '=== THE BUTTON LAW BITES ==='
do $$
declare base text := $f$insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, buttons_forbidden, max_lines, note)
  values (%L, %L, 'fixed', %L, %L::jsonb, %L, %s, 'test')$f$;
begin
  perform pg_temp.rejects('button set with no شيء آخر',
    format(base,'b1','rhythm','كيف كانت؟','[{"label":"نجحت","cb":"ok"}]',false,3));

  perform pg_temp.accepts('button set with شيء آخر',
    format(base,'b2','rhythm','كيف كانت؟',
      '[{"label":"نجحت","cb":"ok"},{"label":"شيء آخر","cb":"other"}]',false,3));

  perform pg_temp.rejects('crisis moment carrying buttons',
    format(base,'b3','crisis','أنا هنا','[{"label":"شيء آخر","cb":"other"}]',true,3));

  perform pg_temp.accepts('crisis moment with no buttons at all',
    format(base,'b4','crisis','أنا هنا','[]',true,3));

  perform pg_temp.rejects('button label carrying a promotional verb',
    format(base,'b5','menu','ماذا الآن؟',
      '[{"label":"احصل على الرحلة","cb":"x"},{"label":"شيء آخر","cb":"other"}]',false,3));

  perform pg_temp.rejects('button with no callback',
    format(base,'b6','menu','ماذا الآن؟',
      '[{"label":"نعم"},{"label":"شيء آخر","cb":"other"}]',false,3));
end $$;

\echo '=== THE LINE BUDGET BITES ==='
do $$
declare base text := $f$insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, buttons_forbidden, max_lines, note)
  values (%L, %L, 'fixed', %L, '[]'::jsonb, false, %s, 'test')$f$;
begin
  perform pg_temp.rejects('rescue may not raise its own budget above 3',
    format(base,'l1','rescue','سطر',8));

  perform pg_temp.accepts('a goal may run long — named exception',
    format(base,'l2','goal','سطر',8));

  perform pg_temp.rejects('body longer than its declared budget',
    format(base,'l3','rhythm',E'واحد\nاثنان\nثلاثة\nأربعة',3));

  perform pg_temp.accepts('blank lines are spacing, not content',
    format(base,'l4','rhythm',E'واحد\n\nاثنان\n\nثلاثة',3));
end $$;

\echo '=== TIER LAW ==='
do $$
begin
  perform pg_temp.rejects('composed moment may not store a body',
    $q$insert into public.conversation_moments (key,category,tier,body_ar,note)
       values ('x1','menu','composed','نص مخزّن','test')$q$);
  perform pg_temp.rejects('fixed moment must have a body',
    $q$insert into public.conversation_moments (key,category,tier,body_ar,note)
       values ('x2','menu','fixed',null,'test')$q$);
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result, 16) || name from pg_temp.r order by n;
select E'\n' || count(*) filter (where result = 'PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

\echo ''
\echo '=== RUNTIME GATE ON COMPOSED TEXT (same law, LLM output) ==='
select 'clean text'          as case, public.validate_outgoing('rescue', E'الرفض ليس عناداً.\nالليلة: الجلوس معه.') as verdict
union all
select 'promotional verb',    public.validate_outgoing('rescue', 'افتح الرحلة الآن')
union all
select 'price leaked',        public.validate_outgoing('rescue', 'الرحلة بـ 2300 دينار')
union all
select 'over the line budget',public.validate_outgoing('rescue', E'أ\nب\nج\nد\nهـ')
union all
select 'empty',               public.validate_outgoing('rescue', '   ');

\echo ''
\echo '=== UX / CONVERSATION CONTRACT IS CLOSED ==='
-- Every `meaning` get_telegram_surface() can emit must have a moment,
-- or a parent taps the menu and ADAM has nothing to say.
with emitted(meaning) as (
  values ('resume'),('lighten_load'),('waitlist'),
         ('journey_progress'),('next_goal'),('open_question')
)
select e.meaning,
       case when exists (select 1 from public.conversation_moments c
                          where c.key = 'menu_' || e.meaning)
            then 'PASS' else 'FAIL — no moment' end as has_moment
from emitted e;

-- And the four fixed menu items.
select k as fixed_menu_item,
       case when exists (select 1 from public.conversation_moments c where c.key = k)
            then 'PASS' else 'FAIL' end
from unnest(array['menu_child','menu_progress','menu_settings','menu_privacy']) k;

\echo ''
\echo '=== COMMERCE GATE ON MOMENTS ==='
do $$
declare p uuid;
begin
  insert into public.followers (platform_user_id, country) values ('t-strain','DZ') returning id into p;
  insert into public.parent_strain (parent_id, level) values (p, 2);
  raise notice 'goal_visible at strain L2 : %', public.get_conversation_moment('goal_visible', p);
  raise notice 'strain_l3  at strain L2   : %', public.get_conversation_moment('strain_l3', p);
end $$;

rollback;

\echo ''
\echo '=== EVERY BUTTON MUST BE ROUTABLE ==='
-- Seven buttons shipped whose callbacks were handled NOWHERE: quiet_hours,
-- pause, erase, resume_tomorrow, stay_paused, review_yes, review_stay. Each
-- fell through the Router's final else to the rescue, so a parent tapping
-- «امحوا كل ما قلته» was answered «لم أفهم هذه تماماً». No test looked at
-- routing, so the copy law passed while the product was broken.
--
-- The Router dispatches a callback when it is in its TAPS table, or starts
-- with menu_ / ck_mom_ / ck_step_ / ck_gen_ / set_country_. Anything else is
-- the rescue. This asserts the property directly.
with taps(cb) as (
  values ('menu_help'),('help_start'),('other'),('how_exactly'),('how_start'),
         ('not_now'),('cta_later'),('cta_ready'),('cta_full_companion'),
         ('waitlist_join')
),
buttons as (
  select distinct c.key as from_moment, b->>'cb' as cb
  from public.conversation_moments c, jsonb_array_elements(c.buttons) b
)
select case when count(*) = 0 then 'PASS' else 'FAIL' end as every_button_routes,
       coalesce(string_agg(from_moment || '→' || cb, ', '), '') as dead
from buttons
where cb not in (select cb from taps)
  and cb !~ '^(menu_|ck_mom_|ck_step_|ck_gen_|set_country_)';

-- A menu_-prefixed callback is used verbatim as the moment key, so the moment
-- must exist — unless get_moment_after_tap deliberately redirects it, which
-- the three hour keys and menu_waitlist_join (joins, then picks the moment
-- from the join's own result) do.
with buttons as (
  select distinct b->>'cb' as cb
  from public.conversation_moments c, jsonb_array_elements(c.buttons) b
)
select case when count(*) = 0 then 'PASS' else 'FAIL' end as menu_callbacks_have_moments,
       coalesce(string_agg(cb, ', '), '') as missing
from buttons
where cb like 'menu\_%'
  and cb not in ('menu_settings_hour_morning','menu_settings_hour_evening',
                 'menu_settings_hour_night','menu_waitlist_join')
  and not exists (select 1 from public.conversation_moments m where m.key = buttons.cb);
