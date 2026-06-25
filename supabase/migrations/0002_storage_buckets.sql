-- Storage buckets + policies
-- Buckets are public-read so the Flutter app can show avatars/logos via plain URLs.

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('contractor-logos', 'contractor-logos', true)
on conflict (id) do nothing;

-- avatars policies
drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars owner write" on storage.objects;
create policy "avatars owner write"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "avatars owner update" on storage.objects;
create policy "avatars owner update"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- contractor-logos policies
drop policy if exists "contractor-logos public read" on storage.objects;
create policy "contractor-logos public read"
  on storage.objects for select
  using (bucket_id = 'contractor-logos');

drop policy if exists "contractor-logos owner write" on storage.objects;
create policy "contractor-logos owner write"
  on storage.objects for insert
  with check (
    bucket_id = 'contractor-logos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "contractor-logos owner update" on storage.objects;
create policy "contractor-logos owner update"
  on storage.objects for update
  using (
    bucket_id = 'contractor-logos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
