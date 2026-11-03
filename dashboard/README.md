# Adam dashboard

Arabic (RTL) dashboard for Nour, the DM agent, and for the adamvoices.site sales pages.
Next.js 15 (App Router, server components), Tailwind 4, Recharts.

## Pages

| Path | What it shows |
|---|---|
| `/` | Messages, Nour replies, reply time, buying signals, offers, pending receipts, sales; daily and hourly charts; stages, problems, topics, objections, products, countries |
| `/followers` | Follower profiles built by Nour, with stage filters and search |
| `/payments` | CCP receipts approved from Telegram, delivery status, card sales |
| `/site` | Site funnel (visitors → engaged → price → checkout → bought), sources, tools, countries |

## Data

- **Nour:** Supabase project `adam-noor-inbox`, function `noor_dashboard_stats(p_days)`, served by the edge function
  `noor-dashboard` (source in `docs/workflows/nour/supabase/`). The dashboard sends `x-dash-token`.
- **Site:** the n8n data table `hodn_events`, read through the `hodn-report` webhook and aggregated in `lib/site.ts`
  with the same rules as the Telegram report.

The dashboard holds no database key. It only reads aggregated JSON.

## Setup

1. In Supabase (adam-noor-inbox) → Edge Functions → Secrets, add `DASHBOARD_TOKEN` (a long random string).
2. In Vercel (project `adam-dashbord`) → Environment Variables, add `NOOR_DASH_TOKEN` with the same value
   (type Sensitive, Production and Preview).
3. Optional: `DASHBOARD_PASSWORD`. Vercel login already protects `*.vercel.app`; set this before adding a public domain.

Local run: `cp .env.example .env.local`, fill in the token, then `npm install && npm run dev`.
