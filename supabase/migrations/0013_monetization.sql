-- 0013_monetization
-- Monetization Phase 1: tier columns, payments audit table, lead-gate on quotes,
-- and a self-upgrade guard. Idempotent; safe to re-run.

-- 1. tier columns on contractor_profiles
alter table public.contractor_profiles
  add column if not exists plan text not null default 'free'
    check (plan in ('free','pro')),
  add column if not exists plan_expires_at timestamptz,
  add column if not exists sponsored_until timestamptz,
  add column if not exists boost_until timestamptz,
  add column if not exists verified boolean not null default false;

-- 2. payments audit table (idempotent on provider_ref)
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null default 'paymob',
  provider_ref text unique,
  amount_piastres int not null,
  currency text not null default 'EGP',
  purpose text not null check (purpose in ('pro','sponsored','boost')),
  status text not null default 'pending' check (status in ('pending','paid','failed')),
  period_start timestamptz,
  period_end timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists payments_contractor_idx on public.payments(contractor_id);

alter table public.payments enable row level security;
-- contractor reads own payments; NO client insert/update/delete -> only service role writes
drop policy if exists "contractor_read_own_payments" on public.payments;
create policy "contractor_read_own_payments" on public.payments
  for select to public using (contractor_id = auth.uid());

-- 3. self-upgrade guard: block a normal user from writing billing columns.
--    Paymob webhook runs as service_role -> auth.role()='service_role' -> allowed.
create or replace function public.tg_block_selfupgrade()
returns trigger language plpgsql as $$
begin
  if auth.role() <> 'service_role' then
    if new.plan            is distinct from old.plan
    or new.plan_expires_at is distinct from old.plan_expires_at
    or new.sponsored_until is distinct from old.sponsored_until
    or new.boost_until     is distinct from old.boost_until
    or new.verified        is distinct from old.verified then
      raise exception 'billing fields are not user-writable';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists block_selfupgrade on public.contractor_profiles;
create trigger block_selfupgrade
  before update on public.contractor_profiles
  for each row execute function public.tg_block_selfupgrade();

-- 4. lead-gate: only active-Pro contractors may insert a quote
drop policy if exists "contractor_insert_own" on public.quotes;
create policy "contractor_insert_own" on public.quotes
  for insert to public
  with check (
    contractor_id = auth.uid()
    and status = 'sent'
    and exists (
      select 1 from public.contractor_profiles cp
      where cp.profile_id = auth.uid()
        and cp.plan = 'pro'
        and cp.plan_expires_at > now()
    )
  );