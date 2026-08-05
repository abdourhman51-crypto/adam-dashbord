-- قراءة آدم — the paid product's centre
--
-- Founder's design, 2026-08-07: the paid tier is not "more messages". It is a
-- reading of your own house that nobody else could write, because it is built
-- from your child's nights and nobody else's. Free parents see it locked, and
-- what they see is真 — a real line from their own data — because a tease of
-- something invented would cost more credibility than it buys intent.
--
-- ── The rule that shaped this ─────────────────────────────────────────────────
--
-- «اذا المستخدم دفع نحققولو وعد سريع بش ميحسش بخيبة امل».
--
-- My first proposal needed fifteen logged nights before it said anything, which
-- means a parent pays and meets an empty screen. That is the worst moment in any
-- subscription product and it is entirely self-inflicted. So the reading has FOUR
-- states, and every one of them gives something:
--
--   locked     free. One true line from their own data if there is one, and an
--              honest description of what the full reading is. Never a fake
--              preview.
--   opened     paid, no nights logged yet. THE REWARD. Everything ADAM already
--              knows, said back to them, plus the agreed goal and the clock.
--              This fires the moment the money is confirmed — nothing to wait for.
--   gathering  paid, 1–6 nights. Real but partial: the nights so far, what has
--              gone calm, and the first thing that repeats.
--   full       paid, 7+ nights. The whole reading — what repeats, what actually
--              calms ranked by how often it worked, the trend against last week,
--              and the distance to the goal.
--
-- Seven nights, not fifteen: a week is the smallest honest unit for «مقارنة
-- بالأسبوع الماضي», and everything before it is still shown, just labelled for
-- what it is.
--
-- ── Why this is safe to build with the workflows off ──────────────────────────
--
-- It reads. It writes nothing, sends nothing, and costs nothing to exist. Every
-- state is reachable in the offline suite by walking a synthetic family through
-- the production writers, which is how all four are tested.

begin;

-- Registered so the copy law knows the surface exists and the menu can list it.
-- 'reference' because a reading is longer than three lines by nature; that is
-- the category the line budget was widened for.
insert into public.conversation_moments
  (key, tier, category, max_lines, buttons, buttons_forbidden, requires_commerce, note)
values
  ('menu_reading', 'composed', 'reference', 22, '[]'::jsonb, false, false,
   'قراءة آدم. Four states — locked / opened / gathering / full. A paid parent '
   'gets something the moment they pay; a free parent gets one true line from '
   'their own data and an honest description, never an invented preview.')
on conflict (key) do update
  set category = excluded.category, max_lines = excluded.max_lines, note = excluded.note;

-- The reading. Returns the state alongside the body so a caller can branch on it
-- (a locked reading is the one place the offer may be named) without parsing Arabic.
create or replace function public.adam_reading(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_nl        text := chr(10);
  v_paid      boolean;
  v_child     text;
  v_sit       text;
  v_nights    int;
  v_calm      int;
  v_hard      int;
  v_calm_prev int;
  v_trigger   text;
  v_calms     text;
  v_stage     jsonb;
  v_state     text;
  v_body      text;
  v_nights_word text;
  v_lines     text[] := '{}';
begin
  if p_parent_id is null then
    return jsonb_build_object('state', 'unknown', 'body', null);
  end if;

  select f.funnel_stage = 'paid_active' into v_paid
  from public.followers f where f.id = p_parent_id;
  if not found then
    return jsonb_build_object('state', 'unknown', 'body', null);
  end if;

  select nullif(btrim(c.name), '') into v_child
  from public.children c
  where c.follower_id = p_parent_id and c.name not in ('الطفل', 'الطفلة')
  order by c.is_primary desc, c.created_at limit 1;

  select s.label_ar into v_sit
  from public.situations s
  where s.parent_id = p_parent_id and s.status = 'confirmed'
  order by s.evidence_count desc, s.last_observed desc limit 1;

  -- The evidence. Only nights she actually answered count as nights.
  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm'),
         count(*) filter (where d.night_result = 'hard')
    into v_nights, v_calm, v_hard
  from public.daily_logs d where d.follower_id = p_parent_id;

  select count(*) filter (where d.night_result = 'calm') into v_calm_prev
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date >  current_date - 14
    and d.log_date <= current_date - 7;

  -- What repeats: the hardest moment, named the way she named it.
  select public.hard_moment_label(d.hard_moment) into v_trigger
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.hard_moment is not null
  group by d.hard_moment order by count(*) desc limit 1;

  -- What actually calms: her own steps, ranked by how often they worked. This is
  -- the line no article can write, and the reason the reading is worth paying for.
  select string_agg(line, v_nl) into v_calms from (
    select '• ' || coalesce(d.step_given, d.seed_text) || ' — نجحت '
           || public.ar_digits((count(*) filter (where d.step_status = 'done'))::text)
           || ' من ' || public.ar_digits(count(*)::text) as line
    from public.daily_logs d
    -- seed_text is what the rhythm writes; step_given is the legacy column the
    -- old checkin engine used. Ranking on step_given alone returned nothing at
    -- all, which is how the single most valuable line in the reading came to be
    -- silently missing until it was rendered and looked at.
    where d.follower_id = p_parent_id
      and coalesce(d.step_given, d.seed_text) is not null
    group by coalesce(d.step_given, d.seed_text)
    having count(*) filter (where d.step_status = 'done') > 0
    order by count(*) filter (where d.step_status = 'done') desc, count(*) desc
    limit 3
  ) t;

  v_stage := public.stage_state(p_parent_id);

  -- Arabic does not pluralise the way a format string wants it to: three to ten
  -- nights are «ليالٍ», eleven and above are «ليلة». Getting this wrong is small
  -- and it is exactly the kind of small that makes a product sound machine-made.
  v_nights_word := case when v_nights between 3 and 10 then 'ليالٍ' else 'ليلة' end;

  -- ── The ladder ──────────────────────────────────────────────────────────────
  v_state := case
    when not v_paid      then 'locked'
    when v_nights = 0    then 'opened'
    when v_nights < 7    then 'gathering'
    else                      'full' end;

  if v_state = 'locked' then
    v_lines := array_append(v_lines, '📖 قراءة آدم');
    v_lines := array_append(v_lines, '');
    -- One true line, from her house, or nothing. Never an invented preview.
    if v_trigger is not null then
      v_lines := array_append(v_lines, ('لاحظتُ أنّ أصعب اللحظات عندكم تتكرّر ' || v_trigger || '.'));
    elsif v_sit is not null and v_child is not null then
      v_lines := array_append(v_lines, ('أعرف أنّ ما يتعبكم مع ' || v_child || ' هو ' || v_sit || '.'));
    elsif v_child is not null then
      v_lines := array_append(v_lines, ('أعرف ' || v_child || '، ولا أعرف بعد ما الذي يهدّئه.'));
    else
      v_lines := array_append(v_lines, 'لا أعرف بيتكم بعد بما يكفي لأقرأه.');
    end if;
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'والقراءة الكاملة تقول أكثر من هذا بكثير:');
    v_lines := array_append(v_lines, 'ما الذي يتكرّر عندكم بالضبط، وما الذي جرّبتموه ونجح فعلاً —');
    v_lines := array_append(v_lines, 'مرتّباً بعدد المرّات التي نجح فيها، لا بما يُقال عموماً.');
    v_lines := array_append(v_lines, 'ثم كيف يتغيّر ذلك أسبوعاً بعد أسبوع.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'وهي مبنيّة من ليالي طفلكم وحده. لا تُكتب لأحد غيركم.');
    v_lines := array_append(v_lines, 'تُفتح مع المرافقة الكاملة، ويتولّاها فريق آدم.');

  elsif v_state = 'opened' then
    v_lines := array_append(v_lines, ('📖 قراءة ' || coalesce(v_child, 'طفلكم') || ' — فُتحت الآن'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'هذا ما أعرفه عنكم حتى اللحظة:');
    if v_child is not null then
      v_lines := array_append(v_lines, ('• طفلكم ' || v_child || '.'));
    end if;
    if v_sit is not null then
      v_lines := array_append(v_lines, ('• وما يتعبكم هو ' || v_sit || '.'));
    end if;
    if (v_stage->>'in_stage')::boolean then
      v_lines := array_append(v_lines, ('• واتّفقنا على: ' || (v_stage->>'objective_text') || '.'));
    end if;
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'من الليلة أبدأ أسألكم كل مساء سؤالاً واحداً قصيراً.');
    v_lines := array_append(v_lines, 'كل إجابة تضيف سطراً إلى هذه الصفحة.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'بعد ثلاث ليالٍ أريكم ما يتكرّر.');
    v_lines := array_append(v_lines, 'وبعد أسبوع أريكم ما يهدّئه فعلاً، وكيف تغيّر.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'لا شيء مطلوب منكم الآن سوى أن تحكوا لي كيف مرّت الليلة.');

  elsif v_state = 'gathering' then
    v_lines := array_append(v_lines, ('📖 قراءة ' || coalesce(v_child, 'طفلكم')));
    v_lines := array_append(v_lines, '');
    v_lines := v_lines || ('حتى الآن: ' || public.ar_digits(v_nights::text) || ' ' || v_nights_word || ' حكيتم لي عنها، '
                           || public.ar_digits(v_calm::text) || ' منها مرّت بهدوء.');
    if v_trigger is not null then
      v_lines := array_append(v_lines, ('وأصعبها يتكرّر ' || v_trigger || '.'));
    end if;
    if v_calms is not null then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, 'وما نجح معكم حتى الآن:');
      v_lines := array_append(v_lines, v_calms);
    end if;
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'ما زالت الصورة تتشكّل — بعد أسبوع كامل أستطيع أن أقارن،');
    v_lines := array_append(v_lines, 'وأقول لكم إن كان ما تفعلونه يعمل أم لا، بالأرقام لا بالانطباع.');

  else
    v_lines := array_append(v_lines, ('📖 قراءة ' || coalesce(v_child, 'طفلكم')));
    v_lines := array_append(v_lines, '');
    v_lines := v_lines || ('من ' || public.ar_digits(v_nights::text) || ' ' || v_nights_word || ' حكيتم لي عنها، '
                           || public.ar_digits(v_calm::text) || ' مرّت بهدوء و'
                           || public.ar_digits(v_hard::text) || ' كانت صعبة.');
    if v_trigger is not null then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('ما يتكرّر: أصعب اللحظات تأتي ' || v_trigger || '.'));
    end if;
    if v_calms is not null then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, 'وما يهدّئه فعلاً — من تجربتكم أنتم، لا من نصيحة عامّة:');
      v_lines := array_append(v_lines, v_calms);
    end if;
    v_lines := array_append(v_lines, '');
    if v_calm > v_calm_prev then
      v_lines := array_append(v_lines, 'وهذا الأسبوع أهدأ من الذي قبله.');
    elsif v_calm < v_calm_prev then
      v_lines := array_append(v_lines, 'وهذا الأسبوع أصعب من الذي قبله — يحدث، والمهم أنكم واصلتم.');
    else
      v_lines := array_append(v_lines, 'وهو ثابت مع الأسبوع الماضي.');
    end if;
    if (v_stage->>'in_stage')::boolean then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('الهدف: ' || (v_stage->>'objective_text') || '.'));
      v_lines := array_append(v_lines, (v_stage->>'phase_ar'));
    end if;
  end if;

  v_body := array_to_string(v_lines, v_nl);

  return jsonb_build_object(
    'state', v_state,
    'body', v_body,
    'child_name', v_child,
    'nights', v_nights,
    'calm', v_calm,
    'in_stage', coalesce((v_stage->>'in_stage')::boolean, false));
end $fn$;

comment on function public.adam_reading(uuid) is
  'قراءة آدم — the paid tier''s centre. Four states, every one of which says '
  'something: locked (free, one TRUE line from their own data), opened (paid, '
  'nothing logged yet — the reward fires on payment, not after a wait), '
  'gathering (1-6 nights), full (7+, with the week-on-week comparison). '
  'Reads only: writes nothing and sends nothing.';

revoke execute on function public.adam_reading(uuid) from public, anon, authenticated;
grant execute on function public.adam_reading(uuid) to service_role;

commit;
