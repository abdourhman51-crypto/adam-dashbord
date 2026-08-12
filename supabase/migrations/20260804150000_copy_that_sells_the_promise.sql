begin;

-- ============================================================
-- The copy stops describing the machine and starts saying the promise.
-- (docs/adam-brand-bible.md §0 · docs/adam-promise.md · docs/adam-system.md §5)
--
-- Founder review of the live surface, from his own Telegram session:
-- the buttons are weak, there is no clear line between free and paid,
-- and there is no reason anywhere for a parent to want the paid thing.
-- All three are true, and all three are already ANSWERED in the brand
-- bible — the live copy simply never carried the answers.
--
-- WHAT THE BRAND ALREADY DECIDED, AND THE COPY IGNORED
--
--   Reason to buy    «القصة تتكرّر. أنتم لا.»
--   Reason to believe «آدم لا يعرف شيئاً عن الأطفال — يعرف عن طفلكم»
--   Free vs paid      «المجاني: أن تكون القصة أخفّ.
--                      المرافقة: ألّا تتكرّر القصة.»
--
-- That last pair is the sharpest sentence this product owns, and it
-- appeared in ZERO live strings. It is the whole answer to "what am I
-- paying for", and a parent understands it in one second without
-- anyone explaining. It now leads every commercial surface.
--
-- «شيء آخر» — NINE TIMES, AND IT MEANS NOTHING
--
-- chk_escape_hatch requires a button whose cb is 'other'. It says
-- nothing about the LABEL. Every escape hatch shipped with the same
-- placeholder text, so a parent who does not know ADAM reads nine
-- dead ends. The constraint is satisfied by the callback; the label is
-- free, and it is now written per context — each one names what it
-- actually opens.
--
-- THE COMMAND THAT SELLS CANNOT BE NAMED
--
-- Verified against production copy_violations(): the literal string
-- «/journey» is blocked as internal:latin. So the one command that
-- reaches the paid offer can never be written in stored copy — the FAQ
-- literally could not tell a parent where to go. Fixed the right way
-- rather than by loosening the rule: a BUTTON carrying
-- cta_full_companion, which the Router already maps to menu_journey.
-- No typing, no hunting for a command, and the internal lexicon stays
-- banned.
--
-- VOCABULARY CORRECTION THE PROMISE DOC ASKED FOR AND NEVER GOT
--
-- menu_journey said «ليالٍ أهدأ». adam-promise.md flags night-shaped
-- words as sleep-product language that tells a parent whose repeating
-- story is the morning battle that ADAM is not for them — one sentence
-- that loses them. Replaced with «الموقف», which is domain-neutral by
-- design.
--
-- Every string below was checked against production's own
-- copy_violations() and content_line_count() BEFORE this migration was
-- written, not after it failed.
-- ============================================================


-- ------------------------------------------------------------
-- The door. A parent here knows nothing about ADAM, and the old
-- line («أرافق الأهل مع أطفالهم، يوماً بيوم») is a category
-- description — true of every parenting app ever made. The reason
-- to believe belongs here instead, because it is the one thing no
-- competitor can say: what I tell you does not fit another child.
-- ------------------------------------------------------------
update public.conversation_moments set
  body_ar = 'السلام عليكم 🌿' || chr(10) ||
            'أنا آدم. لا أعطي نصائح عامّة من كتاب — ما أقوله يخصّ طفلكم أنتم، ويكبر كلما حكيتم.' || chr(10) ||
            'احكوا لي ما حدث اليوم معه، بكلماتكم.'
where key = 'first_contact';

update public.conversation_moments set
  body_ar = 'أنا آدم. تحكون لي ما يحدث مع طفلكم، فأعطيكم شيئاً صغيراً يُجرَّب اليوم، ثم نسأل مساءً: هل تغيّر شيء؟' || chr(10) ||
            'وكلما حكيتم أكثر، صار ما أقوله أقرب لطفلكم بالذات — لا لطفل غيره.',
  buttons = '[{"label":"كيف أبدأ؟","cb":"help_start"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_help';


-- ------------------------------------------------------------
-- The FAQ is where the highest-intent commercial question in the
-- whole product lives: «هل هو مجاني؟». The old answer named the
-- free tier and stopped — it sold nothing and, worse, implied
-- there was nothing else. Now it answers honestly (free stays
-- free, forever, undiminished) and then draws the line, followed
-- by a button that goes straight to the offer.
--
-- Also adds «ولماذا آدم بالذات؟» — the reason to believe, stated
-- once, as the brand bible maps it to this surface.
-- ------------------------------------------------------------
update public.conversation_moments set
  body_ar =
    '**ما هو آدم؟**' || chr(10) ||
    'مرافق يومي للأهل. تحكون له ما يحدث مع طفلكم، فيعطي شيئاً صغيراً يُجرَّب في نفس اليوم، ثم يسأل مساءً: هل تغيّر شيء؟' || chr(10) || chr(10) ||
    '**ولماذا آدم بالذات؟**' || chr(10) ||
    'لأن ما يقوله لا يصلح لطفل غير طفلكم. الكتاب لا يعرف أن هذه ثالث مرة يتكرّر فيها الموقف عندكم — وآدم يعرف.' || chr(10) || chr(10) ||
    '**كيف أبدأ؟**' || chr(10) ||
    'اكتبوا ما يشغلكم مع طفلكم. لا إعداد ولا أسئلة قبلها.' || chr(10) || chr(10) ||
    '**هل هو مجاني؟**' || chr(10) ||
    'نعم. الحديث معي، والفهم، والشيء الصغير كل يوم — مجاناً، دائماً، ولا ينقص منه شيء أبداً.' || chr(10) || chr(10) ||
    '**وما الفرق بين المجاني والمرافقة؟**' || chr(10) ||
    'المجاني يجعل الموقف أخفّ عليكم.' || chr(10) ||
    'والمرافقة تعمل على ألّا يتكرّر الموقف أصلاً.' || chr(10) ||
    'رحلة واحدة نحو هدف واحد تسمّونه أنتم، نمشي إليه يوماً بيوم حتى نصل — أو حتى نعرف معاً أنه لا يصلح، وأقولها لكم بصراحة.' || chr(10) || chr(10) ||
    '**ماذا لو لم ينفع ما جرّبناه؟**' || chr(10) ||
    'نجرّب زاوية أخرى غداً. المحاولة نفسها تغيّر شيئاً، ولا شيء عليكم فيها.' || chr(10) || chr(10) ||
    '**هل يمكن إيقاف الرسائل؟**' || chr(10) ||
    'نعم، متى شئتم من الإعدادات، ويبقى الحديث مفتوحاً كما هو.' || chr(10) || chr(10) ||
    '**ماذا يحدث لما أقوله؟**' || chr(10) ||
    'يبقى بينكم وبينه، ويمكن حذف كل شيء متى شئتم دون أسئلة.',
  buttons = '[{"label":"أخبروني أكثر عن المرافقة","cb":"cta_full_companion"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_faq';


-- ------------------------------------------------------------
-- The evening question — Peak-End, the most remembered message
-- ADAM sends, and its buttons read like a form: «نجحت» /
-- «جرّبناها وما نجحت» / «ما صارت الفرصة».
--
-- Two things wrong. First, «نجحت» measures the STEP, while the
-- whole point of parent_effort() is that the score is about the
-- PARENT — so the labels now report what happened, not a verdict.
-- Second, «ما صارت الفرصة» quietly blames: it makes a parent who
-- was too exhausted to try say so in the language of a missed
-- obligation. An unanswered demand from an app produces guilt, and
-- guilt ends subscriptions before they start. «اليوم كان أثقل»
-- says the same fact and carries none of it.
-- ------------------------------------------------------------
update public.conversation_moments set
  body_ar = 'كيف مرّ اليوم مع طفلكم؟',
  buttons = '[{"label":"مرّ أهدأ","cb":"ck_step_ok"},
              {"label":"جرّبنا، وما تغيّر","cb":"ck_step_failed"},
              {"label":"اليوم كان أثقل","cb":"ck_step_skip"},
              {"label":"صار شيء آخر","cb":"other"}]'::jsonb
where key = 'harvest_ask';


-- ------------------------------------------------------------
-- Every remaining escape hatch, named for what it opens.
-- ------------------------------------------------------------
update public.conversation_moments set
  buttons = '[{"label":"كيف نبدأ؟","cb":"how_start"},
              {"label":"ليس الآن","cb":"not_now"},
              {"label":"عندي موقف آخر","cb":"other"}]'::jsonb
where key = 'goal_visible';

update public.conversation_moments set
  buttons = '[{"label":"احذفوا كل ما قلته","cb":"erase"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_privacy';

update public.conversation_moments set
  buttons = '[{"label":"أوقات أهدأ","cb":"quiet_hours"},
              {"label":"أوقفوا الرسائل","cb":"pause"},
              {"label":"عندي موقف آخر","cb":"other"}]'::jsonb
where key = 'menu_settings';

update public.conversation_moments set
  buttons = '[{"label":"نعود من الغد","cb":"resume_tomorrow"},
              {"label":"نبقى كما نحن","cb":"stay_paused"},
              {"label":"عندي موقف آخر","cb":"other"}]'::jsonb
where key = 'menu_resume';

update public.conversation_moments set
  buttons = '[{"label":"أخبروني حين تصل","cb":"waitlist_join"},
              {"label":"عندي موقف آخر","cb":"other"}]'::jsonb
where key in ('menu_waitlist', 'country_other');

update public.conversation_moments set
  buttons = '[{"label":"نعم، نعمل عليه","cb":"review_yes"},
              {"label":"نكمل كما نحن","cb":"review_stay"},
              {"label":"عندي موقف آخر","cb":"other"}]'::jsonb
where key = 'review_stage4';

update public.conversation_moments set
  buttons = '[{"label":"الجزائر","cb":"set_country_DZ"},
              {"label":"مصر","cb":"set_country_EG"},
              {"label":"المغرب","cb":"set_country_MA"},
              {"label":"بلد آخر","cb":"set_country_OTHER"},
              {"label":"أفضّل ألّا أقول","cb":"other"}]'::jsonb
where key = 'country_ask_footer';


-- ------------------------------------------------------------
-- The answer when commerce is withdrawn (strain L2/L3). It may
-- not carry a price, but it may still carry the reason — and
-- withholding the reason is what made it read like a shrug.
-- ------------------------------------------------------------
update public.conversation_moments set
  body_ar = 'المجاني يبقى مجانياً — الحديث، والفهم، وشيء صغير كل يوم. لا ينقص منه شيء.' || chr(10) ||
            'وحين يظهر هدف واضح لطفلكم، نبني له رحلة نمشي فيها يوماً بيوم حتى نصل.' || chr(10) ||
            'وفريق آدم يشرح التفاصيل متى شئتم: https://t.me/Abdouleg'
where key = 'menu_journey_presence';


-- ------------------------------------------------------------
-- get_conversation_moment — menu_journey, the commercial surface.
--
-- Only the 'supported' branch changes. It used to open with what
-- ADAM does («المرافقة اليومية التي بيننا الآن تبقى كما هي») and
-- close with a bare number. Now it opens by protecting the free
-- tier — the fear that must be answered before anything is heard —
-- then draws the brand's line, then states what is actually being
-- bought (one goal the parent names, walked to together), then the
-- commitment that makes the price fair, and only then the price.
--
-- «ليالٍ أهدأ» is gone: adam-promise.md names night-shaped
-- vocabulary as the sleep-product leak that tells a morning-battle
-- parent this is not for them.
-- ------------------------------------------------------------
create or replace function public.get_conversation_moment(
  p_key       text,
  p_parent_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  m         public.conversation_moments%rowtype;
  v_cs      jsonb;
  v_body    text;
  v_buttons jsonb;
  v_nl      text := chr(10);
begin
  select * into m from public.conversation_moments where key = p_key;
  if not found then
    return jsonb_build_object('found', false, 'key', p_key);
  end if;

  if m.requires_commerce and p_parent_id is not null
     and not coalesce(public.commerce_allowed(p_parent_id), true) then
    return jsonb_build_object('found', true, 'key', p_key, 'allowed', false,
                              'reason', 'commerce_blocked');
  end if;

  v_body    := m.body_ar;
  v_buttons := m.buttons;

  if p_key = 'menu_journey' then
    v_cs := public.country_state(p_parent_id);

    if (v_cs->>'state') = 'supported' then
      -- The price is read from supported_countries, per country, at read
      -- time. It is stored in exactly one place and spoken in exactly one.
      v_body :=
        'المجاني يبقى مجانياً — الحديث، والفهم، وشيء صغير كل يوم. لا ينقص منه شيء أبداً.' || v_nl || v_nl ||
        'والفرق بينه وبين المرافقة سطر واحد:' || v_nl ||
        'المجاني يجعل الموقف أخفّ عليكم.' || v_nl ||
        'والمرافقة تعمل على ألّا يتكرّر الموقف أصلاً.' || v_nl || v_nl ||
        'هدف واحد تسمّونه أنتم، ونمشي إليه يوماً بيوم حتى نصل —' || v_nl ||
        'أو حتى نعرف معاً أنه لا يصلح، وأقولها لكم بصراحة. هذا وعدي في الحالتين.' || v_nl || v_nl ||
        'الرحلة الواحدة: ' || (v_cs->>'price') || '.' || v_nl ||
        'وفريق آدم يشرح التفاصيل وطرق الدفع:' || v_nl ||
        'https://t.me/Abdouleg';
      v_buttons := '[]'::jsonb;

    elsif (v_cs->>'state') = 'unknown' then
      -- We do not know where they are. Saying "not yet in your country"
      -- here would be a sentence we cannot stand behind. Ask instead --
      -- and the answer also unblocks the daily rhythm, which needs a
      -- local clock before it can write at an honest hour.
      v_body :=
        'المرافقة الكاملة تختلف من بلد لآخر — السعر وطريقة الدفع محليّان.' || v_nl || v_nl ||
        'من أي بلد أنتم؟';
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','الجزائر',  'cb','set_country_DZ'),
        jsonb_build_object('label','مصر',     'cb','set_country_EG'),
        jsonb_build_object('label','المغرب',   'cb','set_country_MA'),
        jsonb_build_object('label','بلد آخر', 'cb','set_country_OTHER'),
        -- Added after the fact. Without it this branch asked a question
        -- with no way out, which is the one thing the button law exists
        -- to prevent, and it got here by being composed instead of stored.
        jsonb_build_object('label','عندي موقف آخر', 'cb','other'));

    else
      v_body :=
        'آدم يرافقكم بالكامل، كما يرافق الجميع.' || v_nl ||
        'كل ما بيننا الآن يبقى كما هو، دون نقص.' || v_nl || v_nl ||
        'والرحلات المدفوعة لم تصل بلدكم بعد، لسبب واحد:' || v_nl ||
        'لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.' || v_nl ||
        'وحين تتوفّر، تصلكم رسالة.';
      v_buttons := '[{"label":"أخبروني حين تصل","cb":"waitlist_join"},{"label":"عندي موقف آخر","cb":"other"}]'::jsonb;
    end if;

  elsif v_body is null then
    v_body := public.compose_menu_body(p_key, p_parent_id);
  end if;

  if v_body is null or btrim(v_body) = '' then
    return jsonb_build_object('found', false, 'key', p_key,
                              'reason', 'composed_to_nothing');
  end if;

  return jsonb_build_object(
    'found', true, 'key', m.key, 'allowed', true, 'category', m.category,
    'tier', m.tier, 'body', v_body, 'buttons', v_buttons,
    'buttons_forbidden', m.buttons_forbidden, 'max_lines', m.max_lines);
end;
$function$;

commit;
