-- ============================================================================
-- Nightly Check-in Engine · state and timezones
-- ============================================================================
-- The nightly log is the measurement spine of the product (review A3).
-- The stage clock, the Mirror and the child record are all derived from it,
-- so this engine must be correct about three things the legacy workflow was not:
--
--   1. TIMEZONE. The old workflow hardcoded { DZ: 1, EG: 2, MA: 1 } as fixed
--      UTC offsets. VERIFIED WRONG: Egypt's real offset is +3 (DST reintroduced
--      2023), so Egyptian parents -- the largest market and the source of the
--      only real payment -- were being messaged at 20:00 local, not 21:00,
--      every night. IANA zones let Postgres handle this from its own tzdata.
--
--   2. REACH. Free support exists in every country (P8), so check-ins cannot be
--      limited to the three payment markets.
--
--   3. CONSENT. The old design would message nightly forever. Review A12
--      requires decay: quieten, then stop, never guilt.
--
-- Where the country is unknown we do NOT guess. Messaging at the wrong hour is
-- how ADAM becomes the thing she mutes. Those parents are surfaced in a view.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.country_timezone (
  code text PRIMARY KEY, iana_tz text NOT NULL, name_ar text
);

INSERT INTO public.country_timezone (code, iana_tz, name_ar) VALUES
  ('DZ','Africa/Algiers','الجزائر'),   ('EG','Africa/Cairo','مصر'),
  ('MA','Africa/Casablanca','المغرب'), ('TN','Africa/Tunis','تونس'),
  ('LY','Africa/Tripoli','ليبيا'),     ('SD','Africa/Khartoum','السودان'),
  ('MR','Africa/Nouakchott','موريتانيا'),
  ('SA','Asia/Riyadh','السعودية'),     ('AE','Asia/Dubai','الإمارات'),
  ('KW','Asia/Kuwait','الكويت'),       ('QA','Asia/Qatar','قطر'),
  ('BH','Asia/Bahrain','البحرين'),     ('OM','Asia/Muscat','عُمان'),
  ('YE','Asia/Aden','اليمن'),          ('IQ','Asia/Baghdad','العراق'),
  ('SY','Asia/Damascus','سوريا'),      ('JO','Asia/Amman','الأردن'),
  ('LB','Asia/Beirut','لبنان'),        ('PS','Asia/Hebron','فلسطين'),
  ('TR','Europe/Istanbul','تركيا'),    ('FR','Europe/Paris','فرنسا'),
  ('DE','Europe/Berlin','ألمانيا'),    ('GB','Europe/London','بريطانيا'),
  ('ES','Europe/Madrid','إسبانيا'),    ('IT','Europe/Rome','إيطاليا'),
  ('BE','Europe/Brussels','بلجيكا'),   ('NL','Europe/Amsterdam','هولندا'),
  ('SE','Europe/Stockholm','السويد'),  ('US','America/New_York','أمريكا'),
  ('CA','America/Toronto','كندا')
ON CONFLICT (code) DO NOTHING;

COMMENT ON TABLE public.country_timezone IS
  'IANA zone per country so Postgres tzdata handles DST. Replaces legacy '
  'hardcoded offsets that were verified wrong for Egypt by a full hour.';

CREATE TABLE IF NOT EXISTS public.checkin_state (
  parent_id           uuid PRIMARY KEY REFERENCES public.followers(id) ON DELETE CASCADE,
  cadence             text NOT NULL DEFAULT 'nightly' CHECK (cadence IN ('nightly','weekly','stopped')),
  local_hour          smallint NOT NULL DEFAULT 21 CHECK (local_hour BETWEEN 0 AND 23),
  consecutive_ignored integer NOT NULL DEFAULT 0 CHECK (consecutive_ignored >= 0),
  last_sent_date      date,
  last_sent_at        timestamptz,
  last_responded_at   timestamptz,
  cadence_changed_at  timestamptz,
  paused_until        date,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_checkin_state_active
  ON public.checkin_state (cadence) WHERE cadence <> 'stopped';
CREATE TRIGGER trg_checkin_state_updated BEFORE UPDATE ON public.checkin_state
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.checkin_state IS
  'Per-parent cadence and consent decay (review A12). Five ignored nightly '
  'prompts drop to weekly; four more ignored weekly prompts stop proactive '
  'messages. Chat stays open forever; any reply restores the full rhythm. '
  'No streaks, no guilt, no re-engagement sequences.';

INSERT INTO public.checkin_state (parent_id, cadence, last_sent_date)
SELECT f.id, CASE WHEN f.checkin_opt_in THEN 'nightly' ELSE 'stopped' END, f.last_checkin_sent_date
FROM public.followers f WHERE f.checkin_opt_in IS NOT NULL
ON CONFLICT (parent_id) DO NOTHING;

CREATE OR REPLACE VIEW public.v_checkin_unschedulable
WITH (security_invoker = true) AS
SELECT f.id AS parent_id, f.platform_user_id,
       COALESCE(NULLIF(btrim(f.country),''),'(none)') AS country, f.first_seen::date AS joined
FROM public.followers f
LEFT JOIN public.country_timezone ct ON ct.code = upper(btrim(f.country))
WHERE ct.code IS NULL;

COMMENT ON VIEW public.v_checkin_unschedulable IS
  'Parents whose country maps to no timezone, so their local evening is '
  'unknown. Deliberately NOT messaged: sending at the wrong hour is how ADAM '
  'becomes the thing a parent mutes. Surfaced so the gap is closed with data.';

ALTER TABLE public.checkin_state    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.country_timezone ENABLE ROW LEVEL SECURITY;
CREATE POLICY service_all  ON public.checkin_state    FOR ALL    TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_read ON public.country_timezone FOR SELECT TO service_role USING (true);
GRANT SELECT, INSERT, UPDATE ON public.checkin_state TO service_role;
GRANT SELECT ON public.country_timezone, public.v_checkin_unschedulable TO service_role;
