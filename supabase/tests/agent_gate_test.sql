\set ON_ERROR_STOP on
begin;

-- ============================================================
-- THE CONVERSATIONAL REPLY, UNDER LAW.
--
-- The gate has exactly two jobs and one of them is restraint:
--
--   block what can never be right — a price, a sales verb, an
--   internal term;
--   let through a real answer that happens to contain an
--   ordinary Arabic word we would rather it did not.
--
-- The second job is the hard one. Every test below that asserts
-- a message PASSES is protecting a tired parent from losing a
-- good answer to a word list.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.parent() returns uuid
language plpgsql as $$
declare v uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into v;
  return v;
end $$;

\echo '=== WHAT CAN NEVER BE RIGHT IS BLOCKED ==='
do $$
declare p uuid; g jsonb;
begin
  p := pg_temp.parent();

  g := public.gate_agent_reply(p, 'الرحلة الواحدة عندكم 2300 دينار جزائري.');
  perform pg_temp.chk('a price never reaches a parent from ADAM (P17)',
    (g->>'blocked')::boolean, g::text);

  g := public.gate_agent_reply(p, 'اشترك في الباقة الكاملة اليوم.');
  perform pg_temp.chk('ADAM never sells (§3.7)',
    (g->>'blocked')::boolean, g::text);

  g := public.gate_agent_reply(p, 'سجّلت هذا في الـ journey الخاص بطفلكم.');
  perform pg_temp.chk('an internal term never leaks (§2.8)',
    (g->>'blocked')::boolean, g::text);

  g := public.gate_agent_reply(p, '   ');
  perform pg_temp.chk('an empty reply is caught here, not by Telegram',
    (g->>'blocked')::boolean and (g->>'fallback_key') = 'rescue', g::text);
end $$;

\echo '=== AND THE FALLBACK DOES NOT BLAME THE PARENT ==='
do $$
declare p uuid; g jsonb; b text;
begin
  p := pg_temp.parent();
  g := public.gate_agent_reply(p, 'ادفعوا 500 دينار وسأساعدكم.');

  perform pg_temp.chk('a blocked reply falls back to reply_withheld, NOT the rescue',
    (g->>'fallback_key') = 'reply_withheld', g->>'fallback_key');

  b := (select body_ar from public.conversation_moments where key = 'reply_withheld');
  -- The rescue says «لم أفهم هذه تماماً». Here that would be false: the model
  -- understood and then said something forbidden. Saying it anyway moves our
  -- fault onto the parent, which is the exact inversion of P11.
  perform pg_temp.chk('it never claims ADAM failed to understand',
    b not like '%لم أفهم%', b);
  perform pg_temp.chk('it never explains itself (P24)',
    b !~ '(قاعدة|ممنوع|لا يُسمح|النظام|السياسة)', b);
  perform pg_temp.chk('it never apologises into a paragraph',
    public.content_line_count(b) <= 2, b);
  perform pg_temp.chk('and the one obvious action is still there (L1)',
    b like '%احكوا لي%', b);
  perform pg_temp.chk('the withheld reply is itself legal copy',
    cardinality(public.copy_violations(b)) = 0,
    array_to_string(public.copy_violations(b), ', '));
  perform pg_temp.chk('and it does not address a mother',
    b !~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)', b);
end $$;

\echo '=== A REAL ANSWER IS NEVER LOST TO A WORD LIST ==='
do $$
declare p uuid; g jsonb; t text; blocked text[] := '{}';
begin
  p := pg_temp.parent();

  -- These are the shapes of reply ADAM actually sends. Every one must pass.
  foreach t in array array[
    'الصراخ المستمر يعني أن الجلسة أطول من قدرته على الاحتمال الآن.',
    'غداً: ضبط المؤقّت على خمس دقائق فقط للواجب، ثم التوقّف التام للراحة.',
    'تُعرف أنها نفعت إذا مرّت الدقائق الخمس دون غضب.',
    'إدخال طفل جديد للبيت مسؤولية كبيرة، وغالباً ما يجلب تحديات جديدة.',
    'خطوة واحدة الليلة: أطفئوا الضوء الكبير قبل النوم بعشر دقائق.',
    'نفعله معاً، خطوة بخطوة، وليس دفعة واحدة.',
    'الراحة وهدوء البال الليلة هما الأولوية.',
    'ما وصفتموه ليس عناداً — هو تعب في وقت متأخر من اليوم.']
  loop
    g := public.gate_agent_reply(p, t);
    if (g->>'blocked')::boolean then blocked := blocked || t; end if;
  end loop;

  perform pg_temp.chk('every shape of real answer passes',
    cardinality(blocked) = 0, left(array_to_string(blocked, ' | '), 110));

  -- The overreach cases the conversation law already protects, re-asserted
  -- here because this gate is on a far hotter path than that one.
  g := public.gate_agent_reply(p, 'خطوة صغيرة، ونفعله معاً.');
  perform pg_temp.chk('«خطوة» survives the ban on «خطة», and «نفعله» the ban on «فعّل»',
    not (g->>'blocked')::boolean, g::text);

  g := public.gate_agent_reply(p, 'جرّبوا عشرين دقيقة من اللعب الهادئ.');
  perform pg_temp.chk('a two-digit number is not a price',
    not (g->>'blocked')::boolean, g::text);
end $$;

\echo '=== THE FALSE POSITIVES THAT REPLAY CAUGHT ==='
do $$
declare p uuid; g jsonb; t text; blocked text[] := '{}';
begin
  p := pg_temp.parent();

  -- Every one of these is a REAL reply ADAM sent to a real parent, and every
  -- one of them was blocked by the first draft of this gate. They are the
  -- reason the blocking rules are not a filter over copy_violations().
  foreach t in array array[
    -- «احتواء»: internal jargon here, ordinary Arabic for holding a child. 33 hits.
    'احتواء طفلكم في هذه اللحظة أهم من تصحيحه.',
    -- «افتح»: the ban targets "open the package", not open arms.
    'اجلسوا على الرمل وافتحوا أذرعكم بصمت لتكونوا الملجأ الآمن.',
    -- A father describing pocket money. ADAM is not quoting a price.
    'إلحاحه على الـ 50 ريالاً هو رغبته في الحفاظ على صورته أمام زملائه.',
    -- «محرّك» as a metaphor for a child who needs to move.
    'تتعاملون معها كمحرّك يحتاج للعمل كي لا يضطرب.',
    -- The sanctioned AD-1 behaviour: point at فريق آدم without posing as them.
    'كل تفاصيل وأسعار الاشتراك تتوفر عند فريق آدم عبر هذا الرابط: https://t.me/Abdouleg']
  loop
    g := public.gate_agent_reply(p, t);
    if (g->>'blocked')::boolean then blocked := blocked || t; end if;
  end loop;

  perform pg_temp.chk('a real answer is never lost to a blunt word list',
    cardinality(blocked) = 0, left(array_to_string(blocked, ' | '), 110));
end $$;

\echo '=== AND THE SELLING IT WAS BUILT TO STOP ==='
do $$
declare p uuid; g jsonb; t text; passed text[] := '{}';
begin
  p := pg_temp.parent();

  -- Also real. Every one of these reached a real parent.
  foreach t in array array[
    '150 جنيه مصري - هذا المبلغ الكامل لشهر كامل من المرافقة.',
    'السعر الحالي هو 2,300 دج فقط للـ 30 يوماً كاملة.',
    'بعدها سيعود للسعر الأساسي 14,000 دج.',
    'تفاصيل الدفع ستجدينها عندما تتواصلي معي على t.me/Abdouleg',
    'وإن مشيتم 30 يوماً بصدق وما حسيتم بفرق — أمدد لكم شهراً مجاناً. كلمة آدم.',
    'لا كتاب يعرف طفلكم بالاسم. آدم وحده يفعل هذا.',
    'جاهزة لنبدأ؟']
  loop
    g := public.gate_agent_reply(p, t);
    if not (g->>'blocked')::boolean then passed := passed || t; end if;
  end loop;

  perform pg_temp.chk('every real selling reply is stopped',
    cardinality(passed) = 0, left(array_to_string(passed, ' | '), 110));

  -- Named individually, because each is a different constitutional rule and
  -- a future edit could quietly drop one.
  perform pg_temp.chk('a price is refused (P17)',
    (public.gate_agent_reply(p, 'المرافقة بـ 2,300 دج.')->'blocking') @> '["sell:price"]'::jsonb);
  perform pg_temp.chk('an invented guarantee is refused',
    (public.gate_agent_reply(p, 'أمدد لكم شهراً. كلمة آدم.')->'blocking') @> '["brand:guarantee"]'::jsonb);
  perform pg_temp.chk('a superiority claim is refused',
    (public.gate_agent_reply(p, 'آدم وحده يفعل هذا.')->'blocking') @> '["brand:superiority"]'::jsonb);
  perform pg_temp.chk('posing as فريق آدم is refused (AD-1)',
    (public.gate_agent_reply(p, 'تواصلوا معي على t.me/Abdouleg')->'blocking') @> '["sell:impersonate"]'::jsonb);
  perform pg_temp.chk('a closing line is refused (§3.7)',
    (public.gate_agent_reply(p, 'جاهزة لنبدأ؟')->'blocking') @> '["sell:close"]'::jsonb);
end $$;

\echo '=== MACHINERY WORDS ARE COUNTED, NOT PUNISHED ==='
do $$
declare p uuid; g jsonb; n_before bigint; n_after bigint;
begin
  p := pg_temp.parent();

  g := public.gate_agent_reply(p, 'نحتاج خطة واضحة لنوم طفلكم.');
  perform pg_temp.chk('«خطة» is a brand violation but does NOT cost the parent an answer',
    not (g->>'blocked')::boolean, g::text);
  perform pg_temp.chk('and it is still seen',
    (g->'violations') @> '["machinery:خطة"]'::jsonb, (g->'violations')::text);

  select count(*) into n_before from public.reply_gate_log where parent_id = p;
  perform public.gate_agent_reply(p, 'سنتابع هذا في تقرير أسبوعي.');
  select count(*) into n_after from public.reply_gate_log where parent_id = p;
  perform pg_temp.chk('every violation is recorded, so the line can move on evidence',
    n_after = n_before + 1);

  -- A clean reply must not write a row. A log that fills with successes is a
  -- log nobody reads.
  select count(*) into n_before from public.reply_gate_log;
  perform public.gate_agent_reply(p, 'احكوا لي كيف مرّت الليلة.');
  select count(*) into n_after from public.reply_gate_log;
  perform pg_temp.chk('a clean reply writes nothing', n_after = n_before);
end $$;

\echo '=== THE GATE DOES NOT SHAPE THE VOICE ==='
do $$
declare p uuid; g jsonb; long_reply text;
begin
  p := pg_temp.parent();

  -- The founder named the templated voice as the deepest problem in the
  -- product. gate_composed_reply enforces a line budget and a uniqueness
  -- rule; pointing it at open conversation would push every reply toward
  -- the same safe three-line shape. This gate must never do that.
  long_reply :=
    'ما وصفتموه ليس عناداً.' || chr(10) ||
    'طفل في هذا العمر يفقد قدرته على الاحتمال قبل أن يفقد رغبته في الطاعة.' || chr(10) ||
    'الفرق بينهما أن الأول يُعالج بالراحة، والثاني بالحزم — والخلط بينهما يتعب الجميع.' || chr(10) ||
    'الليلة، جرّبوا الراحة أولاً وانظروا ما يحدث.' || chr(10) ||
    'وإن لم تنفع، نعرف شيئاً لم نكن نعرفه.';

  g := public.gate_agent_reply(p, long_reply);
  perform pg_temp.chk('a five-line reply is not truncated or refused',
    not (g->>'blocked')::boolean, g::text);

  -- Uniqueness must not be applied here either: the same sentence sent to a
  -- parent we know nothing about is still a legitimate reply.
  g := public.gate_agent_reply(p, 'النوم المتقطّع في هذا العمر شائع جداً.');
  perform pg_temp.chk('a reply with no family-specific fact is still allowed',
    not (g->>'blocked')::boolean, g::text);
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 54), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
