-- «بلد آخر» — the branch that was never built
--
-- The country buttons offer three markets and «🌍 بلد آخر». Tapping the fourth
-- reached nothing: the Router turned it into a key with no country attached, and
-- the waitlist built this morning could never fill, because the one path that
-- leads to it had no floor.
--
-- Founder's flow, and his refinement is better than my design:
--
--   🌍 بلد آخر
--     → «آدم غير متاح في بلدكم بعد» — and WHY, plainly
--     → two buttons: سجّلوني / ليس الآن
--   سجّلوني
--     → «من أيّ بلد أنتم؟» — and they TYPE it
--     → we catch what they typed, record it, and they are on the list
--
-- Free text rather than more buttons, because there are twenty-two countries in
-- the Arabic-speaking world and a keyboard of them is not a keyboard. Buttons for
-- the three we sell in; typing for everyone else.
--
-- ── The two things that make free text safe ───────────────────────────────────
--
-- A typed answer is only read inside a window after ADAM asked, exactly as
-- capture_intention works. Without that, «مصر» in the middle of a sentence about
-- a holiday would silently change where a parent lives.
--
-- And an unrecognised answer is never guessed at. It says so and asks once more.
-- Recording the wrong country is worse than recording none: it puts a family in
-- a market they cannot buy in, and it corrupts the one number the waitlist exists
-- to produce.

begin;

-- ── Names people actually type ────────────────────────────────────────────────
--
-- country_timezone carries name_ar for some countries and not others, and nobody
-- types «الجمهورية الجزائرية». This is the spoken form, plus the variants a tired
-- parent types at midnight.
-- No FK to country_timezone: the seed below is deliberately generous and a code
-- may be absent, and a mid-INSERT FK check would abort the whole seed. The
-- cleanup after the insert is the integrity guarantee instead — it removes any
-- alias whose country we cannot put on a clock.
create table if not exists public.country_aliases (
  alias   text primary key,
  code    text not null
);

comment on table public.country_aliases is
  'What parents type when asked where they are. Matched after normalising: the '
  'definite article, tatweel, diacritics and the alef/hamza family all removed.';

-- Normalised the same way on both sides, so «الجزاير» and «الجزائر» are one.
create or replace function public.normalise_place(p_text text)
returns text
language sql
immutable
set search_path to 'pg_catalog', 'public'
as $fn$
  select nullif(btrim(
    regexp_replace(
      translate(
        regexp_replace(lower(btrim(coalesce(p_text,''))), '[ًٌٍَُِّْـ]', '', 'g'),
        'أإآٱىة', 'اااايه'),
      '^(ال|فى |في |من )', '', 'g')
  ), '');
$fn$;

insert into public.country_aliases (alias, code) values
  ('الجزائر','DZ'), ('الجزاير','DZ'), ('دزاير','DZ'), ('algeria','DZ'),
  ('مصر','EG'), ('مصرية','EG'), ('egypt','EG'),
  ('المغرب','MA'), ('مغرب','MA'), ('morocco','MA'),
  ('تونس','TN'), ('tunisia','TN'),
  ('ليبيا','LY'), ('libya','LY'),
  ('موريتانيا','MR'),
  ('السعودية','SA'), ('السعوديه','SA'), ('سعودية','SA'), ('saudi','SA'),
  ('الامارات','AE'), ('امارات','AE'), ('دبي','AE'), ('uae','AE'),
  ('قطر','QA'), ('qatar','QA'),
  ('الكويت','KW'), ('kuwait','KW'),
  ('البحرين','BH'), ('bahrain','BH'),
  ('عمان','OM'), ('سلطنة عمان','OM'), ('oman','OM'),
  ('اليمن','YE'), ('yemen','YE'),
  ('الاردن','JO'), ('اردن','JO'), ('jordan','JO'),
  ('سوريا','SY'), ('سورية','SY'), ('syria','SY'),
  ('لبنان','LB'), ('lebanon','LB'),
  ('فلسطين','PS'), ('غزة','PS'), ('palestine','PS'),
  ('العراق','IQ'), ('عراق','IQ'), ('iraq','IQ'),
  ('السودان','SD'), ('sudan','SD'),
  ('الصومال','SO'), ('somalia','SO'),
  ('جيبوتي','DJ'),
  ('تركيا','TR'), ('turkey','TR'),
  ('فرنسا','FR'), ('france','FR'),
  ('كندا','CA'), ('canada','CA'),
  ('المانيا','DE'), ('germany','DE'),
  ('بريطانيا','GB'), ('انجلترا','GB'), ('uk','GB'),
  ('امريكا','US'), ('الولايات المتحدة','US'), ('usa','US'),
  ('اسبانيا','ES'), ('spain','ES'),
  ('ايطاليا','IT'), ('italy','IT'),
  ('بلجيكا','BE'), ('السويد','SE'), ('هولندا','NL')
on conflict (alias) do nothing;

-- Only keep aliases whose country we can actually put on a clock. The FK does
-- this, but seeding above is deliberately generous and some codes may be absent.
delete from public.country_aliases a
 where not exists (select 1 from public.country_timezone ct where ct.code = a.code);

-- ── Catching what they typed ──────────────────────────────────────────────────

create or replace function public.capture_country_text(p_parent_id uuid, p_text text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_asked timestamptz;
  v_norm  text;
  v_code  text;
  v_state jsonb;
begin
  select f.country_asked_at into v_asked
  from public.followers f where f.id = p_parent_id;
  if not found then
    return jsonb_build_object('captured', false, 'reason', 'no_such_parent');
  end if;

  -- Only inside the window after ADAM asked. Otherwise «كنا في مصر الصيف الماضي»
  -- would quietly move a family to Egypt.
  if v_asked is null or v_asked < now() - interval '36 hours' then
    return jsonb_build_object('captured', false, 'reason', 'not_awaiting');
  end if;

  v_norm := public.normalise_place(p_text);
  if v_norm is null or length(v_norm) > 60 then
    return jsonb_build_object('captured', false, 'reason', 'not_a_place');
  end if;

  -- A whole-word match ANYWHERE in the answer, so «انا من تونس» finds تونس while
  -- «تونسي الأصل نعيش في فرنسا» still resolves to the country they NAMED. Longest
  -- alias first, so «سلطنة عمان» is preferred over «عمان» and «الولايات المتحدة»
  -- over any fragment. The regexp guards word boundaries: «مصرية» does not match
  -- inside «مصريطاليا», and a two-letter code never matches inside a word.
  select a.code into v_code
  from (select code, public.normalise_place(alias) as na from public.country_aliases) a
  where v_norm ~ ('(^|\s)' || a.na || '($|\s)')
  order by length(a.na) desc
  limit 1;

  -- Fall back to the stored name, so a country nobody wrote an alias for still
  -- resolves if the parent typed exactly it.
  if v_code is null then
    select ct.code into v_code from public.country_timezone ct
    where public.normalise_place(ct.name_ar) is not null
      and v_norm ~ ('(^|\s)' || public.normalise_place(ct.name_ar) || '($|\s)')
    order by length(public.normalise_place(ct.name_ar)) desc
    limit 1;
  end if;

  -- And a bare ISO code typed on its own — «SA», «eg». Only as the whole answer,
  -- so a two-letter fragment inside a word is never mistaken for a country.
  if v_code is null and length(v_norm) = 2 then
    select ct.code into v_code from public.country_timezone ct
    where lower(ct.code) = v_norm limit 1;
  end if;

  -- Never guessed. A wrong country is worse than no country: it puts a family in
  -- a market they cannot buy in and corrupts the demand it was meant to measure.
  if v_code is null then
    return jsonb_build_object('captured', false, 'reason', 'unrecognised', 'given', btrim(p_text));
  end if;

  v_state := public.record_country(p_parent_id, v_code);
  if (v_state->>'ok')::boolean is not true then
    return jsonb_build_object('captured', false, 'reason', 'record_failed') || coalesce(v_state,'{}'::jsonb);
  end if;

  -- The ask is spent, so a later message cannot be read as another answer.
  update public.followers set country_asked_at = null where id = p_parent_id;

  return jsonb_build_object('captured', true, 'code', v_code)
      || coalesce(public.join_waitlist(p_parent_id), '{}'::jsonb);
end $fn$;

comment on function public.capture_country_text(uuid, text) is
  'Reads a country a parent TYPED, only inside 36 hours of ADAM asking, and never '
  'guesses an unrecognised one. On success it records the country and, if the '
  'market is not open, puts them on the waitlist in the same call.';

revoke execute on function public.capture_country_text(uuid, text) from public, anon, authenticated;
grant execute on function public.capture_country_text(uuid, text) to service_role;

-- ── The three moments of the branch ───────────────────────────────────────────

insert into public.conversation_moments
  (key, tier, category, max_lines, body_ar, buttons, buttons_forbidden, requires_commerce, note)
values
  ('country_other', 'fixed', 'reference', 14,
   '🌍 آدم ليس متاحاً في بلدكم بعد.' || chr(10) || chr(10) ||
   'والسبب صريح: المرافقة الكاملة تحتاج طريقة دفع يستطيع أهل البلد استعمالها فعلاً،' || chr(10) ||
   'لا تحويلاً معقّداً ولا بطاقة لا يملكها أكثر الناس. ونحن نفتح بلداً حين نجد تلك الطريقة، لا قبلها.' || chr(10) || chr(10) ||
   'وهذا لا يغيّر شيئاً ممّا بيننا الآن:' || chr(10) ||
   'احكوا لي ما حدث، وأعطيكم خطوة صغيرة، وأسألكم مساءً كيف مرّت. مجاناً، ويبقى كذلك.' || chr(10) || chr(10) ||
   'وإن أردتم، أُسجّلكم فأُخبركم حين يصل آدم إليكم.',
   jsonb_build_array(
     jsonb_build_object('cb','menu_waitlist_join','label','🔔 سجّلوني، أخبروني حين يصل'),
     jsonb_build_object('cb','other','label','🌿 ليس الآن، نكمل')),
   false, false,
   'The «بلد آخر» tap. Says why, not just no — the honesty is what makes the free tier read as complete rather than as a consolation.'),
  ('country_not_recognised', 'fixed', 'reference', 8,
   '🌍 لم أعرف هذا البلد.' || chr(10) || chr(10) ||
   'اكتبوه لي باسمه المعروف — «تونس»، «الأردن»، «السعودية» — وأنا أسجّله.' || chr(10) ||
   'أفضّل أن أسأل مرّة أخرى على أن أسجّل بلداً خاطئاً.',
   jsonb_build_array(jsonb_build_object('cb','other','label','↩︎ دعونا من هذا')),
   false, false,
   'An unrecognised country is asked again, never guessed. Recording the wrong one puts a family in a market they cannot buy in.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      category = excluded.category, max_lines = excluded.max_lines, note = excluded.note;

commit;

-- ── Wiring the branch into the tap router ─────────────────────────────────────
--
-- «بلد آخر» is handled HERE rather than in the Router, and that is deliberate.
-- Whatever callback that button carries — set_country_OTHER, set_country_XX, a
-- code we have never seen — record_country refuses it, and a refusal is exactly
-- the signal «this parent is not in a market we know». One branch covers every
-- spelling of the fourth button, and no workflow edit is needed to add a country.
--
-- And the needs_country branch now stamps country_asked_at, which is what opens
-- the 36-hour window capture_country_text reads inside. Without the stamp the
-- parent types their country into silence.

begin;

create or replace function public.get_moment_after_tap(
  p_key text, p_parent_id uuid, p_country_code text default null::text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_rec  jsonb;
  v_req  uuid;
  v_done text := null;
  v_moment text := p_key;
  v_reading jsonb;
  v_join jsonb;
begin
  if nullif(btrim(coalesce(p_country_code,'')), '') is not null then
    v_rec := public.record_country(p_parent_id, p_country_code);

    -- A code we cannot place IS the «بلد آخر» answer, however it was spelled.
    if coalesce((v_rec->>'ok')::boolean, false) is not true then
      v_done   := 'country_unknown';
      v_moment := 'country_other';
    end if;
  end if;

  if p_parent_id is not null and v_moment = p_key then
    if p_key = 'menu_settings_paused' then
      insert into public.checkin_state (parent_id, cadence, cadence_changed_at)
      values (p_parent_id, 'stopped', now())
      on conflict (parent_id) do update
        set cadence = 'stopped', cadence_changed_at = now(), updated_at = now();
      v_done := 'paused';

    elsif p_key = 'menu_settings_resumed' then
      insert into public.checkin_state (parent_id, cadence, paused_until, cadence_changed_at)
      values (p_parent_id, 'nightly', null, now())
      on conflict (parent_id) do update
        set cadence = 'nightly', paused_until = null,
            cadence_changed_at = now(), updated_at = now();
      v_done := 'resumed';

    elsif p_key in ('menu_settings_hour_morning','menu_settings_hour_evening','menu_settings_hour_night') then
      perform public.set_checkin_hour(p_parent_id, case p_key
                when 'menu_settings_hour_morning' then 8::smallint
                when 'menu_settings_hour_evening' then 17::smallint
                else                                   21::smallint end);
      v_done   := 'hour_set';
      v_moment := 'menu_settings_hour_set';

    elsif p_key = 'menu_privacy_erased' then
      v_req := public.request_erasure(p_parent_id);
      if v_req is not null then
        perform public.execute_erasure(v_req);
        v_done := 'erased';
      end if;

    elsif p_key = 'menu_waitlist_join' then
      v_join := public.join_waitlist(p_parent_id);
      if (v_join->>'joined')::boolean then
        v_done   := 'waitlisted';
        v_moment := 'menu_waitlist_joined';
      elsif v_join->>'reason' = 'needs_country' then
        -- Open the window they will type into. Without this stamp,
        -- capture_country_text refuses their answer as not_awaiting.
        update public.followers set country_asked_at = now() where id = p_parent_id;
        v_done   := 'waitlist_needs_country';
        v_moment := 'menu_waitlist_ask_country';
      else
        v_done   := 'waitlist_not_needed';
        v_moment := 'menu_journey';
      end if;
    end if;
  end if;

  if p_key = 'menu_reading' then
    v_reading := public.adam_reading(p_parent_id);
    return coalesce(public.get_conversation_moment('menu_reading', p_parent_id), '{}'::jsonb)
        || jsonb_build_object('body', v_reading->>'body')
        || jsonb_build_object('reading_state', v_reading->>'state')
        || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
        || jsonb_build_object('action_done', 'null'::jsonb);
  end if;

  return public.get_conversation_moment(
           v_moment,
           case when v_done = 'erased' then null else p_parent_id end)
       || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
       || jsonb_build_object('action_done', coalesce(to_jsonb(v_done), 'null'::jsonb));
end;
$function$;

commit;
