-- 0026_provider_kind — let a professional say what they actually are.
--
-- The app had exactly one word for its entire supply side: "مقاول". In Egypt
-- that reads as a building contractor specifically, and often as a labour
-- subcontractor. An engineer, an engineering office, or a finishing company
-- reading "سجّل كمقاول" hears a demotion — so the best-credentialled supply is
-- the most likely to bounce off signup, or to resent staying.
--
-- The fix every mature marketplace reached independently (Houzz, Thumbtack,
-- Angi): a neutral umbrella for the category, plus a self-declared identity per
-- account. The role stays one thing technically — this changes only what a
-- professional is called, never what they can do.
--
-- Also becomes a discovery filter. "Show me engineering offices" is a real
-- homeowner need the app cannot serve today.

alter table public.contractor_profiles
  add column if not exists provider_kind text not null default 'contractor';

-- Added separately so re-running is safe and the constraint can change without
-- touching the column.
alter table public.contractor_profiles
  drop constraint if exists contractor_profiles_provider_kind_check;

alter table public.contractor_profiles
  add constraint contractor_profiles_provider_kind_check
  check (provider_kind in (
    'contractor',          -- مقاول
    'engineer',            -- مهندس
    'engineering_office',  -- مكتب هندسي
    'finishing_company',   -- شركة تشطيبات
    'interior_designer',   -- مصمم داخلي
    'tradesman'            -- فني متخصص
  ));

-- Existing rows keep 'contractor' via the column default: it is what they
-- signed up as, and silently relabelling someone is worse than a stale label
-- they can correct. Onboarding and edit-profile now ask.

-- Supports filtering discovery by professional type.
create index if not exists contractor_profiles_provider_kind_idx
  on public.contractor_profiles (provider_kind);
