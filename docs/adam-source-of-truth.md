# آدم — وثيقة الحقيقة الموحّدة (المصدر الوحيد المعتمد)

آخر تحديث: **2026-09-02** · الفرع: `claude/adam-telegram-miniapp-0q4a27` · آخر commit: `addce56`

⚠️ **هذا الملف يُلغي عملياً كل الوثائق السابقة في `docs/` من ناحية "ما هي الحالة الحالية".**
معظمها قديم ومتناقض (مثلاً `docs/HANDOFF.md` من 2026-08-12 يذكر `luxe/` وW1 بـ126 عقدة —
لا شيء من هذا صحيح اليوم). إن تعارض أي ملف آخر مع هذا الملف: **هذا الملف هو الصحيح.**
أي جلسة جديدة: اقرأ هذا الملف فقط أولاً، وابحث في الكود مباشرة عند الحاجة لتفاصيل أعمق —
لا تفترض صحة أي doc قديم آخر.

---

## 0. ما هو آدم (سطران)

بوت تيليجرام + تطبيق مصغّر (Mini App) + داشبورد داخلي، يرافق الوالدين يومياً: يسمع سطراً
عن يومهم مع طفلهم، ويرد بخطوة صغيرة قابلة للتطبيق الليلة نفسها. القيمة المُباعة في صفحة
الهبوط = نتيجة/تحوّل ملموس عند الوالد — لا "نظام تتبع" أو "تحليل" (مفردات ممنوعة، §6).

## 1. خريطة المستودع (4 أجزاء مستقلة، نفس الـ repo)

| المسار | ما هو | يُنشر إلى |
|---|---|---|
| `supabase/` | المنتج الحي: migrations + دوال Postgres + اختبارات | Supabase مباشرة |
| `docs/` | التوثيق — معظمه قديم، هذا الملف هو الاستثناء المحدَّث | — |
| بوت تيليجرام | **لا كود له في هذا الـ repo** — يعيش كـ workflow كامل في n8n | n8n (hawiyat.cloud) |
| `miniapp/` | التطبيق المصغّر داخل تيليجرام (Next.js) | Vercel: `adam-miniapp` |
| `dashboard/` | داشبورد داخلي (Next.js) يقرأ نفس Supabase | Vercel: `adam-dashbord` |
| `landing/` | صفحة الهبوط التسويقية (Next.js) | Vercel — ⚠️ فوضى، §6 |

## 2. البوت (n8n)

- n8n على `adam-voices-n8n.hawiyat.cloud`.
- الـ workflow الفعّال: **`ADAM - Machine 1+2 - Reception, Gates & AI Agents`** — id `42loY0bgUSwYmHFV`.
- العقد الأهم داخله:
  - **`paid aget adam`** — الوكيل الرئيسي (AI Agent). برومبته مطابق حرفياً لـ
    `docs/prompts/adam-conversation-agent.md`. **هذا الملف = مصدر حقيقة البرومبت**: عدّل
    الملف أولاً، ثم انسخه لنفس الحقل في n8n. لا العكس.
  - **`M2 - Classify Track`** (Code node) — يصنّف كل رسالة واردة: محادثة عادية أم إجابة عن
    سؤال "أي بلد؟". نافذة اعتبار الرسالة "إجابة بلد" = **15 دقيقة** من وقت السؤال (كانت 36
    ساعة خطأً → سبب شكوى "آدم يرد بالطريقة القديمة/ردود مكررة"، أُصلح 2026-09-01).
  - **`M2 - Extract Step`** — يستخرج جملة "الخطوة" حرفياً من نص آدم (اقتباس حرفي، لا صياغة).
  - **`Is Country Answer?`** (IF) → يوجّه لـ `Tap - Get Parent` قبل `M2 - Track Switch`
    (لأن Switch V1 محدود بـ4 مخارج).
  - W2 (Knowledge Writer، `7mTP12nVLS1Taokl`)، W3 (Rhythm Sender، `Vb4ADCkPsevPRWRN`)، W4
    (First Mirror) — **حالتها الفعلية (active/paused) غير مؤكَّدة في هذه الجلسة**. تحقق
    مباشرة من n8n قبل الاعتماد على أي وصف سابق (`docs/HANDOFF.md` يقول paused، لكن تاريخه
    2026-08-12).

⚠️ **فخّ حرج عند أي تعديل عبر `update_workflow` / `setNodeParameter`:** الـ `path` نسبي
لـ `node.parameters` نفسه، وليس للعقدة كلها. `/parameters/options/systemMessage` يكتب في
مكان ميت لا يُقرأ أبداً، ويرجع نجاحاً بلا أي خطأ. الصحيح: `/options/systemMessage`
(وبالمثل `/jsCode` للـ Code nodes، `/jsonBody` للـ HTTP Request — بدون بادئة `/parameters`).
**دائماً أعد الجلب (`get_workflow_details`) بعد كل تعديل وقارن الفرق — نجاح الاستدعاء لا
يعني أن التعديل نفذ فعلياً.** هذا سبّب فشل تعديلين "ناجحين" سابقين هذه الجلسة.

## 3. قاعدة البيانات (Supabase)

- مشروع `aajqbmjasnbwwyvgrlzy` ("Adam OS")، Postgres 17.6.
- الحقيقة = آخر migration في `supabase/migrations/` بترتيب التاريخ في اسم الملف — لا أي
  وصف نصي في أي doc.
- جداول أساسية: `followers` (الوالد)، `n8n_chat_histories` (كل رسائل المحادثة)،
  `miniapp_events` (تتبع التطبيق المصغّر، جديد 2026-09-01).
- دوال مهمة:
  - `get_rhythm_due()` — البوابة الوحيدة لكل إرسال مجدوَل (seed/harvest/journey-step).
    يمتنع عن الإرسال إن كان هناك أي نشاط محادثة حي خلال آخر 90 دقيقة.
  - `get_moment_after_tap()` / `commit_chat_step()` — لحظة تثبيت الخطوة من التطبيق
    المصغّر؛ الرد الآن يردد نص الخطوة الفعلي (لم يعد مديحاً عاماً مكرَّراً).
  - `get_miniapp_overview`, `get_miniapp_daily_active`, `get_miniapp_screen_performance`,
    `get_miniapp_top_clicks`, `get_miniapp_retention` — الدوال الخمس التي يقرأ منها
    `/dashboard/miniapp`. كلها تستثني حسابَي الاختبار المعتمَدَين
    (`TEST_PLATFORM_USER_IDS` = `7377091520`, `8074049810`، معرَّفة في
    `dashboard/lib/supabase/admin.ts`).
- الاختبارات المحلية `supabase/tests/*.sql` تُشغَّل بدون اتصال حقيقي (postgres مؤقت) —
  سكريبت التشغيل في `docs/HANDOFF.md` لا يزال صالحاً تقنياً رغم قِدَم باقي الملف.

## 4. التطبيق المصغّر (`miniapp/`) + نظام التتبع

- Next.js، Vercel project **`adam-miniapp`** (id `prj_apnowjntsgnk77qspzcB0pzws53O`) →
  **`adam-miniapp.vercel.app`** (production حقيقي، **مؤكَّد الآن يخدم commit `addce56`**).
- التحقق من هوية المستخدم: `miniapp/lib/telegram/verify.ts` — HMAC-SHA256 قياسي على
  Telegram `initData` (`secret_key = HMAC(key="WebAppData", data=BOT_TOKEN)`).
- الشاشات: `app/{page,journey,journey/start,child,insights}` + مكوّنات في `components/`.
- **نظام التتبع (بُني 2026-09-01/02):**
  - جدول `miniapp_events` (`event_type`: screen_view / screen_time / click، مع `screen`,
    `element`, `meta jsonb`, `session_id`, `follower_id`).
  - `miniapp/lib/analytics.ts` — يدير `session_id` عبر `sessionStorage`، يرسل الأحداث
    بـ `navigator.sendBeacon` (احتياطياً `fetch`).
  - `miniapp/app/api/track/route.ts` — نقطة الاستقبال. **مهم:** `initData` تُمرَّر كـ
    query param `?d=` وليس كـ header، لأن `sendBeacon` لا يقدر يرسل headers مخصّصة (كل
    مسارات الـ API الأخرى تستعمل header `x-telegram-init-data` — هذا المسار وحده استثناء).
  - `miniapp/components/ScreenViewTracker.tsx` — مركَّب في `layout.tsx`، يسجّل
    `screen_view` عند كل تغيّر مسار، ويحسب `screen_time` عند مغادرة الشاشة/إغلاق التطبيق.
  - نقرات مُتَتبَّعة يدوياً في: `ChatCTAButton`, `BottomNav`, `PanicButton`,
    `EveningCheckIn`, `app/page.tsx`.
  - الداشبورد: `dashboard/app/miniapp/page.tsx` — زيارات/جلسات/متوسط مدة الجلسة، أداء كل
    شاشة (+ نسبة الخروج)، أكثر النقرات، عائدون مقابل جدد، D1/D7 retention.
  - **✅ الحالة الآن (تأكدت عبر Vercel API في هذه الجلسة):** آخر نشر production فعلي على
    `adam-miniapp.vercel.app` هو commit `addce56` — يشمل نظام التتبع كاملاً + استثناء
    حسابات الاختبار. **النظام حيّ فعلاً الآن، وليس فقط في الكود.**

⚠️ **درس لأي جلسة قادمة:** هذا المشروع سابقاً احتاج ترقية يدوية "Promote to Production"
بعد كل push (8 commits بقيت preview فقط دون أن تصل للمستخدمين، رغم أن الكود كان "جاهزاً").
**لا تفترض أبداً أن push للـ git = وصل للمستخدمين.** تحقق دائماً بـ
`mcp__Vercel__get_project` (أو `list_deployments`) أن `latestDeployment.target ==
"production"` وأن الـ commit SHA فيه هو نفس آخر commit قبل تبليغ المستخدم أن أي تعديل نُشر.

## 5. الداشبورد (`dashboard/`)

- Vercel project **`adam-dashbord`** (id `prj_R0gjW4uq9bOdivgMGJin9DBGNa5s`) →
  **`adam-dashbord.vercel.app`** (production مؤكَّد، آخر commit `addce56`).
- الصفحات: `/` (نظرة عامة), `/conversations`, `/customers`, `/patterns`, `/stages`,
  `/insights`, `/miniapp` (تحليلات التطبيق المصغّر، جديدة).
- الاستعلامات في `dashboard/lib/queries/*.ts`؛ `shared.ts` يحوي منطق استثناء حسابات
  الاختبار (`includeTest`) المستعمل في كل الصفحات.
- ⚠️ **مشروع مكرر مهجور:** `adam-dashboard-t2s8` (id `prj_J8MSG97PfrRd8Wx5ngOYqzoTV13s`) —
  نفس الربط لنفس الـ repo، لكن آخر نشر له بحالة `BLOCKED`. **لا تستعمله ولا تحدّثه** —
  الأفضل حذفه (قرار المؤسّس).

## 6. صفحة الهبوط (`landing/`)

- المحتوى النصي أُعيد صياغته بالكامل (2026-09-02) بمعادلة القيمة لأليكس هورموزي (Dream
  Outcome × Perceived Likelihood) / (Time Delay × Effort) — بدون أي تغيير بصري/هيكلي، فقط
  `app/page.tsx` + `app/layout.tsx` (metadata).
- مفردات ممنوعة دائماً (من `docs/adam-brand-bible.md`): "ذاكرة، تقرير، خطة، نظام، تحليل،
  متابعة، ذكاء، أتمتة، أنماط، تخصيص، سياق، مسار، ملف، لوحة، تتبّع، قياس".

🚨 **فوضى غير محلولة — تحتاج قرار من المؤسّس قبل أي عمل جديد على اللاندنغ:** يوجد **4
مشاريع Vercel منفصلة** لنفس `landing/`، كلها مربوطة بنفس الـ repo/الفرع، **ولا واحد منها
عليه `target: "production"` حالياً** (تأكدت عبر Vercel API في 2026-09-02):

| مشروع | نطاقاته |
|---|---|
| `adam-landing` | `adam-landing-henna.vercel.app`, `adam-landing-adammm.vercel.app` |
| `adam-landing-page` | `adam-landing-page-two.vercel.app`, `adam-landing-page-adammm.vercel.app` |
| `adam-landing-v2` | `adam-landing-v2.vercel.app` |
| `adam-landing-test` | (بلا ربط git) |

لا يوجد "production" رسمي واضح لصفحة الهبوط الآن. **قبل أي عمل جديد: اسأل المؤسّس أي رابط
هو الذي يُستعمل فعلياً في التسويق، وثبّته هنا، واحذف الباقي.**

## 7. فخاخ/دروس تقنية عامة (لا تُعِد اكتشافها)

- `setNodeParameter` في n8n — انظر §2.
- `navigator.sendBeacon` لا يقدر يرسل custom headers → مرّر البيانات الحساسة عبر query
  string إن كان الطلب سيُرسَل بها.
- أداة `Read` في هذه البيئة محدودة بحجم ملف (256KB) وبعدد tokens للمخرجات لكل استدعاء
  (~25000) — لا تحاول نقل شجرة ملفات كبيرة (~500KB+) عبر context لغرض نشر يدوي؛ استعمل
  `git push` العادي بدلاً من ذلك.
- بروكسي الشبكة في بيئة sandbox هذه يمنع `curl` مباشر لأي نطاق خارجي عام (`*.vercel.app`
  إلخ) — استعمل أدوات MCP (Vercel/GitHub/Supabase) بدل Bash للتحقق من حالة الإنتاج.
- لا تثق بنجاح استدعاء "نشر/تعديل" وحده — تحقق دائماً بإعادة القراءة/الفرق (git diff،
  fresh fetch من n8n، أو `target` في Vercel deployment).

## 8. مهام مفتوحة معروفة

- `M2 - Track Switch` فيه تحذير validator قديم (`rules.rules` vs `rules.values`) — تقييم
  سابق أنه على الأرجح false positive (syntax v1 صالح لكنه يبدو مثل v3)، لم يُعَد التأكد.
- تنظيف مشاريع Vercel المكررة (اللاندنغ ×4 + `adam-dashboard-t2s8`) — قرار المؤسّس مطلوب.
- W2/W3/W4 في n8n: حالتها الفعلية لم تُتحقق في هذه الجلسة — تحقق مباشرة قبل الاعتماد على
  أي وصف سابق.

## 9. كيف تُحدَّث هذه الوثيقة

كل جلسة تُدخل تغييراً حقيقياً على البوت/التطبيق المصغّر/الداشبورد/اللاندنغ/قاعدة البيانات
تُحدّث القسم المعني هنا **في نفس الـ commit**. لا تُنشئ ملف "حقيقة" جديد آخر — هذا الملف
هو الوحيد المعتمد؛ حدِّثه بدل استبداله.
