\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.family(p_name text) returns uuid
language plpgsql as $$
declare v uuid; c uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into v;
  insert into public.children (follower_id, name, is_primary)
  values (v, p_name, true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                               evidence_count, window_start, window_end)
select c, ch.follower_id, 'sleep', sc.label_ar, 'confirmed', 4, sc.window_start, sc.window_end
  from public.children ch, public.situation_catalog sc
 where ch.id = c and sc.key = 'sleep';
  return v;
end $$;

create or replace function pg_temp.sit_of(p uuid) returns uuid language sql as $$
  select s.id from public.situations s join public.children c on c.id = s.child_id
  where c.follower_id = p limit 1;
$$;

\echo '=== THE EVENING MESSAGE GIVES BEFORE IT ASKS ==='
do $$
declare p uuid; s uuid; t text;
begin
  p := pg_temp.family('مالك'); s := pg_temp.sit_of(p);

  -- Case 3: first ever harvest. Nothing to give but today's own step.
  insert into public.daily_logs (follower_id, log_date, step_given, situation_id, seed_sent_at)
  values (p, current_date, 'تنبيه قبل النوم بعشر دقائق', s, now());

  t := public.get_harvest_prompt(p);
  perform pg_temp.chk('the first evening message hands back today''s own step',
    t like '%تنبيه قبل النوم بعشر دقائق%', t);
  perform pg_temp.chk('and it is never a blank question',
    t not like 'كيف كانت%' and t like '%كيف مرّت؟', t);
  perform pg_temp.chk('the ask comes last, after the gift',
    position('كيف مرّت؟' in t) > position('تنبيه' in t), t);

  -- Case 2: something worked before -> hand that back instead.
  insert into public.daily_logs (follower_id, log_date, step_given, night_result, situation_id)
  values (p, current_date - 4, 'خفّفنا الأضواء', 'calm', s);
  t := public.get_harvest_prompt(p);
  perform pg_temp.chk('a step that once worked outranks today''s untested one',
    t like '%آخر مرة نفعت معكم%' and t like '%خفّفنا الأضواء%', t);

  -- Case 1: THE moment. Two prior calms in the SAME situation.
  insert into public.daily_logs (follower_id, log_date, step_given, night_result, situation_id)
  values (p, current_date - 6, 'خفّفنا الأضواء', 'calm', s);
  t := public.get_harvest_prompt(p);
  perform pg_temp.chk('a counted repeat outranks everything — the scoreboard',
    t like '%مالك هدأ%' and t like '%مرّتين%', t);
  perform pg_temp.chk('and it names the situation, so «twice» is never about two different things',
    t like '%النوم%', t);
  -- situation_label_ar returns «النوم», not «عند النوم». Without the
  -- preposition the sentence reads "calmed twice this month the sleep" —
  -- grammatical nonsense that every assertion above still passes.
  perform pg_temp.chk('the repeat sentence carries its preposition',
    t like '%هذا الشهر عند %', t);
end $$;

\echo '=== A REPEAT IS NEVER COUNTED ACROSS DIFFERENT SITUATIONS ==='
do $$
declare p uuid; s1 uuid; c uuid; s2 uuid; t text;
begin
  p := pg_temp.family('سارة'); s1 := pg_temp.sit_of(p);
  select id into c from public.children where follower_id = p;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                               evidence_count, window_start, window_end)
select c, ch.follower_id, 'meal', sc.label_ar, 'confirmed', 2, sc.window_start, sc.window_end
  from public.children ch, public.situation_catalog sc
 where ch.id = c and sc.key = 'meal' returning id into s2;

  insert into public.daily_logs (follower_id, log_date, step_given, situation_id, seed_sent_at)
  values (p, current_date, 'خطوة اليوم', s1, now());
  -- two calm outcomes, but in the OTHER situation
  insert into public.daily_logs (follower_id, log_date, step_given, night_result, situation_id)
  values (p, current_date - 3, 'شيء آخر', 'calm', s2),
         (p, current_date - 5, 'شيء آخر', 'calm', s2);

  t := public.get_harvest_prompt(p);
  perform pg_temp.chk('two calms in another situation do NOT become «twice» here',
    t not like '%سارة هدأ%', t);
  perform pg_temp.chk('it falls back to the step that worked instead',
    t like '%آخر مرة نفعت معكم%', t);
end $$;

\echo '=== THE SCOREBOARD COUNTS THE PARENT, NOT THE CHILD ==='
do $$
declare p uuid; s uuid; e jsonb; b text;
begin
  p := pg_temp.family('يوسف'); s := pg_temp.sit_of(p);
  insert into public.daily_logs (follower_id, log_date, night_result, situation_id) values
    (p, current_date,     'hard', s),
    (p, current_date - 1, 'hard', s),
    (p, current_date - 2, 'calm', s),
    (p, current_date - 3, 'skip', s),
    (p, current_date - 9, 'hard', s);

  e := public.parent_effort(p);
  perform pg_temp.chk('an attempt counts whether it worked or not',
    (e->>'tried_this_week')::int = 3, e::text);
  perform pg_temp.chk('a night too tired to try is not held against them',
    (e->>'tried_this_week')::int = 3, 'skip is honest, not a failure');

  b := public.compose_menu_body('menu_progress', p);
  -- Not `like 'هذا الأسبوع%'`: the surface now opens with a heading naming the
  -- child, because a parent tapping /progress for the first time was landing
  -- mid-sentence. What the assertion is actually for survives that: the first
  -- thing said ABOUT THE WEEK is what the parent did, not what the child did.
  perform pg_temp.chk('/progress opens with what THEY did', b like '%هذا الأسبوع: جرّبتم%', b);
  -- "١ منها" reads like a spreadsheet row. One and two are words.
  perform pg_temp.chk('small counts are words, not digits', b not like '%١ منها%', b);
  perform pg_temp.chk('the child''s outcome is evidence, not the headline',
    position('جرّبتم' in b) < position('بهدوء' in b), b);
  perform pg_temp.chk('a week with no calm outcome is still a week they showed up',
    public.compose_menu_body('menu_progress', p) like '%جرّبتم%', b);
end $$;

\echo '=== A WORSE WEEK STILL COUNTS THE TRYING ==='
do $$
declare p uuid; s uuid; b text;
begin
  p := pg_temp.family('أمين'); s := pg_temp.sit_of(p);
  insert into public.daily_logs (follower_id, log_date, night_result, situation_id) values
    (p, current_date,      'hard', s),
    (p, current_date - 8,  'calm', s),
    (p, current_date - 9,  'calm', s),
    (p, current_date - 10, 'hard', s);
  b := public.compose_menu_body('menu_progress', p);
  perform pg_temp.chk('a lighter week is named without blame',
    b like '%أسبوع أثقل%' and b like '%المحاولة نفسها تُحسب%', b);
end $$;

\echo '=== THE INTENTION IS ASKED ONCE, AND ONLY AFTER SOMETHING WORKED ==='
do $$
declare p uuid; s uuid; ok boolean;
begin
  p := pg_temp.family('لينا'); s := pg_temp.sit_of(p);
  perform pg_temp.chk('not asked before anything has worked',
    not public.should_ask_intention(p), 'abstract to an exhausted stranger');

  insert into public.daily_logs (follower_id, log_date, night_result, situation_id)
  values (p, current_date - 1, 'calm', s);
  perform pg_temp.chk('asked once something has worked', public.should_ask_intention(p));

  ok := public.record_intention(p, 'أب هادئ لا يصرخ');
  perform pg_temp.chk('an answer is recorded', ok);
  perform pg_temp.chk('and never asked again', not public.should_ask_intention(p));

  ok := public.record_intention(p, 'شيء مختلف تماماً');
  perform pg_temp.chk('a later answer NEVER overwrites who they said they were', not ok,
    (select intention_text from public.followers where id = p));

  perform pg_temp.chk('an empty answer is refused', not public.record_intention(p, '   '));
end $$;

\echo '=== THE JOURNEY IS A FORK, AND ONLY AFTER THEIR OWN EVIDENCE ==='
do $$
declare p uuid; s uuid; o jsonb;
begin
  p := pg_temp.family('جود'); s := pg_temp.sit_of(p);

  o := public.offer_ready(p);
  perform pg_temp.chk('a new parent is not ready, and we say what is missing',
    not (o->>'ready')::boolean and (o->>'missing') like '%three_attempts%', o->>'missing');
  perform pg_temp.chk('and no fork is offered', o->>'fork_ar' is null);

  insert into public.daily_logs (follower_id, log_date, night_result, situation_id) values
    (p, current_date,     'calm', s),
    (p, current_date - 1, 'calm', s),
    (p, current_date - 2, 'hard', s);

  o := public.offer_ready(p);
  perform pg_temp.chk('after three attempts and two outcomes, the fork exists',
    (o->>'ready')::boolean, o->>'missing');
  perform pg_temp.chk('the fork names the child and asks, it does not offer',
    (o->>'fork_ar') like '%جود%' and (o->>'fork_ar') like '%أم نشتغل عليه حتى يتغيّر؟%',
    o->>'fork_ar');
  perform pg_temp.chk('the fork carries no price, no product name, no urgency',
    (o->>'fork_ar') !~ '(سعر|دينار|رحلة|اشتراك|الآن فقط|عرض|[0-9])', o->>'fork_ar');

  -- P1: crisis suppresses commerce, and it must suppress the fork too
  insert into public.parent_strain (parent_id, level) values (p, 2);
  o := public.offer_ready(p);
  perform pg_temp.chk('strain withdraws the fork silently',
    not (o->>'ready')::boolean and o->>'fork_ar' is null
    and (o->>'missing') like '%commerce_blocked%', o->>'missing');
end $$;

\echo '=== AND NONE OF IT ADDRESSES A MOTHER ==='
do $$
declare p uuid; s uuid; bad text[] := '{}';
begin
  p := pg_temp.family('رزان'); s := pg_temp.sit_of(p);
  insert into public.daily_logs (follower_id, log_date, step_given, night_result, situation_id, seed_sent_at)
  values (p, current_date, 'خطوة', null, s, now()),
         (p, current_date - 2, 'خفّفنا الأضواء', 'calm', s, null),
         (p, current_date - 3, 'خفّفنا الأضواء', 'calm', s, null);

  if public.get_harvest_prompt(p) ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then
    bad := bad || 'harvest'; end if;
  if public.compose_menu_body('menu_progress', p) ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then
    bad := bad || 'progress'; end if;
  if coalesce(public.offer_ready(p)->>'fork_ar','') ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then
    bad := bad || 'fork'; end if;
  if (select body_ar from public.conversation_moments where key='intention_ask')
       ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then
    bad := bad || 'intention_ask'; end if;

  perform pg_temp.chk('every new sentence speaks to a household, not a mother',
    cardinality(bad) = 0, array_to_string(bad, ', '));
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 60)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 56), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
