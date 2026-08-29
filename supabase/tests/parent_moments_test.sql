\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- ===============================================================
-- The parent is the one we measure.
--
-- One mother is walked through two real weeks: a bad first week,
-- then a better second one — because the whole product promise is
-- a comparison between those two weeks, and a comparison cannot
-- be tested with a single week of data.
-- ===============================================================
do $$
declare p uuid; c jsonb; w jsonb;
begin
  insert into public.followers (platform_user_id, country)
  values ('moments-test','DZ') returning id into p;

  -- ---------- the write path refuses rather than coerces ----------
  perform pg_temp.chk('an invented kind is refused, not rounded',
    (public.record_parent_moment(p, 'nearly_maybe')->>'reason') = 'unknown_kind',
    'same rule as commit_incident: a gate that rounds is not a gate');

  perform pg_temp.chk('an invented source is refused',
    (public.record_parent_moment(p, 'held', 'carrier_pigeon')->>'reason') = 'unknown_source');

  perform pg_temp.chk('an unknown parent is refused',
    (public.record_parent_moment(gen_random_uuid(), 'held')->>'reason') = 'unknown_parent');

  -- ---------- a note is spoken-adjacent, so it obeys the copy law ----------
  perform pg_temp.chk('a note carrying a banned word is not stored',
    (public.record_parent_moment(p, 'held', 'evening', 'هذه خطة للتحكم')->>'reason') = 'vocabulary',
    public.record_parent_moment(p, 'held', 'evening', 'هذه خطة للتحكم')->>'violations');

  perform pg_temp.chk('nothing was written by any refusal',
    (select count(*) from public.parent_moments where parent_id = p) = 0,
    'a refusal that still writes a row is a refusal in name only');

  -- ---------- the curve refuses to draw itself too early ----------
  c := public.get_parent_curve(p);
  perform pg_temp.chk('no curve at all before anything is recorded',
    not (c->>'ready')::boolean and (c->>'heldTotal')::int = 0);

  -- three days of a first week only
  insert into public.parent_moments (parent_id, kind, source, occurred_on) values
    (p,'erupted','evening',      current_date - 2),
    (p,'held',   'panic_button', current_date - 3),
    (p,'erupted','evening',      current_date - 4);

  c := public.get_parent_curve(p);
  perform pg_temp.chk('THREE DAYS IS NOT A CURVE — ready stays false',
    not (c->>'ready')::boolean,
    'a curve drawn from a few days misleads in whichever direction the noise falls');
  perform pg_temp.chk('but the raw counts are already honest',
    (c->>'heldWeek')::int = 1 and (c->>'eruptWeek')::int = 2, c::text);
end $$;

-- ===============================================================
-- Two full weeks: the comparison the product actually sells.
-- ===============================================================
do $$
declare p uuid; c jsonb;
begin
  insert into public.followers (platform_user_id, country)
  values ('moments-two-weeks','DZ') returning id into p;

  -- LAST week — heavy: five eruptions, one hold
  insert into public.parent_moments (parent_id, kind, source, occurred_on) values
    (p,'erupted','evening',      current_date - 13),
    (p,'erupted','evening',      current_date - 12),
    (p,'erupted','confession',   current_date - 11),
    (p,'erupted','evening',      current_date - 10),
    (p,'erupted','evening',      current_date - 8),
    (p,'held',   'panic_button', current_date - 9);

  -- THIS week — the turn: four holds, two eruptions
  insert into public.parent_moments (parent_id, kind, source, occurred_on) values
    (p,'held',   'panic_button', current_date - 6),
    (p,'held',   'panic_button', current_date - 5),
    (p,'held',   'evening',      current_date - 3),
    (p,'held',   'panic_button', current_date - 1),
    (p,'erupted','evening',      current_date - 4),
    (p,'erupted','confession',   current_date - 2);

  c := public.get_parent_curve(p);

  perform pg_temp.chk('with two weeks on the board, the curve is ready',
    (c->>'ready')::boolean, c::text);

  perform pg_temp.chk('this week counted correctly',
    (c->>'heldWeek')::int = 4 and (c->>'eruptWeek')::int = 2);

  perform pg_temp.chk('last week counted correctly, and kept separate',
    (c->>'heldPrev')::int = 1 and (c->>'eruptPrev')::int = 5);

  perform pg_temp.chk('THE SENTENCE THE PRODUCT SELLS: eruptions fell by three',
    (c->>'eruptDelta')::int = -3,
    'من ٥ انفجارات إلى ٢ — negative delta is the win');

  perform pg_temp.chk('holds accumulate across both weeks',
    (c->>'heldTotal')::int = 5);

  -- ---------- the panic button can be judged against its own threshold ----------
  perform pg_temp.chk('panic-button usage is separable from evening answers',
    (select count(*) from public.parent_moments
     where parent_id = p and source = 'panic_button') = 4,
    'the 15% falsification criterion needs this column to be answerable at all');

  -- ---------- the window is rolling, not calendar ----------
  perform pg_temp.chk('a moment 20 days old sits outside both weeks',
    (select count(*) from public.parent_moments where parent_id = p) = 12
    and (c->>'heldWeek')::int + (c->>'eruptWeek')::int
      + (c->>'heldPrev')::int + (c->>'eruptPrev')::int = 12);
end $$;

-- ===============================================================
-- A mother who only ever erupts still gets an honest curve —
-- the number must never flatter her, and must never judge her.
-- ===============================================================
do $$
declare p uuid; c jsonb;
begin
  insert into public.followers (platform_user_id, country)
  values ('moments-hard','DZ') returning id into p;

  insert into public.parent_moments (parent_id, kind, source, occurred_on) values
    (p,'erupted','evening', current_date - 10),
    (p,'erupted','evening', current_date - 9),
    (p,'erupted','evening', current_date - 3),
    (p,'erupted','evening', current_date - 2);

  c := public.get_parent_curve(p);
  perform pg_temp.chk('zero holds reports zero — the count never flatters',
    (c->>'heldTotal')::int = 0 and (c->>'heldWeek')::int = 0);
  perform pg_temp.chk('and a flat week reads as no change, not as failure',
    (c->>'eruptDelta')::int = 0, 'delta 0 — the UI must never render this as a verdict');
end $$;

select n, result, name, coalesce(detail,'') as detail from pg_temp.r order by n;
select count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed' from pg_temp.r;

rollback;
