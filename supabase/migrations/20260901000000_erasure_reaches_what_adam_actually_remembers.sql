-- المحو كان يمسح النص الخام (المحادثة) فقط، بينما "ما يتذكّره آدم" فعلياً
-- يعيش في معرفة مُشتقّة منفصلة كتبها W2 من نفس تلك المحادثة: light_memory
-- على followers (الحقل الذي أعاد فعلاً جملة "بكاء يوسف... إبعاد اللعبة
-- واحتضانه" حرفياً لوالد طلب المحو قبل دقائق)، والأنماط والمواقف واللحظات
-- المكتشَفة. حذف المحادثة الخام بلا حذف هذا كان يعني وعداً منكسراً: آدم يبدو
-- وكأنه لم يمحُ شيئاً، رغم أن سجل المحادثة نفسه مُحي فعلاً.
--
-- ما يبقى عمداً غير مُمحو: daily_logs (تقدّم الوالد المسجَّل بنفسه — الشجرة
-- والسلسلة المتتالية، لا شيء أفصح به لآدم)، children (هوية أساسية تلزم
-- لاستمرار الخدمة)، stages/الرحلة المدفوعة (اتفاق فعلي قائم)، وسجلات الأمان
-- التشغيلية (crisis_flags، incidents، reply_gate_log) التي ليست ملكاً
-- للوالد وحده لتقرير محوها.

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
  v_knowledge_deleted int := 0;
  v_tmp int;
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

  -- المعرفة المُشتقّة من نفس المحادثة — هذا هو "الذي يتذكّره آدم" فعلياً
  update public.followers
  set light_memory = null, light_memory_updated_at = null
  where id = p_parent_id and light_memory is not null;
  get diagnostics v_tmp = row_count;
  v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.situations where parent_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.child_patterns where follower_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.aha_moments where parent_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.memory_events where follower_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.memory_snapshots where follower_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.parent_strain where parent_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.mirrors where parent_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  delete from public.stage_proposals where parent_id = p_parent_id;
  get diagnostics v_tmp = row_count; v_knowledge_deleted := v_knowledge_deleted + v_tmp;

  -- الدفعة نفسها سجل محاسبي يبقى، لكن أي ملاحظة نصية شخصية فيها تُمحى.
  update public.payments
  set notes = null
  where follower_id = p_parent_id and notes is not null;
  get diagnostics v_payments_anonymised = row_count;

  v_notes := format('chat=%s surveys=%s knowledge=%s payments_anonymised=%s',
                     v_chat_deleted, v_surveys_deleted, v_knowledge_deleted, v_payments_anonymised);

  insert into public.erasure_requests (parent_id, platform_user_id, status, completed_at, notes)
  values (p_parent_id, v_platform_user_id, 'completed', now(), v_notes);

  return jsonb_build_object(
    'erased', true,
    'chat_deleted', v_chat_deleted,
    'surveys_deleted', v_surveys_deleted,
    'knowledge_deleted', v_knowledge_deleted,
    'payments_anonymised', v_payments_anonymised
  );
end;
$$;
