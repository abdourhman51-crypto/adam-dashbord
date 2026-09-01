-- get_moment_after_tap()'s sc_commit branch (the "✅ سأطبّق ذلك" button reply)
-- sent generic praise on the free tier -- "كل خطوة صغيرة توخذ بجدية تصنع فرق
-- حقيقي" -- a hardcoded, non-LLM string that bypassed every voice fix made to
-- the conversational prompt today, and reads exactly like the generic
-- encouragement the brand bible forbids ("لا مديح عام"). commit_chat_step()
-- already returns the actual committed step text (v_commit->>'step') -- it
-- was simply never used in the body. Both branches (paid/free) now echo the
-- specific step itself instead of praising the parent in the abstract.
create or replace function public.get_moment_after_tap(p_key text, p_parent_id uuid, p_country_code text default null::text)
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
  v_cap jsonb;
  v_intent_result jsonb;
  v_screen jsonb;
  v_field  text;
  v_result jsonb;
  v_cs jsonb;
  v_reading_buttons jsonb;
  v_offer jsonb;
  v_review jsonb;
  v_commit jsonb;
  v_nl text := chr(10);
  v_stage jsonb;
begin
  if p_key <> 'menu_capture_country' then
    update public.followers
       set country_asked_at = null
     where id = p_parent_id and country_asked_at is not null;
  end if;

  if p_key = 'sc_commit' then
    v_commit := public.commit_chat_step(p_parent_id);
    if not coalesce((v_commit->>'committed')::boolean, false) then
      return jsonb_build_object('found', true, 'key', 'sc_commit', 'allowed', true,
        'category', 'reference', 'tier', 'fixed',
        'body', 'ما لقيت خطوة اليوم بعد — احكوا لي الموقف الأول.',
        'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
        'action_done', 'step_commit_missing');
    end if;
    return jsonb_build_object('found', true, 'key', 'sc_commit', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', case when coalesce((v_commit->>'is_paid')::boolean, false) and v_commit->>'objective_text' is not null
        then '✅ «' || (v_commit->>'step') || '» — خطوة حقيقية تقرّبكم من هدفكم: ' || (v_commit->>'objective_text') || '.'
        else '✅ «' || (v_commit->>'step') || '» — هذا ما فعلتموه اليوم، ويُبنى عليه غداً.' end,
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 3,
      'action_done', 'step_committed');
  end if;

  if p_key = 'sc_more' then
    return jsonb_build_object('found', true, 'key', 'sc_more', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', 'تمام، احكوا لي شنو يشغل بالكم أكثر — كل ما تحكون أكثر، صارت الخطوة أدق.',
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
      'action_done', 'step_more_context_requested');
  end if;

  if p_key like 'pat\_yes\_%' escape '\' then
    v_review := public.handle_pattern_review_tap(substring(p_key from 9)::uuid, true);
    return jsonb_build_object('found', true, 'key', 'pattern_review', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', v_review->>'body', 'buttons', '[]'::jsonb,
      'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'pattern_approved');
  end if;
  if p_key like 'pat\_no\_%' escape '\' then
    v_review := public.handle_pattern_review_tap(substring(p_key from 8)::uuid, false);
    return jsonb_build_object('found', true, 'key', 'pattern_review', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', v_review->>'body', 'buttons', '[]'::jsonb,
      'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'pattern_rejected');
  end if;

  if p_key in ('sdi_yes', 'sdi_no') then
    select platform_user_id into v_moment from public.followers where id = p_parent_id;
    v_intent_result := public.record_seed_intent(
      v_moment, case when p_key = 'sdi_yes' then 'will_try' else 'not_tonight' end);
    return jsonb_build_object(
      'found', true, 'key', p_key, 'allowed', true, 'category', 'rhythm',
      'tier', 'fixed',
      'body', case when p_key = 'sdi_yes' then '🌿 نتابع الليلة.' else 'تمام، نكون هنا لما يناسبكم.' end,
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
      'action_done', case when coalesce((v_intent_result->>'recorded')::boolean, false)
                           then 'intent_recorded' else 'intent_not_recorded' end);
  end if;

  if p_key = 'jf_start' then
    v_stage := public.stage_state(p_parent_id);
    if coalesce((v_stage->>'in_stage')::boolean, false) then
      return jsonb_build_object('found', true, 'key', 'jf_already_in_stage', 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', '📈 عندكم اتفاق نشط بالفعل — هدفكم: ' || coalesce(v_stage->>'objective_text','') || '.' || v_nl || v_nl
             || 'ما في داعي لاستمارة جديدة.',
        'buttons', '[{"label":"📈 أشوف تقدّمي","cb":"menu_progress"},{"label":"💬 عندي سؤال","cb":"other"}]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 6, 'action_done', 'jf_start_blocked_in_stage');
    end if;
    perform public.start_journey_form(p_parent_id);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_started');
  end if;

  if p_key = 'menu_change_goal' then
    update public.followers set agreed_objective = null, agreed_at = null where id = p_parent_id;
    perform public.start_journey_form(p_parent_id);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_restarted');
  end if;

  if p_key like 'jf_%' and p_key <> 'jf_capture_text' then
    if p_key = 'jf_other_problem' then
      perform public.await_journey_form_text(p_parent_id, 'problem_text');
      return jsonb_build_object('found', true, 'key', p_key, 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', 'احكوا لي بكلماتكم: ما الذي يتعبكم معه؟', 'buttons', '[]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'awaiting_problem_text');

    elsif p_key = 'jf_other_outcome' then
      perform public.await_journey_form_text(p_parent_id, 'outcome_text');
      return jsonb_build_object('found', true, 'key', p_key, 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', 'بكلماتكم: ماذا تحبّون أن يتغيّر؟', 'buttons', '[]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'awaiting_outcome_text');

    elsif p_key like 'jf_problem\_%' escape '\' then
      perform public.capture_journey_form_answer(p_parent_id, 'problem_key', substring(p_key from 12));

    elsif p_key like 'jf_freq\_%' escape '\' then
      perform public.capture_journey_form_answer(p_parent_id, 'frequency_key', substring(p_key from 9));

    elsif p_key like 'jf_outcome\_%' escape '\' then
      declare
        v_idx int;
        v_prob text;
        v_opts jsonb;
        v_text text;
      begin
        v_idx := substring(p_key from 12)::int;
        select journey_form_state->>'problem_key' into v_prob from public.followers where id = p_parent_id;
        v_opts := public.journey_outcome_options(v_prob);
        v_text := v_opts->>(v_idx - 1);
        perform public.capture_journey_form_answer(p_parent_id, 'outcome_text', coalesce(v_text, 'ما اخترتموه'));
      end;

    elsif p_key = 'jf_confirm_restart' then
      perform public.start_journey_form(p_parent_id);

    elsif p_key = 'jf_confirm_yes' then
      v_result := public.agree_objective_from_form(p_parent_id);
      if coalesce((v_result->>'agreed')::boolean, false) then
        if public.commerce_allowed_after_voluntary_form(p_parent_id) then
          v_offer := public.get_conversation_moment('menu_journey', p_parent_id, true);
          return v_offer || jsonb_build_object('action_done', 'goal_agreed_from_form');
        end if;
        return jsonb_build_object('found', true, 'key', 'jf_goal_saved_no_offer',
          'allowed', true, 'category', 'journey_form', 'tier', 'fixed',
          'body', 'سجّلت هدفكم: ' || coalesce(v_result->>'objective_text','') || '.' || chr(10) || chr(10)
               || 'خلّونا نكمل نتكلم شوي، ونرجع لهذا الموضوع لما يناسب الوقت أكثر.' || chr(10)
               || 'هو محفوظ عندي، ما يضيع.',
          'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 4,
          'action_done', 'goal_agreed_offer_deferred');
      end if;
      perform public.start_journey_form(p_parent_id);
    end if;

    v_screen := public.compose_journey_form_screen(p_parent_id);
    if v_screen ? 'await_field' then
      perform public.await_journey_form_text(p_parent_id, v_screen->>'await_field');
    end if;
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_advanced');
  end if;

  if p_key = 'jf_capture_text' then
    select journey_form_state->>'awaiting_free_text_for' into v_field
    from public.followers where id = p_parent_id;
    if v_field is null then
      v_field := 'problem_text';
    end if;
    perform public.capture_journey_form_answer(p_parent_id, v_field, p_country_code);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    if v_screen ? 'await_field' then
      perform public.await_journey_form_text(p_parent_id, v_screen->>'await_field');
    end if;
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_text_captured');
  end if;

  if p_key = 'menu_capture_country' then
    v_cap := public.capture_country_text(p_parent_id, p_country_code);
    if (v_cap->>'captured')::boolean then
      if (v_cap->>'joined')::boolean then
        v_moment := 'menu_waitlist_joined'; v_done := 'waitlisted';
      else
        v_moment := 'country_recorded'; v_done := 'country_recorded';
      end if;
    else
      v_moment := 'country_not_recognised'; v_done := 'country_unrecognised';
    end if;
    return coalesce(public.get_conversation_moment(v_moment, p_parent_id), '{}'::jsonb)
        || jsonb_build_object('action_done', v_done)
        || jsonb_build_object('captured', coalesce((v_cap->>'captured')::boolean, false));
  end if;

  if nullif(btrim(coalesce(p_country_code,'')), '') is not null then
    v_rec := public.record_country(p_parent_id, p_country_code);
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
    v_reading_buttons := case when v_reading->>'state' in ('locked','locked_preview')
      then jsonb_build_array(jsonb_build_object('label','🎯 أشوف المرافقة الكاملة','cb','menu_journey'))
      else '[]'::jsonb end;
    return coalesce(public.get_conversation_moment('menu_reading', p_parent_id), '{}'::jsonb)
        || jsonb_build_object('body', v_reading->>'body')
        || jsonb_build_object('buttons', v_reading_buttons)
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
