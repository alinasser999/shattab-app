-- 0003_contractors — extended contractor profile fields
-- Applied live mid-M2 (2026-05-16) after the base schema in 0001.
-- Covers columns used by ContractorListing (discovery) + portfolio features.

alter table public.contractor_profiles
  add column if not exists cover_photo_url text,
  add column if not exists headline text,
  add column if not exists projects_completed int not null default 0,
  add column if not exists response_rate int not null default 100;
