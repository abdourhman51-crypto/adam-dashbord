-- ما بعد الوصول — built
--
-- The design is docs/after-arrival.md. Arrival is a handover, not an ending:
-- three moments across a week, the rhythm stepping down by itself, and a 30-day
-- watch that brings ADAM back unprompted and free if the calm breaks.
--
-- Four prohibitions from the design are enforced here rather than remembered:
--   1. no offer in the arrival message — its buttons are empty, and the
--      escape-hatch constraint is satisfied by having none at all
--   2. no stage renews itself — nothing below writes to `stages`
--   3. no expiry framing — the words are about a goal reached
--   4. ADAM never claims the result — asserted in the test suite, on the text
--
-- Nothing here sends. It composes and it derives; W3 is the sender it already
-- was, and it stays paused.

begin;

-- ── The rhythm steps down by itself ───────────────────────────────────────────
--
-- Nobody should have to ask ADAM to stop asking about a problem they solved.
-- A trigger rather than a line inside close_stage, because the rule is «whenever
-- a stage completes», and a stage could be completed by any hand — close_stage
-- today, an operator tomorrow.
--
-- Weekly, not stopped: the watch below needs a heartbeat to notice a relapse
-- through. And only ever a step DOWN — a parent who already chose 'stopped' is
-- not moved to weekly by this.
create or replace function public.step_rhythm_down_on_arrival()
returns trigger
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
begin
  if new.status = 'completed' and coalesce(old.status,'') <> 'completed' then
    update public.checkin_state
       set cadence = 'weekly', cadence_changed_at = now(), updated_at = now()
     where parent_id = new.parent_id
       and cadence = 'nightly';
  end if;
  return new;
end $fn$;

drop trigger if exists trg_arrival_quietens_rhythm on public.stages;
create trigger trg_arrival_quietens_rhythm
  after update of status on public.stages
  for each row execute function public.step_rhythm_down_on_arrival();

-- ── The 30-day watch ──────────────────────────────────────────────────────────
--
-- Who has arrived recently, and whether the calm has broken since. Three hard
-- nights inside the last seven is the trigger — one bad night is a night, and
-- two is a week; three is a pattern returning.
--
-- `since_arrival` counts only nights AFTER the goal was met, so the hard nights
-- that were part of the journey itself can never be read as a relapse.
create or replace view public.v_arrival_watch as
select s.parent_id,
       s.id                                as stage_id,
       s.child_id,
       s.objective_text,
       s.completed_at,
       (now() - s.completed_at) < interval '30 days'      as within_watch,
       count(d.*) filter (where d.night_result = 'hard'
                            and d.log_date > current_date - 7) as hard_last_7,
       count(d.*)                                              as since_arrival,
       (   (now() - s.completed_at) < interval '30 days'
       and count(d.*) filter (where d.night_result = 'hard'
                               and d.log_date > current_date - 7) >= 3) as relapse
from public.stages s
left join public.daily_logs d
       on d.follower_id = s.parent_id
      and d.night_result is not null
      and d.log_date > s.completed_at::date
where s.status = 'completed'
  and s.completed_at is not null
  -- Only the most recent arrival per parent: an older journey cannot relapse.
  and not exists (select 1 from public.stages s2
                   where s2.parent_id = s.parent_id
                     and s2.status = 'completed'
                     and s2.completed_at > s.completed_at)
group by s.parent_id, s.id, s.child_id, s.objective_text, s.completed_at;

comment on view public.v_arrival_watch is
  'The 30 days after a goal is reached. `relapse` is true when three of the last '
  'seven nights were hard — one is a night, two is a week, three is a pattern '
  'returning. Counts only nights after the arrival, so the journey''s own hard '
  'nights can never read as a relapse.';

-- ── The three bodies ──────────────────────────────────────────────────────────
--
-- One function, because all three read the same evidence and differ only in what
-- they do with it. Composed rather than stored, because every one of them names
-- the child, the goal and the step that actually worked — a fixed body could
-- carry none of that, and without it the relapse message is just sympathy.
create or replace function public.arrival_message(p_parent_id uuid, p_kind text)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_nl text := chr(10);
  v_child text; v_objective text; v_days int; v_best text; v_won int; v_of int;
  v_lines text[] := '{}';
begin
  if p_kind not in ('arrived','what_now','relapse') then
    return jsonb_build_object('ok', false, 'reason', 'unknown_kind', 'given', p_kind);
  end if;

  select w.objective_text,
         greatest(1, (current_date - w.completed_at::date))
    into v_objective, v_days
  from public.v_arrival_watch w where w.parent_id = p_parent_id;

  if v_objective is null then
    return jsonb_build_object('ok', false, 'reason', 'no_arrival');
  end if;

  select nullif(btrim(c.name),'') into v_child
  from public.children c
  where c.follower_id = p_parent_id and c.name not in ('الطفل','الطفلة')
  order by c.is_primary desc, c.created_at limit 1;

  -- The step that actually worked, and how often. This is what makes the return
  -- «لا نبدأ من الصفر» rather than a kind sentence.
  select coalesce(d.step_given, d.seed_text),
         count(*) filter (where d.step_status = 'done'), count(*)
    into v_best, v_won, v_of
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and coalesce(d.step_given, d.seed_text) is not null
  group by coalesce(d.step_given, d.seed_text)
  having count(*) filter (where d.step_status = 'done') > 0
  order by count(*) filter (where d.step_status = 'done') desc, count(*) desc
  limit 1;

  if p_kind = 'arrived' then
    v_lines := array_append(v_lines, '🌿 وصلتم.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, (v_objective || '.'));
    v_lines := array_append(v_lines, 'هذا ما اتّفقنا عليه، وهذا ما صار.');
    v_lines := array_append(v_lines, '');
    -- The credit goes back, entirely and by name.
    v_lines := array_append(v_lines, 'لم أفعل هذا أنا. أنا سألتكم كل مساء سؤالاً واحداً وكتبت الجواب.');
    v_lines := array_append(v_lines, 'أنتم من جرّب، في أصعب ساعة من يومكم،');
    v_lines := array_append(v_lines, 'وأعاد المحاولة بعد الليالي التي لم تنجح.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'الليلة لا خطوة ولا سؤال.');
    v_lines := array_append(v_lines, 'فقط أردتُ أن تعرفوا أنّ ما تعبتم فيه ظهر.');

  elsif p_kind = 'what_now' then
    v_lines := array_append(v_lines, '🌿 مرّت أيام على وصولكم، وما زالت هادئة.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'من هنا، الأمر لكم:');
    v_lines := array_append(v_lines, '');
    -- The free door first. That order is the reason the second one is believable.
    v_lines := array_append(v_lines, ('👁 نُبقي عيناً على ما وصلنا إليه — أسألكم مرّة في الأسبوع بدل كل مساء.'));
    v_lines := array_append(v_lines, '   إن رجعت الليالي الصعبة، أعرف قبل أن تصير عادة. وهذا يبقى مجانياً.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, ('🎯 أو نعمل على شيء آخر يتعبكم مع ' || coalesce(v_child,'طفلكم') || '.'));
    v_lines := array_append(v_lines, '   نتّفق على هدف، ونمشي إليه كما فعلنا تماماً.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, '🌿 أو نكتفي بهذا. تعرفون أين أجدكم، وأنا لا أختفي.');

  else
    v_lines := array_append(v_lines, '🌿 لاحظتُ أنّ الليالي رجعت صعبة هذا الأسبوع.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'هذا يحدث — الهدوء لا يمشي في خط مستقيم.');
    if v_best is not null then
      v_lines := array_append(v_lines, 'والفرق أنّنا لا نبدأ من الصفر: نعرف ما نجح معكم آخر مرّة.');
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines,
        ('«' || v_best || '» نجح ' || public.ar_digits(v_won::text)
              || ' من ' || public.ar_digits(v_of::text) || ' ليالٍ.'));
      v_lines := array_append(v_lines, 'نعيده أسبوعاً ونرى؟');
    else
      v_lines := array_append(v_lines, 'ونحن نعرف بيتكم الآن أكثر ممّا كنّا نعرفه في البداية.');
      v_lines := array_append(v_lines, 'احكوا لي ما تغيّر، ونبدأ من حيث نحن.');
    end if;
  end if;

  return jsonb_build_object(
    'ok', true, 'kind', p_kind, 'body', array_to_string(v_lines, v_nl),
    'child_name', v_child, 'days_since_arrival', v_days);
end $fn$;

comment on function public.arrival_message(uuid, text) is
  'The three bodies of ما بعد الوصول: arrived (sells nothing, takes no credit), '
  'what_now (the free door named first), relapse (free, unprompted, and specific '
  'about what worked last time). Composes only — nothing here sends.';

revoke execute on function public.arrival_message(uuid, text) from public, anon, authenticated;
grant execute on function public.arrival_message(uuid, text) to service_role;

-- The moment rows. Buttons are EMPTY on the arrival message on purpose: the
-- escape-hatch constraint is satisfied by having no buttons at all, which is
-- also the design's first prohibition — nothing in it leads to money.
insert into public.conversation_moments
  (key, tier, category, max_lines, buttons, buttons_forbidden, requires_commerce, note)
values
  ('journey_arrived', 'composed', 'review', 14, '[]'::jsonb, false, false,
   'The evening the goal is met. Sells nothing, asks nothing, and gives the credit away.'),
  ('journey_what_now', 'composed', 'goal', 16,
   jsonb_build_array(
     jsonb_build_object('cb','journey_watch_on','label','👁 أبقِ عيناً عليه'),
     jsonb_build_object('cb','menu_journey','label','🎯 هدف آخر'),
     jsonb_build_object('cb','other','label','🌿 نكتفي بهذا')),
   false, false,
   'Three days after arrival, never the same day. The free door is named first, which is why the paid one is believable.'),
  -- 'review' rather than 'rhythm': chk_line_budget caps a rhythm moment at three
  -- lines, and this one names the step and its count. The copy law refused the
  -- first draft, which is the law doing its job.
  ('journey_relapse', 'composed', 'review', 10, '[]'::jsonb, false, false,
   'Unprompted and free, inside 30 days of arrival, when three of seven nights went hard.')
on conflict (key) do update
  set category = excluded.category, max_lines = excluded.max_lines,
      buttons = excluded.buttons, note = excluded.note;

commit;
