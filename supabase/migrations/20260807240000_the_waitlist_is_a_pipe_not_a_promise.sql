-- قائمة الانتظار — a pipe, laid now, collecting from the first day of production
--
-- Founder's instruction: «مش نحوس اليوم نعرف وش اكثر بلاد مدعومة، نحوس نخدم
-- المسار والانابيب بش كي ندخلو مرحلة الانتاج يبدا النظام يجمع». So: build the
-- path, switch nothing on, collect nothing today.
--
-- ── The commercial flow, end to end ───────────────────────────────────────────
--
--   parent wants the journey
--     → country buttons + the honest explanation           (already built)
--     → country recorded by record_country()               (already built)
--         supported    → فريق آدم take it from there       (already built)
--         unsupported  → «سجّلوني» → join_waitlist()       ← this file
--
-- The interesting decision is what «سجّلوني» is allowed to touch.
--
-- ── Why `waitlist` is set by the tap and never inferred ───────────────────────
--
-- The obvious shortcut is to have record_country() set `waitlist = true` for
-- everyone whose country is unsupported. It is wrong, and quietly so:
-- `M2 - Classify Track` routes on that column — `waitlist = true` sends a parent
-- down the waitlist track instead of the ordinary conversation. Inferring it
-- from geography would silently change the experience of every parent in an
-- unsupported country, none of whom asked for anything.
--
-- So `waitlist` stays what its name says: a person asked to be told. It is set
-- by one tap, and only that tap.
--
-- ── And why the country is asked FOR the waitlist, not assumed ────────────────
--
-- A parent can reach «سجّلوني» before ADAM knows where they are. Recording the
-- signup without a country would produce exactly the number the founder does not
-- want — demand with no address. join_waitlist() therefore reports
-- `needs_country`, and the caller asks with the same country buttons already
-- built, then calls again. One flow, no second set of buttons to maintain.

begin;

-- The register. `waitlist` records that they asked; `waitlist_at` records when,
-- which is what turns a flag into a demand signal you can read a trend from.
alter table public.followers
  add column if not exists waitlist_at timestamptz;

comment on column public.followers.waitlist_at is
  'When the parent asked to be told their country had arrived. Set only by '
  'join_waitlist(), never inferred from where they happen to be.';

create or replace function public.join_waitlist(p_parent_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_state jsonb;
begin
  v_state := public.country_state(p_parent_id);
  if v_state is null then
    return jsonb_build_object('joined', false, 'reason', 'no_such_parent');
  end if;

  -- No address, no signup. A waitlist that cannot say WHERE is the one number
  -- this whole feature exists to produce.
  if (v_state->>'state') = 'unknown' then
    return jsonb_build_object('joined', false, 'reason', 'needs_country') || v_state;
  end if;

  -- Already sold here. Joining would be recording demand that is already met,
  -- and telling a parent to wait for something they can have today.
  if (v_state->>'state') = 'supported' then
    return jsonb_build_object('joined', false, 'reason', 'already_supported') || v_state;
  end if;

  -- Idempotent: tapping twice is not two people. The first timestamp is kept,
  -- because when they asked is the fact worth having.
  update public.followers
     set waitlist    = true,
         waitlist_at = coalesce(waitlist_at, now())
   where id = p_parent_id;

  return jsonb_build_object('joined', true) || v_state;
end $fn$;

comment on function public.join_waitlist(uuid) is
  'Records that a parent in an unsupported country asked to be told when ADAM '
  'reaches them. Refuses without a country (needs_country) — demand with no '
  'address is the one thing this must not produce — and refuses where we '
  'already sell. Idempotent: the first timestamp survives.';

revoke execute on function public.join_waitlist(uuid) from public, anon, authenticated;
grant execute on function public.join_waitlist(uuid) to service_role;

-- The demand, per country, highest first. Nothing reads this today; it is the
-- end of the pipe, waiting for production to start filling it.
create or replace view public.v_waitlist_demand as
select f.country                                as country,
       coalesce(ct.name_ar, f.country)          as name_ar,
       count(*)                                 as waiting,
       min(f.waitlist_at)                       as first_asked,
       max(f.waitlist_at)                       as last_asked,
       count(*) filter (where f.waitlist_at > now() - interval '30 days') as asked_last_30d
from public.followers f
left join public.country_timezone ct on ct.code = f.country
where f.waitlist
  and f.country is not null
  -- A country that has since been switched on is no longer demand; it is a
  -- backlog of people to go and tell.
  and not exists (select 1 from public.supported_countries sc
                   where sc.code = f.country and coalesce(sc.is_active, false))
group by f.country, ct.name_ar
order by count(*) desc, min(f.waitlist_at);

comment on view public.v_waitlist_demand is
  'Which unsupported countries have people waiting, and since when. The answer '
  'to «which market do we find a payment method for next».';

-- Countries switched on since parents asked: the list of people owed the news
-- they signed up for. Separate from demand on purpose — one is a decision, the
-- other is a debt.
create or replace view public.v_waitlist_owed_the_news as
select f.id as parent_id, f.platform_user_id, f.country, sc.name_ar, f.waitlist_at
from public.followers f
join public.supported_countries sc
  on sc.code = f.country and coalesce(sc.is_active, false)
where f.waitlist
order by f.waitlist_at;

comment on view public.v_waitlist_owed_the_news is
  'Parents who asked to be told when their country arrived, and whose country '
  'now has. They were promised a message. This is the list.';

-- ── The two moments ───────────────────────────────────────────────────────────
--
-- Honesty as the conversion tool, per the founder: we do not pretend a date we
-- do not have, and we say plainly that the free product is not the thing being
-- waited for — it is already theirs.

insert into public.conversation_moments
  (key, tier, category, max_lines, body_ar, buttons, buttons_forbidden, requires_commerce, note)
values
  ('menu_waitlist_joined', 'fixed', 'reference', 12,
   '🌿 سجّلناكم.' || chr(10) || chr(10) ||
   'حين يصل آدم إلى بلدكم، تصلكم رسالة منّي. لن أعدكم بموعد لا أعرفه —' || chr(10) ||
   'نحن نفتح بلداً حين نستطيع أن نستقبل الدفع فيه بطريقة تناسب أهله، لا قبل ذلك.' || chr(10) || chr(10) ||
   'وحتى ذلك الحين لا ينقصكم شيء ممّا نفعله معاً:' || chr(10) ||
   'احكوا لي ما حدث، وأعطيكم خطوة صغيرة، وأسألكم مساءً كيف مرّت.' || chr(10) ||
   'هذا مجاني، ويبقى مجانياً، وليس نسخة مصغّرة من شيء آخر.',
   jsonb_build_array(jsonb_build_object('cb','other','label','💬 نكمل الآن')),
   false, false,
   'After join_waitlist. No date is promised because none is known, and the free '
   'product is named as complete in itself rather than as a trial of the paid one.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      category = excluded.category, max_lines = excluded.max_lines, note = excluded.note;

insert into public.conversation_moments
  (key, tier, category, max_lines, body_ar, buttons, buttons_forbidden, requires_commerce, note)
values
  ('menu_waitlist_ask_country', 'fixed', 'reference', 10,
   '🌍 من أيّ بلد أنتم؟' || chr(10) || chr(10) ||
   'أسأل لسببين: حتى أعرف متى أخبركم أنّ آدم وصل إليكم،' || chr(10) ||
   'وحتى أعرف أيّ البلدان فيها أهل ينتظرون — فنبدأ بها.',
   jsonb_build_array(jsonb_build_object('cb','other','label','↩︎ ليس الآن')),
   false, false,
   'Asked before join_waitlist when country_state is unknown. The country '
   'buttons themselves are appended by the caller — the same set the purchase '
   'flow already uses, so there is one list to maintain, not two.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      category = excluded.category, max_lines = excluded.max_lines, note = excluded.note;

commit;
