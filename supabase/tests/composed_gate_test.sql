\set ON_ERROR_STOP on
begin;
create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

do $$
declare p uuid; c uuid; g jsonb; ctx jsonb; i int;
begin
  insert into public.followers (platform_user_id, country) values ('hg-1','DZ') returning id into p;
  insert into public.children (follower_id, name, is_primary) values (p,'يوسف',true) returning id into c;
  insert into public.situations (child_id,key,status,evidence_count) values (c,'sleep','confirmed',4);
  for i in 1..5 loop
    insert into public.daily_logs (follower_id, log_date, night_result, step_status, step_given)
    values (p, current_date - i, case when i<=3 then 'calm' else 'hard' end, 'done', 'تنبيه قبل الانتقال');
  end loop;
  insert into public.daily_logs (follower_id, log_date, seed_text, step_given)
  values (p, current_date, 'تجربة اليوم', 'تنبيه قبل الانتقال');

  -- ---- the gate ----
  g := public.gate_composed_reply(p, 'harvest_reply_ok',
        E'التنبيه قبل الانتقال نفع مع يوسف الليلة.\nنبني عليه غداً.');
  perform pg_temp.chk('a grounded, clean, short reply passes', (g->>'ok')::boolean, g->>'reasons');

  g := public.gate_composed_reply(p, 'harvest_reply_ok', E'أحسنت.\nإلى الغد.');
  perform pg_temp.chk('a warm but generic reply is refused',
    not (g->>'ok')::boolean and g->'reasons' @> '["uniqueness:generic"]'::jsonb, g->>'reasons');

  g := public.gate_composed_reply(p, 'harvest_reply_ok', E'يوسف بخير الليلة.\nإلى الغد.');
  perform pg_temp.chk('name-only is refused — R2 caught at the gate',
    not (g->>'ok')::boolean and g->'reasons' @> '["uniqueness:identity_only"]'::jsonb, g->>'reasons');

  g := public.gate_composed_reply(p, 'harvest_reply_ok',
        E'التنبيه قبل الانتقال نفع.\nيمكن تجديد الاشتراك بـ 2300 دينار.');
  perform pg_temp.chk('banned vocabulary and a price are refused even when grounded',
    not (g->>'ok')::boolean and g->'reasons' @> '["vocabulary"]'::jsonb, g->>'reasons');

  g := public.gate_composed_reply(p, 'harvest_reply_ok',
        E'التنبيه قبل الانتقال نفع.\nسطر\nسطر\nسطر');
  perform pg_temp.chk('over the two-line budget is refused',
    not (g->>'ok')::boolean and g->'reasons' @> '["too_long"]'::jsonb, g->>'reasons');

  g := public.gate_composed_reply(p, 'harvest_reply_ok', E'أحسنت 2300 دينار.\nسطر\nسطر\nسطر');
  perform pg_temp.chk('every failure is reported, not the first',
    jsonb_array_length(g->'reasons') >= 2, g->>'reasons');

  g := public.gate_composed_reply(p, 'rescue', 'الرفض عند النوم غالباً ليس عناداً.');
  perform pg_temp.chk('the rescue is exempt from uniqueness — it may be generic',
    (g->>'ok')::boolean, g->>'reasons');

  -- ---- the context ----
  ctx := public.get_harvest_context(p, 'ok');
  perform pg_temp.chk('context carries the child and the situation',
    ctx->>'child_name' = 'يوسف' and ctx->>'situation' = 'عند النوم');
  perform pg_temp.chk('context carries this week and last week',
    (ctx->>'calm_this_week')::int = 3 and (ctx->>'nights_logged_this_week')::int = 5,
    ctx->>'calm_this_week' || ' calm / ' || (ctx->>'nights_logged_this_week') || ' logged');
  perform pg_temp.chk('context names what the reply must mention one of',
    jsonb_array_length(ctx->'must_mention_one_of') > 0, ctx->>'must_mention_one_of');
  perform pg_temp.chk('context picks the matching fallback',
    ctx->>'fallback_key' = 'harvest_reply_ok'
    and public.get_harvest_context(p,'skip')->>'fallback_key' = 'harvest_reply_skip');

  -- ---- the stored fallbacks must themselves survive the gate's vocabulary check ----
  perform pg_temp.chk('every stored harvest fallback is still sendable',
    (select bool_and(cardinality(public.copy_violations(body_ar)) = 0)
       from public.conversation_moments where key like 'harvest_reply_%'));

  -- ---- a family with nothing measured yet falls back, correctly ----
  declare p2 uuid;
  begin
    insert into public.followers (platform_user_id, country) values ('hg-2','EG') returning id into p2;
    insert into public.children (follower_id, name, is_primary) values (p2,'سارة',true);
    g := public.gate_composed_reply(p2, 'harvest_reply_ok', E'سارة نامت بهدوء.\nإلى الغد.');
    perform pg_temp.chk('night one has nothing measured, so it falls back rather than faking',
      not (g->>'ok')::boolean, g->>'reasons');
  end;

  -- ---- get_harvest_context now also decides and stamps the intention ask ----
  declare p3 uuid; s3 uuid; ctx3 jsonb;
  begin
    insert into public.followers (platform_user_id, country) values ('hg-3','MA') returning id into p3;
    insert into public.children (follower_id, name, is_primary) values (p3,'ريان',true) returning id into c;
    s3 := c;
    insert into public.situations (child_id,key,status,evidence_count) values (s3,'sleep','confirmed',4);

    ctx3 := public.get_harvest_context(p3, 'ok');
    perform pg_temp.chk('no ask before anything has worked — night one is not the moment',
      (ctx3->>'ask_intention')::boolean is not true, ctx3->>'ask_intention');

    insert into public.daily_logs (follower_id, log_date, night_result, situation_id)
    values (p3, current_date - 1, 'calm', s3);

    ctx3 := public.get_harvest_context(p3, 'failed');
    perform pg_temp.chk('a bad night never carries the ask, even once something has worked',
      (ctx3->>'ask_intention')::boolean is not true, ctx3->>'ask_intention');
    perform pg_temp.chk('and it does not spend the stamp either',
      public.should_ask_intention(p3));

    ctx3 := public.get_harvest_context(p3, 'ok');
    perform pg_temp.chk('a positive answer after a calm night carries the ask',
      (ctx3->>'ask_intention')::boolean, ctx3->>'ask_intention');
    perform pg_temp.chk('and it carries the fixed intention_ask body, not composed language',
      ctx3->>'intention_ask_body' = (select body_ar from public.conversation_moments where key='intention_ask'));

    perform pg_temp.chk('the stamp lands in the same call that hands the question back',
      not public.should_ask_intention(p3));

    ctx3 := public.get_harvest_context(p3, 'ok');
    perform pg_temp.chk('asked once, ever — a second positive night never asks again',
      (ctx3->>'ask_intention')::boolean is not true, ctx3->>'ask_intention');
    perform pg_temp.chk('and no answer is fabricated on the parent''s behalf',
      (select intention_text from public.followers where id = p3) is null);
  end;
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 58)
    || coalesce('  -> ' || left(detail, 52), '') from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed' from pg_temp.r;
rollback;
