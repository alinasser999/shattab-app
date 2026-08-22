-- Payment proofs and identity documents are append-only client submissions.
-- Keep their Storage policies aligned with the Flutter upload contract:
-- authenticated contractors may insert and read their own private objects,
-- but they cannot overwrite or mutate submitted evidence.

drop policy if exists "pp_insert_own" on storage.objects;
create policy "pp_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'payment-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid())
        and p.role = 'contractor'
    )
  );

drop policy if exists "pp_read_own" on storage.objects;
create policy "pp_read_own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'payment-proofs'
    and owner_id = (select auth.uid())::text
    and (storage.foldername(name))[1] = (select auth.uid())::text
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

drop policy if exists "vd_read_own" on storage.objects;
create policy "vd_read_own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'verification-docs'
    and owner_id = (select auth.uid())::text
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
