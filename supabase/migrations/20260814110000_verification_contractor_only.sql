-- Verification is a contractor supply-side workflow. Enforce that at the
-- database boundary instead of relying on the onboarding UI to hide the form.

drop policy if exists "vr_insert_own" on public.verification_requests;
create policy "vr_insert_own" on public.verification_requests
  for insert to authenticated
  with check (
    contractor_id = (select auth.uid())
    and status = 'pending'
    and exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid())
        and p.role = 'contractor'
    )
  );

drop policy if exists "vd_insert_own" on storage.objects;
create policy "vd_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid())
        and p.role = 'contractor'
    )
  );
