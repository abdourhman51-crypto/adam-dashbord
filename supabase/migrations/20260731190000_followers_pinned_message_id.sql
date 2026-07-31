-- The pinned message is derived on every read, but Telegram needs the
-- message_id to edit it in place. Without this the banner could only ever be
-- created, never refreshed -- which is how it came to read "لم نسجّل شيئاً بعد"
-- permanently for every parent (adam-experience-principles.md F4).
--
-- Stores the HANDLE, not the content. The text stays derived, so there is
-- still no second copy of the truth to go stale.
-- Applied via Supabase migration `followers_pinned_message_id`.

alter table public.followers
  add column if not exists pinned_message_id bigint;

comment on column public.followers.pinned_message_id is
  'Telegram message_id of this parent''s pinned banner, so it can be edited in place. The handle only — the text is always derived from get_telegram_surface().';
