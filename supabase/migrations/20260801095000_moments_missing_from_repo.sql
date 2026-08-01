begin;

-- ============================================================
-- Five moments that existed in production and in no migration.
--
-- They were applied directly during the command-menu work and
-- never written to a file, so a clean checkout built a product
-- missing /journey, /faq, the voice reply and the waitlist
-- acknowledgement — the four surfaces a lost parent is most
-- likely to reach.
--
-- The local fixture found this, not production. That is the
-- point of the fixture: drift shows up as a failing test in a
-- throwaway database rather than as silence on a phone.
--
-- Bodies copied verbatim from pg_proc/pg_class output, not
-- retyped from memory.
-- ============================================================

-- ------------------------------------------------------------
-- The 'reference' category, also missing from the repo.
--
-- chk_line_budget caps every moment at three lines, because
-- ADAM's replies must be short: an exhausted parent cannot read
-- an essay she did not ask for. A page she deliberately opened —
-- the FAQ, the journey description — is a different object, and
-- 'reference' says so rather than smuggling help text into
-- 'review'. The three-line cap still binds every unprompted
-- message, which is the rule that actually matters.
-- ------------------------------------------------------------
alter table public.conversation_moments
  drop constraint if exists conversation_moments_category_check,
  drop constraint if exists conversation_moments_max_lines_check,
  drop constraint if exists chk_line_budget;

alter table public.conversation_moments
  -- 40 is the FAQ's ceiling, not a target. Nothing unprompted may
  -- come near it: chk_line_budget below is what enforces that.
  add constraint conversation_moments_max_lines_check
    check (max_lines >= 1 and max_lines <= 40),
  add constraint conversation_moments_category_check
    check (category in ('greeting','rescue','rhythm','goal','strain',
                        'crisis','menu','review','referral','reference')),
  add constraint chk_line_budget
    check (max_lines <= 3
           or category in ('goal','review','crisis','reference'));


insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, buttons_forbidden,
   max_lines, requires_commerce, note)
values

  ('voice_unsupported', 'greeting', 'fixed',
   'الصوت لا يصلني بعد — لكن الكتابة تصل كاملة.' || chr(10) ||
   'اكتبوا ما حدث ولو بكلمات قليلة.',
   '[]'::jsonb, false, 2, false,
   'Honest failure instead of silence. A voice note previously reached the agent with an empty prompt and produced nonsense. Delete this row the day voice transcription actually works.'),

  ('menu_journey', 'reference', 'composed',
   null, '[]'::jsonb, false, 12, true,
   'D7. The Menu is the door and فريق آدم is the cashier. Built by get_conversation_moment from supported_countries at read time, so no price is ever stored and there is one place it can change. requires_commerce means a parent at strain L2/L3 gets presence instead.'),

  ('waitlist_joined', 'reference', 'fixed',
   'سُجّلتم. حين تصل الرحلات إلى بلدكم، تصلكم رسالة مني — ولا شيء قبلها.' || chr(10) ||
   'وكل ما بيننا يبقى كما هو.',
   '[]'::jsonb, false, 3, false,
   'The waitlist promise must be real: followers.waitlist is set when this fires. "ولا شيء قبلها" is binding — joining a waitlist is not permission to market.'),

  ('menu_faq', 'reference', 'fixed',
   '**ما هو آدم؟**' || chr(10) ||
   'مرافق يومي للأهل. تحكون له ما يحدث مع طفلكم، ويعطي خطوة صغيرة تُجرَّب في نفس اليوم، ثم يسأل مساءً: هل نفعت؟' || chr(10) || chr(10) ||
   '**كيف أبدأ؟**' || chr(10) ||
   'اكتبوا ما يشغلكم مع طفلكم. لا يوجد إعداد ولا أسئلة قبلها.' || chr(10) || chr(10) ||
   '**هل هو مجاني؟**' || chr(10) ||
   'المرافقة اليومية مجانية دائماً — الحديث، والفهم، والخطوة كل يوم.' || chr(10) || chr(10) ||
   '**هل يتذكّر طفلي؟**' || chr(10) ||
   'نعم. كلما تحدّثنا أكثر، صار ما يقترحه أقرب لطفلكم بالذات، لا كلاماً عامّاً.' || chr(10) || chr(10) ||
   '**ماذا لو لم تنفع الخطوة؟**' || chr(10) ||
   'نجرّب زاوية أخرى غداً. المحاولة نفسها تغيّر شيئاً، ولا شيء عليكم فيها.' || chr(10) || chr(10) ||
   '**هل يمكن إيقاف الرسائل؟**' || chr(10) ||
   'نعم، متى شئتم من الإعدادات، ويبقى الحديث مفتوحاً كما هو.' || chr(10) || chr(10) ||
   '**ماذا يحدث لما أقوله؟**' || chr(10) ||
   'يبقى بينكم وبينه، ويمكن حذف كل شيء متى شئتم دون أسئلة.',
   '[{"label":"شيء آخر","cb":"other"}]'::jsonb, false, 24, false,
   'Merged with menu_help — they were the same surface twice. Opens with ما هو آدم so the first thing a lost parent reads is the answer to the first thing they wonder.'),

  ('menu_help', 'menu', 'fixed',
   'أنا آدم — أرافق الأهل مع أطفالهم يوماً بيوم.' || chr(10) ||
   'تحكون لي ما يحدث، وأقترح خطوة صغيرة تُجرَّب اليوم، ثم نسأل مساءً: هل نفعت؟' || chr(10) ||
   'وكلما تحدّثنا أكثر، صار ما أقترحه أقرب لطفلكم بالذات.',
   '[{"label":"كيف أبدأ؟","cb":"help_start"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
   false, 3, false,
   'DEPRECATED - merged into menu_faq. Router sends both there. Kept so an old inline button does not break.')

on conflict (key) do update
  set category          = excluded.category,
      tier              = excluded.tier,
      body_ar           = excluded.body_ar,
      buttons           = excluded.buttons,
      buttons_forbidden = excluded.buttons_forbidden,
      max_lines         = excluded.max_lines,
      requires_commerce = excluded.requires_commerce,
      note              = excluded.note;

commit;
