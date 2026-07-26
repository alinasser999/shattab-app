-- 0015_verification_requests
-- Free "Verified" badge, earned via document review. Contractor submits ID +
-- (optional) trade-licence photos → pending row → founder approves via
-- approve_verification_request() (service role) which flips
-- contractor_profiles.verified = true. Client can only ever create a pending
-- request; it can NEVER self-verify (no grant on the approve function, and the
-- billing-columns trigger already blocks direct writes to `verified`).
-- Mirrors 0014_payment_requests. Idempotent.

create table if not exists public.verification_requests (
  id uuid primary key default gen_random_uuid(),
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  doc_paths text[] not null default '{}',   -- storage paths in verification-docs
  note text,                                -- optional message from contractor
  status text not null default 'pending'
    check (status in ('pending','approved','rejected')),
  reject_reason text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create index if not exists verification_requests_contractor_idx
  on public.verification_requests(contractor_id);
create index if not exists verification_requests_status_idx
  on public.verification_requests(status);

alter table public.verification_requests enable row level security;

drop policy if exists "vr_read_own" on public.verification_requests;
create policy "vr_read_own" on public.verification_requests
  for select to public using (contractor_id = auth.uid());

drop policy if exists "vr_insert_own" on public.verification_requests;
create policy "vr_insert_own" on public.verification_requests
  for insert to public
  with check (contractor_id = auth.uid() and status = 'pending');
-- no client update/delete: only the definer functions below mutate status

-- ── private storage bucket for verification documents ──
insert into storage.buckets (id, name, public)
values ('verification-docs', 'verification-docs', false)
on conflict (id) do nothing;

drop policy if exists "vd_insert_own" on storage.objects;
create policy "vd_insert_own" on storage.objects
  for insert to public
  with check (bucket_id = 'verification-docs'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "vd_read_own" on storage.objects;
create policy "vd_read_own" on storage.objects
  for select to public
  using (bucket_id = 'verification-docs'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- ── approve / reject (SECURITY DEFINER; service role / SQL editor only —
--    NOT granted to authenticated, so no client can self-verify) ──
create or replace function public.approve_verification_request(p_request uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.verification_requests;
begin
  select * into r from public.verification_requests where id = p_request for update;
  if r.id is null then
    raise exception 'verification request % not found', p_request;
  end if;
  if r.status <> 'pending' then
    raise exception 'verification request % already %', p_request, r.status;
  end if;

  update public.contractor_profiles
    set verified = true
    where profile_id = r.contractor_id;

  update public.verification_requests
    set status = 'approved', reviewed_at = now() where id = p_request;
end;
$$;

create or replace function public.reject_verification_request(p_request uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.verification_requests
    set status = 'rejected', reject_reason = p_reason, reviewed_at = now()
    where id = p_request and status = 'pending';
end;
$$;

revoke all on function public.approve_verification_request(uuid) from public;
revoke all on function public.reject_verification_request(uuid, text) from public;
