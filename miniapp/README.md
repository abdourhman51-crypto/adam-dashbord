# آدم — Mini App

Telegram Mini App للوالدين، قراءة فقط. مشروع Next.js مستقل عن `dashboard/` بنفس الريبو — انظر [`DESIGN.md`](./DESIGN.md) لنظام التصميم.

## التشغيل محلياً

```bash
npm install
cp .env.example .env.local   # عبّئ القيم
npm run dev
```

## متغيرات البيئة

| المتغير | من وين |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | مشروع Supabase `aajqbmjasnbwwyvgrlzy` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API (سرّي، سيرفر فقط) |
| `TELEGRAM_BOT_TOKEN` | BotFather (سرّي، سيرفر فقط — للتحقق من initData) |

أزرار "التحدث مع آدم" و"المرافقة الكاملة" لا تحتاج أي اسم مستخدم للبوت —
تستخدم `WebApp.close()` لإرجاع الوالد لنفس محادثة البوت التي فتح منها
التطبيق المصغّر، وهذا يعمل دائماً بلا أي إعداد إضافي.

## تسجيله عند BotFather كـ Mini App

بعد النشر على Vercel، أرسل لـ [@BotFather](https://t.me/BotFather):

1. `/mybots` → اختر بوت آدم.
2. `Bot Settings` → `Menu Button` → `Configure Menu Button` → ألصق رابط Vercel.
3. أو لربطه كـ Mini App كامل: `/newapp` واتبع الخطوات، بنفس رابط Vercel.

## البنية

- `app/api/*` — Route Handlers، كل واحد يتحقق من `initData` أولاً (`lib/telegram/verify.ts`) قبل أي استعلام.
- `lib/supabase/admin.ts` — عميل `service_role`، سيرفر فقط.
- `app/{timeline,wall,child,journey}` — الشاشات الأربع.
- `components/` — عناصر التصميم المشتركة (زجاجية، تنقّل، حالات فارغة/تحميل).

## الاستثناء الوحيد لقاعدة "قراءة فقط"

`app/api/reply/route.ts` — يكتب فقط على سجل اليوم الحالي (وفق توقيت عائلة الوالد) عبر `record_harvest_answer` RPC، وفقط لو كان سؤال مساء اليوم مُرسلاً وغير مُجاب عليه بعد. قائمة قيم مقفلة (`succeeded` / `tried_failed` / `no_chance`) — بلا أي حقل نص حر، ونفس صرامة التحقق من initData قبل أي استدعاء.

## قدرات تفاعلية إضافية

- **الشجرة الحية** — ورقة ذهبية لكل ليلة هادئة، تكبير/تحريك حقيقي بالمس. `components/LivingTree.tsx`، `app/api/tree/route.ts`.
- **اللحظة الحرجة الحية** (شاشة رحلتي) — تقرأ `situations.window_start/window_end` بتوقيت عائلة الوالد الحقيقي (`country_timezone`)، وتتابع الوقت حياً بالعميل. `lib/supabase/criticalWindow.server.ts`، `components/CriticalWindowIndicator.tsx`.
- **بطاقة إنجاز قابلة للمشاركة** — عند بلوغ محطة تتابع (3/5/7/10/14/21/29 ليلة)، احتفال بصري + بطاقة PNG مُولَّدة بـ Canvas + مشاركة عبر Web Share API (أو تحميل كبديل). `lib/streak.ts`، `lib/shareCard.ts`، `components/AchievementCelebration.tsx`.
- **تجربة المستخدم المجاني** — يفحص `followers.funnel_stage` عبر `resolveParent`؛ جدار الإنجاز وشاشة رحلتي يُطمَسان جزئياً/كلياً بدعوة فضول لا ضغط بيع (`lib/upsell.ts`، `components/UpsellButton.tsx`).
