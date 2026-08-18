# مركز قيادة آدم — Adam Mission Control

لوحة تحكم داخلية عربية (RTL) لمنصة **آدم** للمرافقة التربوية، مبنية بـ Next.js 15 ومتصلة مباشرة ببيانات Supabase الحية. تتطلب تسجيل دخول — داخلية لمعز فقط.

## التشغيل محلياً

```bash
npm install
cp .env.example .env.local   # واملأ القيم الثلاث
npm run dev
```

## متغيرات البيئة (`.env.local`)

| المتغير | الاستخدام |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | رابط مشروع Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | مفتاح anon — يُستخدم فقط لتسجيل الدخول (Supabase Auth) |
| `SUPABASE_SERVICE_ROLE_KEY` | **سرّي**. يُقرأ حصراً على الخادم (`lib/supabase/admin.ts`) لكل استعلامات البيانات الحقيقية. لا يصل أبداً لأي كود يعمل على المتصفح. |

## الصفحات

| المسار | الغرض |
|---|---|
| `/login` | تسجيل الدخول (Supabase Auth) |
| `/` | نظرة عامة: KPIs + قمع التحويل |
| `/stages` | صحة الرحلات المدفوعة (`v_stage_progress`) |
| `/customers`, `/customers/[id]` | CRM: قائمة + بحث/فلترة + صفحة تفصيلية بإجراءات RPC حقيقية (تفعيل/إلغاء/تمديد/حذف) ونافذة محادثة |
| `/patterns` | صندوق مراجعة الأنماط (`get_patterns_pending_review` / `handle_pattern_review_tap`) |
| `/insights` | فهم العميل — تحليلات منتج مجمّعة بالكامل، بلا أي ربط باسم عميل |

## البنية

- **Next.js 15 (App Router) + TypeScript**، كل الصفحات Server Components بتصيير ديناميكي كامل (`dynamic = "force-dynamic"`) — لا بيانات مخبوءة قديمة.
- **Tailwind CSS 4** — نظام ألوان آدم (أخضر الغابة `#1F4D2E` + ذهبي `#D4A017`) عبر متغيرات CSS في `app/globals.css`، وضع فاتح/داكن كامل.
- **تسجيل الدخول**: كوكيز HttpOnly مبنية مباشرة على `@supabase/supabase-js` (`lib/supabase/session.ts`) وتُحمى كل الصفحات عبر `middleware.ts`.
- **طبقة البيانات**: `lib/supabase/admin.ts` (عميل service_role، سيرفر فقط) + `lib/queries/*` (استعلامات نمطية لكل صفحة، تستبعد حسابي الاختبار دائماً) + `lib/actions/*` (Server Actions تُغلّف الدوال الحقيقية بقاعدة البيانات).
- **الأمان والخصوصية**: حقول `light_memory` خلف زر "إظهار"، `parent_strain.reason` مخفي افتراضياً، صفحة `/insights` بلا أي معرّف عميل فردي.
