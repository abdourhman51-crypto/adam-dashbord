begin;

-- ============================================================
-- Applied directly to production earlier today and, like five
-- moments and two functions before it, never written down. The
-- local fixture caught it on the next migration that touched the
-- same row — which is the third time today the fixture has found
-- drift that production could not report about itself.
-- ============================================================

-- rescue was tier='composed' with a null body, and nothing in W1 composes
-- it. In practice the rescue — the message that fires when nothing else
-- could be determined — was silence. It now has a fixed floor. A composer
-- may still override it later; what changes is that the floor exists.
--
-- Its two buttons are removed: docs/telegram-logic.md L2 says a button may
-- only answer a question its own message asked. "كيف أفعلها بالضبط؟" on a
-- message that says "I did not understand" answers nothing.
update public.conversation_moments
set tier = 'fixed',
    max_lines = 2,
    buttons = '[]'::jsonb,
    body_ar = 'لم أفهم هذه تماماً.' || chr(10)
           || 'احكوا لي ما يحدث بكلماتكم، وأنا معكم.',
    note = 'The floor under every path. Fires when an update matches no route, when a composed body comes back empty, and when anything else fails. Silence is the one output that is always wrong.'
where key = 'rescue';

-- A parent whose commerce is blocked used to get strain_l2 when they opened
-- /journey — "هذا كثير على شخص واحد". They asked what the companionship is
-- and were told they looked overwhelmed. That is a suppression announcing
-- itself, which L4 forbids.
--
-- They now get a real answer with the price simply absent: free stays free,
-- journeys exist, فريق آدم explains when they want. No number, no urgency,
-- and nothing that reveals they were classified.
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('menu_journey_presence', 'reference', 'fixed',
   'المرافقة اليومية التي بيننا الآن تبقى كما هي — مجاناً، دائماً.' || chr(10) ||
   'وحين يظهر هدف واضح لطفلكم، نبني له رحلة نمشي فيها يوماً بيوم حتى نصل.' || chr(10) ||
   'فريق آدم يشرح التفاصيل متى شئتم: https://t.me/Abdouleg',
   '[]'::jsonb, 4, false,
   'What /journey answers when commerce is blocked. Same question answered, price withheld, classification invisible (L4).')
on conflict (key) do update
  set body_ar = excluded.body_ar, max_lines = excluded.max_lines, note = excluded.note;

commit;
