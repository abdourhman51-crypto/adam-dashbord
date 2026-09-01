-- first_contact -- the very first message any brand-new parent ever gets --
-- still said "كل الأوامر... تلقونها بزر القائمة ☰ تحت مربّع الكتابة" without
-- ever naming the Mini App, predating 20260830's "the agent learns the Mini
-- App exists" prompt fix (docs/prompts/adam-conversation-agent.md). That fix
-- taught the LIVE conversational agent to name the Mini App by one honest
-- sentence -- this static, pre-agent greeting was simply never updated
-- alongside it, so the very first thing a new parent reads still describes
-- the button as a generic command menu instead of naming what it actually
-- opens.

update public.conversation_moments
set body_ar = '🌿 أهلاً، أنا آدم — مرافق أبوّة يومي. تحكون لي عن يومكم مع طفلكم، وأرد بخطوة صغيرة واحدة تناسبه هو بالذات.' || chr(10) || chr(10)
  || '📱 وفوق هذا، فيه تطبيق آدم المصغّر — تفتحونه من الزر بجانب مربّع الكتابة، وفيه خطوة اليوم وتقدّمكم يوماً بيوم.' || chr(10) || chr(10)
  || 'احكوا لي الآن: كيف كان يومكم معه؟'
where key = 'first_contact';
