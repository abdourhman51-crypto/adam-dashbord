\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);

create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- ===============================================================
-- Phase 1 — the tantrum reading, ages 3-8.
--
-- The gate is walked in the order a real family arrives in: no
-- child, then a child with no name, then no age, then an age
-- outside the band, then inside it. Each step is observed
-- refusing for its OWN reason, because a gate that refuses for
-- the wrong reason sends ADAM to ask the wrong question.
-- ===============================================================
do $$
declare p uuid; c uuid; g jsonb; f jsonb; w jsonb; y int;
begin
  y := extract(year from now())::int;

  insert into public.followers (platform_user_id, country)
  values ('tantrum-test','DZ') returning id into p;

  -- ---------- the gate, walked ----------
  g := public.can_read_incident(p);
  perform pg_temp.chk('no child at all -> refuses, asks for the child',
    not (g->>'can_read')::boolean and g->'missing' ? 'child', g::text);

  insert into public.children (follower_id, name, birth_year, is_primary)
  values (p, null, null, true) returning id into c;

  g := public.can_read_incident(p);
  perform pg_temp.chk('a nameless child -> asks for the name AND the year',
    not (g->>'can_read')::boolean
    and g->'missing' ? 'child_name'
    and g->'missing' ? 'birth_year',
    g->>'missing');

  update public.children set name = 'يوسف' where id = c;
  g := public.can_read_incident(p);
  perform pg_temp.chk('named, no year -> asks only for the year',
    not (g->>'can_read')::boolean
    and g->'missing' ? 'birth_year'
    and not (g->'missing' ? 'child_name'),
    g->>'missing');

  -- ---------- the scope refusal is NOT a missing fact ----------
  update public.children set birth_year = y - 11 where id = c;
  g := public.can_read_incident(p);
  perform pg_temp.chk('an eleven-year-old -> out_of_band, not "missing"',
    not (g->>'can_read')::boolean
    and g->>'reason' = 'out_of_band'
    and jsonb_array_length(g->'missing') = 0,
    'the age is known; asking for it again would be the wrong question');

  update public.children set birth_year = y - 2 where id = c;
  perform pg_temp.chk('a two-year-old is also out of band',
    (public.can_read_incident(p)->>'reason') = 'out_of_band');

  -- ---------- inside the band ----------
  update public.children set birth_year = y - 4 where id = c;
  g := public.can_read_incident(p);
  perform pg_temp.chk('a four-year-old passes, in band 3_4',
    (g->>'can_read')::boolean and g->>'age_band' = '3_4', g->>'age_band');

  update public.children set birth_year = y - 8 where id = c;
  perform pg_temp.chk('an eight-year-old passes, in band 7_8',
    (public.can_read_incident(p)->>'age_band') = '7_8');

  -- ---------- the band boundaries are exact, not approximate ----------
  perform pg_temp.chk('the band is null at 9 and at 2, not clamped',
    public.tantrum_age_band(y - 9) is null and public.tantrum_age_band(y - 2) is null);
  perform pg_temp.chk('a null birth year yields a null band, never a guess',
    public.tantrum_age_band(null) is null);

  -- ---------- the frame the composer is allowed to draw on ----------
  update public.children set birth_year = y - 4 where id = c;
  f := public.get_tantrum_frame(p);
  perform pg_temp.chk('the frame carries the child by name',
    (f->>'ready')::boolean and f->>'child_name' = 'يوسف');
  perform pg_temp.chk('both kinds and the unclear case are offered',
    jsonb_array_length(f->'kinds') = 3);
  perform pg_temp.chk('all five drivers are offered',
    jsonb_array_length(f->'drivers') = 5);
  perform pg_temp.chk('all four phases are offered',
    jsonb_array_length(f->'phases') = 4);
  perform pg_temp.chk('the age answer is the 3_4 one, not a generic one',
    f->'age'->>'band' = '3_4' and (f->'age'->>'normal_ar') like '%متوقّعة%',
    f->'age'->>'normal_ar');
  perform pg_temp.chk('nothing is "recent" before anything has happened',
    jsonb_array_length(f->'recent') = 0);

  -- ---------- an out-of-band family gets no frame at all ----------
  update public.children set birth_year = y - 11 where id = c;
  perform pg_temp.chk('out of band -> no frame, and the reason travels with it',
    not (public.get_tantrum_frame(p)->>'ready')::boolean
    and public.get_tantrum_frame(p)->'gate'->>'reason' = 'out_of_band');
  update public.children set birth_year = y - 4 where id = c;

  -- ---------- commit_incident refuses rather than coercing ----------
  perform pg_temp.chk('an empty description is refused',
    (public.commit_incident(p, '   ')->>'reason') = 'empty_text');

  perform pg_temp.chk('an unknown source is refused',
    (public.commit_incident(p, 'صرخ عند النوم', 'telepathy')->>'reason') = 'unknown_source');

  perform pg_temp.chk('an invented kind is refused, NOT rounded to unclear',
    (public.commit_incident(p, 'صرخ عند النوم', 'text', 'tantrum_type_7')->>'reason') = 'unknown_kind',
    'a gate that rounds to the nearest valid value is not a gate');

  perform pg_temp.chk('an invented driver is refused',
    (public.commit_incident(p, 'صرخ', 'text', 'flood', 'mercury_retrograde')->>'reason') = 'unknown_driver');

  perform pg_temp.chk('an invented phase is refused',
    (public.commit_incident(p, 'صرخ', 'text', 'flood', 'body', 'later_maybe')->>'reason') = 'unknown_phase');

  -- ---------- the reading obeys the same law every spoken string obeys ----------
  w := public.commit_incident(p, 'صرخ عند النوم', 'text', 'flood', 'body', 'peak',
                              'هذه خطة لعلاج نوبات يوسف');
  perform pg_temp.chk('a reading carrying a banned word is not stored',
    not (w->>'committed')::boolean and w->>'reason' = 'vocabulary',
    w->>'violations');

  w := public.commit_incident(p, 'صرخ عند النوم', 'text', 'flood', 'body', 'peak',
                              'الرحلة بـ 2300 دينار');
  perform pg_temp.chk('a reading that speaks a price is not stored either',
    not (w->>'committed')::boolean and w->>'reason' = 'vocabulary',
    w->>'violations');

  perform pg_temp.chk('nothing was written by any of the refusals',
    (select count(*) from public.incidents where parent_id = p) = 0,
    'a refusal that still writes a row is a refusal in name only');

  -- ---------- the happy path ----------
  w := public.commit_incident(
         p,
         'ولى يصرّط ويتشدّ في الأرض كي نقولو حان وقت النوم، ما يسمع والو',
         'voice', 'flood', 'shift', 'peak',
         'يوسف انهار عند الانتقال إلى النوم، ولم يكن يسمع لأنه لم يعد قادراً.');
  perform pg_temp.chk('a complete, lawful reading is stored',
    (w->>'committed')::boolean and w->>'child_name' = 'يوسف', w::text);
  perform pg_temp.chk('the voice path is a first-class source, not an afterthought',
    (select source from public.incidents where parent_id = p) = 'voice');

  -- ---------- the second incident is the beginning of a pattern ----------
  perform public.commit_incident(p, 'نفس الشي البارح', 'voice', 'flood', 'shift', 'peak',
                                 'مرة ثانية عند الانتقال نفسه.');
  f := public.get_tantrum_frame(p);
  perform pg_temp.chk('two readings of the same shape surface as recent history',
    jsonb_array_length(f->'recent') = 2
    and f->'recent'->0->>'driver' = 'shift',
    'this is the only EARNED token here — §2.6 measured, not supplied');

  -- ---------- §2.8: the disclosure never becomes proactive material ----------
  perform pg_temp.chk('what the parent said is kept, and kept out of the reading',
    exists (select 1 from public.incidents
            where parent_id = p and raw_text like '%يصرّط%')
    and not exists (select 1 from public.incidents
            where parent_id = p and reading_ar like '%يصرّط%'),
    'raw_text is a disclosure; only the reading may be spoken');
end $$;

-- ===============================================================
-- The panic button is NOT tested here any more.
--
-- It moved into the mini app (components/PanicButton.tsx) on
-- 2026-08-30, with its scripts inline, because a parent mid-crisis
-- cannot wait for a round trip — and because reading 5,712 real
-- messages showed the scripts had to address the PARENT's own loss
-- of control, not the child's tantrum. Its data now lands in
-- parent_moments; see supabase/tests/parent_moments_test.sql.
-- ===============================================================

-- ===============================================================
-- The catalogs are copy, and copy is law-bound. These CHECKs
-- already ran at insert time; asserting them here is what makes
-- a later careless UPDATE visible.
-- ===============================================================
do $$
begin
  perform pg_temp.chk('no catalog string violates §0.7',
    not exists (
      select 1 from public.tantrum_kind_catalog
      where cardinality(public.copy_violations(label_ar || ' ' || tell_ar || ' ' || response_ar)) > 0)
    and not exists (
      select 1 from public.tantrum_driver_catalog
      where cardinality(public.copy_violations(label_ar || ' ' || tell_ar || ' ' || prevent_ar)) > 0)
    and not exists (
      select 1 from public.tantrum_phase_catalog
      where cardinality(public.copy_violations(label_ar || ' ' || works_ar || ' ' || backfire_ar)) > 0)
    and not exists (
      select 1 from public.tantrum_age_expectation
      where cardinality(public.copy_violations(normal_ar || ' ' || watch_ar)) > 0));

  perform pg_temp.chk('every phase names what backfires, not only what works',
    not exists (select 1 from public.tantrum_phase_catalog
                where btrim(coalesce(backfire_ar,'')) = ''),
    'naming the mistake is the half a tip library always omits');

  perform pg_temp.chk('every driver carries a move for BEFORE the eruption',
    not exists (select 1 from public.tantrum_driver_catalog
                where btrim(coalesce(prevent_ar,'')) = ''),
    'the before window is the only one with real leverage');

  perform pg_temp.chk('the three age answers differ from one another',
    (select count(distinct normal_ar) from public.tantrum_age_expectation) = 3,
    'one answer for all ages would be a horoscope');
end $$;

select n, result, name, coalesce(detail,'') as detail from pg_temp.r order by n;
select count(*) filter (where result = 'PASS') || ' / ' || count(*) || ' passed' from pg_temp.r;

rollback;
