-- الإعدادات والخصوصية تصير أفعالاً حقيقية، لا وعوداً بالمحادثة
--
-- set_checkin_hour(uuid, smallint) موجودة أصلاً وتُستدعى من محادثة البوت —
-- لا نكرّرها. الجديد هنا فقط: قراءة الحالة الحالية (لعرضها في التطبيق
-- المصغّر)، إيقاف/تشغيل الرسالة اليومية (لا دالة كانت موجودة لهذا)، ومحو
-- البيانات — الثلاثة تُستدعى مباشرة من التطبيق المصغّر عبر RPC، بنفس نمط كل
-- كتابة أخرى في هذا المشروع (commit_chat_step، record_harvest_answer).
--
-- محو البيانات يطابق حرفياً الشكل الذي أُنجز به آخر ١٣ طلب محو حقيقي في
-- erasure_requests (notes بصيغة "chat=N surveys=N payments_anonymised=N")
-- — لا نخترع نطاقاً جديداً، بل نجعل النطاق نفسه تلقائياً بدل يدوي.

create or replace function public.get_checkin_settings(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  v_hour smallint;
  v_cadence text;
begin
  select cs.local_hour, cs.cadence into v_hour, v_cadence
  from public.checkin_state cs where cs.parent_id = p_parent_id;

  return jsonb_build_object(
    'local_hour', coalesce(v_hour, 21),
    'paused', coalesce(v_cadence, 'nightly') = 'stopped'
  );
end;
$$;

create or replace function public.set_checkin_paused(p_parent_id uuid, p_paused boolean)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_cadence text := case when p_paused then 'stopped' else 'nightly' end;
begin
  insert into public.checkin_state (parent_id, cadence, paused_until)
  values (p_parent_id, v_cadence, null)
  on conflict (parent_id) do update
    set cadence = v_cadence,
        paused_until = null,
        cadence_changed_at = now(),
        updated_at = now();

  return jsonb_build_object('updated', true, 'paused', p_paused);
end;
$$;

create or replace function public.request_data_erasure(p_parent_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_platform_user_id text;
  v_chat_deleted int := 0;
  v_surveys_deleted int := 0;
  v_payments_anonymised int := 0;
  v_notes text;
begin
  select f.platform_user_id into v_platform_user_id
  from public.followers f where f.id = p_parent_id;

  if v_platform_user_id is null then
    return jsonb_build_object('erased', false, 'reason', 'not_found');
  end if;

  -- محادثة اللانج تشين الخام — "كل ما قلته" حرفياً. أحياناً يُخزَّن مفتاح
  -- الجلسة بخطأ تعبير n8n فيسبقه "=" حرفياً؛ نمحو الشكلين معاً.
  delete from public.n8n_chat_histories
  where session_id in (v_platform_user_id, '=' || v_platform_user_id);
  get diagnostics v_chat_deleted = row_count;

  delete from public.survey_responses
  where platform_user_id = v_platform_user_id;
  get diagnostics v_surveys_deleted = row_count;

  -- الدفعة نفسها سجل محاسبي يبقى، لكن أي ملاحظة نصية شخصية فيها تُمحى.
  update public.payments
  set notes = null
  where follower_id = p_parent_id and notes is not null;
  get diagnostics v_payments_anonymised = row_count;

  v_notes := format('chat=%s surveys=%s payments_anonymised=%s',
                     v_chat_deleted, v_surveys_deleted, v_payments_anonymised);

  insert into public.erasure_requests (parent_id, platform_user_id, status, completed_at, notes)
  values (p_parent_id, v_platform_user_id, 'completed', now(), v_notes);

  return jsonb_build_object(
    'erased', true,
    'chat_deleted', v_chat_deleted,
    'surveys_deleted', v_surveys_deleted,
    'payments_anonymised', v_payments_anonymised
  );
end;
$$;
