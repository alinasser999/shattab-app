-- 0014_payment_requests
-- Manual InstaPay (and future PSP) payment claims: contractor submits proof,
-- founder/admin approves via approve_payment_request() which grants the plan.
-- Applied live to project ajqdutehxpbbflzdovhw (2026-07-23). Idempotent.

create table if not exists public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  method text not null check (method in ('instapay','applepay','card')),
  purpose text not null default 'pro' check (purpose in ('pro','sponsored','boost')),
  plan_term text check (plan_term in ('monthly','annual')),
  amount_egp int not null,
  proof_path text,           -- storage path in payment-proofs bucket (instapay)
  reference_text text,       -- optional transfer reference from contractor
  status text not null default 'pending'
    check (status in ('pending','approved','rejected')),
  reject_reason text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create index if not exists payment_requests_contractor_idx
  on public.payment_requests(contractor_id);
create index if not exists payment_requests_status_idx
  on public.payment_requests(status);

alter table public.payment_requests enable row level security;

drop policy if exists "pr_read_own" on public.payment_requests;
create policy "pr_read_own" on public.payment_requests
  for select to public using (contractor_id = auth.uid());

drop policy if exists "pr_insert_own" on public.payment_requests;
create policy "pr_insert_own" on public.payment_requests
  for insert to public
  with check (contractor_id = auth.uid() and status = 'pending');
-- no client update/delete: only the definer functions below mutate status

-- ── private storage bucket for InstaPay proof screenshots ──
insert into storage.buckets (id, name, public)
values ('payment-proofs', 'payment-proofs', false)
on conflict (id) do nothing;

drop policy if exists "pp_insert_own" on storage.objects;
create policy "pp_insert_own" on storage.objects
  for insert to public
  with check (bucket_id = 'payment-proofs'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "pp_read_own" on storage.objects;
create policy "pp_read_own" on storage.objects
  for select to public
  using (bucket_id = 'payment-proofs'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- ── approve / reject (SECURITY DEFINER; callable from SQL editor / service role
--    only — NOT granted to authenticated, so no client can self-grant) ──
create or replace function public.approve_payment_request(p_request uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.payment_requests;
  v_start timestamptz := now();
  v_end timestamptz;
begin
  select * into r from public.payment_requests where id = p_request for update;
  if r.id is null then
    raise exception 'payment request % not found', p_request;
  end if;
  if r.status <> 'pending' then
    raise exception 'payment request % already %', p_request, r.status;
  end if;

  insert into public.payments (contractor_id, provider, provider_ref,
      amount_piastres, currency, purpose, status, period_start, period_end)
  values (r.contractor_id, r.method, 'pr_' || r.id::text, r.amount_egp * 100,
      'EGP', r.purpose, 'paid', v_start, null);

  if r.purpose = 'pro' then
    v_end := case when r.plan_term = 'annual'
                  then v_start + interval '1 year'
                  else v_start + interval '1 month' end;
    update public.contractor_profiles
      set plan = 'pro', plan_expires_at = v_end
      where profile_id = r.contractor_id;
    update public.payments set period_end = v_end
      where provider_ref = 'pr_' || r.id::text;
  elsif r.purpose = 'sponsored' then
    update public.contractor_profiles
      set sponsored_until =
          greatest(coalesce(sponsored_until, v_start), v_start) + interval '7 days'
      where profile_id = r.contractor_id;
  elsif r.purpose = 'boost' then
    update public.contractor_profiles
      set boost_until =
          greatest(coalesce(boost_until, v_start), v_start) + interval '7 days'
      where profile_id = r.contractor_id;
  end if;

  update public.payment_requests
    set status = 'approved', reviewed_at = now() where id = p_request;
end;
$$;

create or replace function public.reject_payment_request(p_request uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.payment_requests
    set status = 'rejected', reject_reason = p_reason, reviewed_at = now()
    where id = p_request and status = 'pending';
end;
$$;

revoke all on function public.approve_payment_request(uuid) from public;
revoke all on function public.reject_payment_request(uuid, text) from public;
