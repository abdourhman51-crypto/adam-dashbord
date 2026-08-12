\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);

create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- ---------------------------------------------------------------
-- One family, built up fact by fact, so knowledge_depth() is
-- observed rising rather than asserted.
-- ---------------------------------------------------------------
do $$
declare p uuid; c uuid; d jsonb; u jsonb; i int;
begin
  insert into public.followers (platform_user_id, country)
  values ('k-test','DZ') returning id into p;

  -- level 0: nothing known
  d := public.knowledge_depth(p);
  perform pg_temp.chk('depth 0 when nothing is known', (d->>'level')::int = 0, d->>'now_possible');
  perform pg_temp.chk('rescue sends at depth 0',
    (public.can_send('rescue', p)->>'can_send')::boolean);
  perform pg_temp.chk('seed refuses at depth 0',
    not (public.can_send('seed', p)->>'can_send')::boolean,
    public.can_send('seed', p)->>'reason');

  -- level 1: a name
  insert into public.children (follower_id, name, is_primary)
  values (p, 'يوسف', true) returning id into c;
  d := public.knowledge_depth(p);
  perform pg_temp.chk('depth 1 once the child has a name', (d->>'level')::int = 1);
  perform pg_temp.chk('seed still refuses on a name alone',
    not (public.can_send('seed', p)->>'can_send')::boolean,
    public.can_send('seed', p)->>'reason');

  -- level 2: a situation
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                               evidence_count, window_start, window_end)
select c, ch.follower_id, 'sleep', sc.label_ar, 'confirmed', 3, sc.window_start, sc.window_end
  from public.children ch, public.situation_catalog sc
 where ch.id = c and sc.key = 'sleep';
  d := public.knowledge_depth(p);
  perform pg_temp.chk('depth 2 once a situation is detected', (d->>'level')::int = 2);
  perform pg_temp.chk('seed sends once grounded',
    (public.can_send('seed', p)->>'can_send')::boolean);

  -- level 3: three logged results
  for i in 1..3 loop
    insert into public.daily_logs (follower_id, log_date, night_result, hard_moment)
    values (p, current_date - i, case when i = 1 then 'calm' else 'hard' end, 'sleep');
  end loop;
  d := public.knowledge_depth(p);
  perform pg_temp.chk('depth 3 at three logged results', (d->>'level')::int = 3);
  perform pg_temp.chk('mirror fires at three results',
    (public.can_send('mirror', p)->>'can_send')::boolean);

  -- level 4: a month of outcomes
  for i in 4..20 loop
    insert into public.daily_logs (follower_id, log_date, night_result, step_status, step_given)
    values (p, current_date - i, 'calm', 'done', 'تنبيه قبل الانتقال');
  end loop;
  d := public.knowledge_depth(p);
  perform pg_temp.chk('depth 4 at a month of outcomes', (d->>'level')::int = 4, d->>'now_possible');
  perform pg_temp.chk('naming a goal becomes possible only at depth 4',
    d->'now_possible' @> '["name_a_goal"]'::jsonb);

  -- =============================================================
  -- §2.6 — could this exact message be sent to a different family?
  -- =============================================================
  u := public.passes_uniqueness_test(p, 'الأطفال يحتاجون روتيناً ثابتاً قبل النوم.');
  perform pg_temp.chk('a generic tip does not send',
    not (u->>'passes')::boolean and u->>'reason' = 'generic', u->>'reason');

  u := public.passes_uniqueness_test(p, 'يوسف يحتاج روتيناً ثابتاً قبل النوم.');
  perform pg_temp.chk('a generic tip WITH THE NAME IN IT still does not send',
    not (u->>'passes')::boolean and u->>'reason' = 'identity_only', u->>'reason');

  u := public.passes_uniqueness_test(p,
        'تجربة التنبيه قبل الانتقال نجحت مع يوسف أكثر من مرة — نبني عليها.');
  perform pg_temp.chk('a message built on what worked for THIS child sends',
    (u->>'passes')::boolean, u->>'matched_measured');

  u := public.passes_uniqueness_test(p, 'الليلة الصعبة الوحيدة كانت عند النوم.');
  perform pg_temp.chk('a message naming this family''s own situation sends',
    (u->>'passes')::boolean, u->>'matched_measured');

  -- =============================================================
  -- §2.8 — provenance, not content filtering
  -- =============================================================
  -- follower_id is NOT NULL in production; derived rather than passed so the
  -- caller cannot get the pair wrong.
  insert into public.child_patterns (child_id, follower_id, pattern_label, status, safe_for_record)
  -- 'active', not 'confirmed': child_patterns_status_check allows only
  -- active / improving / resolved / dormant, so 'confirmed' was a row production
  -- would refuse.
  values (c, p, 'التنقل بين ثلاث عائلات', 'active', false);   -- a real live row
  perform pg_temp.chk('a disclosure never becomes a family token',
    not (public.family_tokens(p)->'measured' @> '["التنقل بين ثلاث عائلات"]'::jsonb),
    public.family_tokens(p)->>'measured');

  u := public.passes_uniqueness_test(p, 'التنقل بين ثلاث عائلات صعب على يوسف.');
  perform pg_temp.chk('a message quoting a disclosure does not send',
    not (u->>'passes')::boolean, u->>'reason');

  -- Cleared through the ONLY door production leaves open. A bare UPDATE is
  -- refused by guard_safe_for_record, which demands an audit row written in the
  -- same transaction naming who approved it and why — so the bare UPDATE this
  -- used to do was setting a flag the disclosure safeguard makes unsettable.
  perform public.set_pattern_record_visibility(
    (select id from public.child_patterns
      where child_id = c and pattern_label = 'التنقل بين ثلاث عائلات'),
    true, 'operator:test',
    'Reviewed for the record test: the label is the parent''s own wording and was cleared deliberately.');
  perform pg_temp.chk('the same label DOES count once explicitly cleared',
    public.family_tokens(p)->'measured' @> '["التنقل بين ثلاث عائلات"]'::jsonb,
    'safe_for_record is the only thing that changed');

  -- =============================================================
  -- §2.5 — harvest needs its seed
  -- =============================================================
  perform pg_temp.chk('harvest refuses with no seed today',
    not (public.can_send('harvest', p)->>'can_send')::boolean,
    public.can_send('harvest', p)->>'reason');

  insert into public.daily_logs (follower_id, log_date, seed_sent_at)
  values (p, current_date, now());
  perform pg_temp.chk('harvest sends once a seed went out today',
    (public.can_send('harvest', p)->>'can_send')::boolean);

  update public.daily_logs set harvest_sent_at = now()
   where follower_id = p and log_date = current_date;
  perform pg_temp.chk('harvest refuses twice in one day',
    not (public.can_send('harvest', p)->>'can_send')::boolean,
    public.can_send('harvest', p)->>'reason');

  perform pg_temp.chk('journey_step refuses with no live journey',
    not (public.can_send('journey_step', p)->>'can_send')::boolean,
    public.can_send('journey_step', p)->>'reason');

  perform pg_temp.chk('an unknown kind refuses rather than defaulting open',
    not (public.can_send('newsletter', p)->>'can_send')::boolean,
    public.can_send('newsletter', p)->>'reason');
end $$;

-- ---------------------------------------------------------------
-- A second family. The point of §2.6 is cross-family, so it has to
-- be tested across two families and not one.
-- ---------------------------------------------------------------
do $$
declare p2 uuid; c2 uuid; msg text;
begin
  insert into public.followers (platform_user_id, country)
  values ('k-test-2','EG') returning id into p2;
  insert into public.children (follower_id, name, is_primary)
  values (p2, 'سارة', true) returning id into c2;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                               evidence_count, window_start, window_end)
select c2, ch.follower_id, 'study', sc.label_ar, 'confirmed', 1, sc.window_start, sc.window_end
  from public.children ch, public.situation_catalog sc
 where ch.id = c2 and sc.key = 'study';

  msg := 'تجربة التنبيه قبل الانتقال نجحت مع يوسف أكثر من مرة — نبني عليها.';

  perform pg_temp.chk('family A''s message passes for family A',
    (public.passes_uniqueness_test(
      (select id from public.followers where platform_user_id='k-test'), msg)->>'passes')::boolean);

  perform pg_temp.chk('THE SAME MESSAGE fails for family B',
    not (public.passes_uniqueness_test(p2, msg)->>'passes')::boolean,
    'this is §2.6 stated exactly');
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  → ' || left(detail, 60), '')
from pg_temp.r order by n;

select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
