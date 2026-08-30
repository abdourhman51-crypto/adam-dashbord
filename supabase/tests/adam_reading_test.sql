\set ON_ERROR_STOP on
begin;

-- ============================================================
-- قراءة آدم — the paid product's centre.
--
-- The rule these cases exist to defend: «اذا المستخدم دفع
-- نحققولو وعد سريع بش ميحسش بخيبة امل». A parent who pays and
-- meets an empty screen has been failed, so `opened` fires on the
-- payment itself with zero nights logged.
--
-- And the other half of it: a FREE parent is never shown an
-- invented preview. What they see is one TRUE line from their own
-- house, or an admission that ADAM does not know it yet.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A family walked through N evenings, every row written by the rhythm's own
-- writers. Nights 2 and 5 are hard, so «what calms» has something to rank.
create or replace function pg_temp.fam(p_pid text, p_nights int, p_paid boolean,
                                       p_named boolean default true)
returns uuid language plpgsql as $$
declare p uuid; c uuid; s uuid; v_day uuid; a jsonb;
begin
  insert into public.followers (platform_user_id, country) values (p_pid,'DZ') returning id into p;
  insert into public.children (follower_id, name, is_primary)
  values (p, case when p_named then 'يوسف' else 'الطفل' end, true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status, window_start, window_end)
  select c, p, 'sleep', sc.label_ar, 'confirmed', sc.window_start, sc.window_end
    from public.situation_catalog sc where sc.key = 'sleep' returning id into s;

  if p_paid then
    a := public.activate_subscription(p, null, null, 'test', 'sleep',
           'خمس ليالٍ هادئة من سبع عند النوم مع يوسف', 5, 7, 29);
  end if;

  for i in 0..(p_nights - 1) loop
    v_day := (public.record_seed_sent(p, current_date, 'تنبيه قبل النوم بعشر دقائق',
                jsonb_build_array('child_name','situation'), s, c)->>'day_id')::uuid;
    perform public.record_harvest_sent(v_day);
    perform public.record_harvest_answer(p,
      case when i in (1,4) then 'tried_failed' else 'succeeded' end,
      case when i in (1,4) then 'sleep' end);
    if i < p_nights - 1 then
      update public.daily_logs set log_date = current_date - (i+1)
       where follower_id = p and log_date = current_date;
    end if;
  end loop;
  return p;
end $$;


\echo '=== LOCKED: A FREE PARENT IS NEVER SHOWN AN INVENTED PREVIEW ==='
do $$
declare p uuid; r jsonb;
begin
  p := pg_temp.fam('rd-lock', 0, false);
  r := public.adam_reading(p);

  perform pg_temp.chk('a free parent is locked', r->>'state' = 'locked', r->>'state');
  perform pg_temp.chk('and is told one TRUE thing from their own house',
    r->>'body' like '%عند النوم يستهلك صبركم مع يوسف%',
    'the situation they actually confirmed, not a sample');
  perform pg_temp.chk('the offer is named, and named as فريق آدم''s',
    r->>'body' like '%يتولّاها فريق آدم%');
  perform pg_temp.chk('and no price is ever spoken here',
    r->>'body' !~ '[0-9٠-٩]');
end $$;

do $$
declare p uuid; r jsonb;
begin
  -- A stranger. There is nothing true to say, so nothing is claimed.
  insert into public.followers (platform_user_id, country) values ('rd-nobody','DZ');
  select public.adam_reading(id) into r from public.followers where platform_user_id='rd-nobody';
  perform pg_temp.chk('with an unknown house it admits so instead of inventing',
    r->>'body' like '%لا أعرف بيتكم بعد%', left(r->>'body', 60));
end $$;


\echo '=== OPENED: THE REWARD LANDS ON THE PAYMENT, NOT AFTER A WAIT ==='
do $$
declare p uuid; r jsonb;
begin
  -- Paid this second. Zero nights. This is the moment the founder named.
  p := pg_temp.fam('rd-open', 0, true);
  r := public.adam_reading(p);

  perform pg_temp.chk('a paid parent with NOTHING logged is already opened',
    r->>'state' = 'opened', r->>'state');
  perform pg_temp.chk('and the reading is not empty — it says what ADAM already knows',
    r->>'body' like '%طفلكم يوسف%' and r->>'body' like '%عند النوم يستهلك صبركم أكثر من غيره%');
  perform pg_temp.chk('the agreed goal is read back to them',
    r->>'body' like '%خمس ليالٍ هادئة من سبع%',
    'they paid for a goal, so the goal is the first thing they see');
  perform pg_temp.chk('and it tells them exactly when more appears',
    r->>'body' like '%بعد ثلاث ليالٍ%' and r->>'body' like '%بعد أسبوع%');
  perform pg_temp.chk('and asks nothing of them tonight',
    r->>'body' like '%لا شيء مطلوب منكم الآن%');
end $$;


\echo '=== GATHERING AND FULL: REAL FROM THE FIRST NIGHT ==='
do $$
declare p uuid; r jsonb;
begin
  p := pg_temp.fam('rd-gath', 3, true);
  r := public.adam_reading(p);

  perform pg_temp.chk('three nights is gathering, not full', r->>'state' = 'gathering', r->>'state');
  perform pg_temp.chk('and it already counts them honestly',
    r->>'body' like '%٣ ليالٍ%' and r->>'body' like '%٢ منها مرّت بهدوء%');
  perform pg_temp.chk('and already names what worked, ranked',
    r->>'body' like '%تنبيه قبل النوم بعشر دقائق — نجحت ٢ من ٣%',
    'the line no article could write, because it is their own step');
  perform pg_temp.chk('while saying plainly that it cannot compare yet',
    r->>'body' like '%ما زالت الصورة تتشكّل%');
end $$;

do $$
declare p uuid; r jsonb;
begin
  p := pg_temp.fam('rd-full', 9, true);
  r := public.adam_reading(p);

  perform pg_temp.chk('seven nights or more is the full reading', r->>'state' = 'full', r->>'state');
  perform pg_temp.chk('what repeats is named',
    r->>'body' like '%ما يتكرّر%' and r->>'body' like '%عند النوم%');
  perform pg_temp.chk('what calms is ranked by how often it actually worked',
    r->>'body' like '%نجحت ٧ من ٩%',
    'seed_text, not step_given — the rhythm writes the former');
  perform pg_temp.chk('the week is compared to the one before it',
    r->>'body' like '%الأسبوع%');
  perform pg_temp.chk('and the goal and phase are carried',
    r->>'body' like '%الهدف:%' and r->>'body' like '%نراقب%');

  -- Arabic counts 3–10 as ليالٍ and 11+ as ليلة. Getting this wrong is small,
  -- and small is exactly what makes a product sound machine-made.
  perform pg_temp.chk('nine nights reads as ليالٍ, not ليلة',
    r->>'body' like '%٩ ليالٍ%' and r->>'body' not like '%٩ ليلة%');
end $$;


\echo '=== IT READS. IT NEVER WRITES. ==='
do $$
declare p uuid; before_logs int; before_followers int;
begin
  p := pg_temp.fam('rd-ro', 4, true);
  select count(*) into before_logs from public.daily_logs;
  select count(*) into before_followers from public.followers;

  perform public.adam_reading(p);
  perform public.adam_reading(p);

  perform pg_temp.chk('calling it twice changes no row anywhere',
    (select count(*) from public.daily_logs) = before_logs
    and (select count(*) from public.followers) = before_followers,
    'a reading that mutates is a reading nobody can trust to look at twice');
end $$;

do $$
begin
  perform pg_temp.chk('an unknown parent returns unknown, not an exception',
    public.adam_reading(gen_random_uuid())->>'state' = 'unknown');
  perform pg_temp.chk('and a null parent likewise',
    public.adam_reading(null)->>'state' = 'unknown');
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 44), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
