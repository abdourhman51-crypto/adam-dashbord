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
