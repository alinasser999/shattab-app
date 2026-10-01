-- Add the new professional identity without changing the application role or
-- rewriting historical provider values.
alter table public.contractor_profiles
  drop constraint if exists contractor_profiles_provider_kind_check;

alter table public.contractor_profiles
  add constraint contractor_profiles_provider_kind_check
  check (provider_kind in (
    'contractor',
    'engineer',
    'engineering_office',
    'finishing_company',
    'interior_designer',
    'specialized_provider',
    'tradesman'
  ));
