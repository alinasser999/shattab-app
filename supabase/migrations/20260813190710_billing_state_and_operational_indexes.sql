-- Phase 2: expose one authenticated, read-only billing snapshot to the app.
-- The client must never infer subscription state from a payment request alone:
-- only the server-approved contractor plan is authoritative.

alter table public.payment_requests
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists set_payment_requests_updated_at on public.payment_requests;
create trigger set_payment_requests_updated_at
  before update on public.payment_requests
  for each row execute function public.tg_set_updated_at();

create index if not exists payment_requests_contractor_status_created_idx
  on public.payment_requests (contractor_id, status, created_at desc);

create index if not exists payments_contractor_created_idx
  on public.payments (contractor_id, created_at desc);

create or replace function public.get_my_billing_state()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'plan', coalesce(
      (select cp.plan
       from public.contractor_profiles cp
       where cp.profile_id = (select auth.uid())),
      'free'
    ),
    'plan_expires_at', (
      select cp.plan_expires_at
      from public.contractor_profiles cp
      where cp.profile_id = (select auth.uid())
    ),
    'latest_request', coalesce(
      (
        select jsonb_build_object(
          'id', pr.id,
          'status', pr.status,
          'purpose', pr.purpose,
          'plan_term', pr.plan_term,
          'amount_egp', pr.amount_egp,
          'reject_reason', pr.reject_reason,
          'created_at', pr.created_at,
          'reviewed_at', pr.reviewed_at
        )
        from public.payment_requests pr
        where pr.contractor_id = (select auth.uid())
        order by pr.created_at desc, pr.id desc
        limit 1
      ),
      '{}'::jsonb
    ),
    'latest_payment', coalesce(
      (
        select jsonb_build_object(
          'id', p.id,
          'status', p.status,
          'purpose', p.purpose,
          'amount_piastres', p.amount_piastres,
          'period_end', p.period_end,
          'created_at', p.created_at
        )
        from public.payments p
        where p.contractor_id = (select auth.uid())
        order by p.created_at desc, p.id desc
        limit 1
      ),
      '{}'::jsonb
    )
  )
  where (select auth.uid()) is not null;
$$;

revoke all on function public.get_my_billing_state() from public, anon, authenticated;
grant execute on function public.get_my_billing_state() to authenticated;

comment on function public.get_my_billing_state() is
  'Authenticated read-only billing snapshot. Payment approval remains server/admin-owned.';
