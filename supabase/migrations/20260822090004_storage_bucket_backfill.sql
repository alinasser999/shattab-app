-- Replayability backfill, storage half.
--
-- Three buckets were created live and never landed on disk, so the limit
-- update in 20260808012000 silently no-op'd on a fresh replay. This file
-- recreates them (guarded: no-op where they already exist, including
-- production) plus their owner-scoped object policies, mirrored from live
-- on 2026-08-22. contractor-covers deliberately has no delete policy on
-- live; mirrored as-is rather than "fixed" silently.
--
-- The portfolio_projects half of this backfill lives at the top of 0007,
-- which is the first file that references the table.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('brief-photos', 'brief-photos', true, 10485760,
   array['image/jpeg', 'image/png', 'image/webp']),
  ('contractor-covers', 'contractor-covers', true, 10485760,
   array['image/jpeg', 'image/png', 'image/webp']),
  ('portfolio-photos', 'portfolio-photos', true, 10485760,
   array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "brief-photos owner write" on storage.objects;
create policy "brief-photos owner write"
  on storage.objects for insert to public
  with check (
    bucket_id = 'brief-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "brief-photos owner select" on storage.objects;
create policy "brief-photos owner select"
  on storage.objects for select to public
  using (
    bucket_id = 'brief-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "brief-photos owner update" on storage.objects;
create policy "brief-photos owner update"
  on storage.objects for update to public
  using (
    bucket_id = 'brief-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "brief-photos owner delete" on storage.objects;
create policy "brief-photos owner delete"
  on storage.objects for delete to public
  using (
    bucket_id = 'brief-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "contractor-covers owner write" on storage.objects;
create policy "contractor-covers owner write"
  on storage.objects for insert to public
  with check (
    bucket_id = 'contractor-covers'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "contractor-covers owner select" on storage.objects;
create policy "contractor-covers owner select"
  on storage.objects for select to public
  using (
    bucket_id = 'contractor-covers'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "contractor-covers owner update" on storage.objects;
create policy "contractor-covers owner update"
  on storage.objects for update to public
  using (
    bucket_id = 'contractor-covers'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "portfolio-photos owner write" on storage.objects;
create policy "portfolio-photos owner write"
  on storage.objects for insert to public
  with check (
    bucket_id = 'portfolio-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "portfolio-photos owner select" on storage.objects;
create policy "portfolio-photos owner select"
  on storage.objects for select to public
  using (
    bucket_id = 'portfolio-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "portfolio-photos owner update" on storage.objects;
create policy "portfolio-photos owner update"
  on storage.objects for update to public
  using (
    bucket_id = 'portfolio-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );

drop policy if exists "portfolio-photos owner delete" on storage.objects;
create policy "portfolio-photos owner delete"
  on storage.objects for delete to public
  using (
    bucket_id = 'portfolio-photos'
    and (auth.uid())::text = (storage.foldername(name))[1]
  );
