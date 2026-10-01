-- Trigger regression for source rows with different primary-key names.
-- Every fixture is synthetic and the transaction is rolled back at the end.

begin;

select plan(8);

create temporary table qa_homeowner_profile_sync_fixture (
  profile_id uuid primary key
) on commit drop;

insert into qa_homeowner_profile_sync_fixture(profile_id)
values (gen_random_uuid());

-- The auth.users bootstrap inserts public.profiles and fires the profile
-- projection trigger. That source row is keyed by id, not profile_id.
insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
select
  profile_id,
  'authenticated',
  'authenticated',
  profile_id::text || '@example.test',
  '',
  '{}'::jsonb,
  jsonb_build_object('role', 'homeowner', 'full_name', 'Synthetic QA fixture'),
  now(),
  now()
from qa_homeowner_profile_sync_fixture;

select is(
  (select profile_id from public.homeowner_public_profiles
   where profile_id = (select profile_id from qa_homeowner_profile_sync_fixture)),
  (select profile_id from qa_homeowner_profile_sync_fixture),
  'auth bootstrap resolves the profiles source key from id'
);

insert into public.homeowner_profiles(profile_id, city, district, renovation_interests)
select profile_id, 'Fixture City', 'Fixture District', array['kitchen']
from qa_homeowner_profile_sync_fixture;

select is(
  (select city from public.homeowner_public_profiles
   where profile_id = (select profile_id from qa_homeowner_profile_sync_fixture)),
  'Fixture City'::text,
  'homeowner-details INSERT synchronizes NEW.profile_id'
);

update public.homeowner_profiles
set city = 'Updated Fixture City'
where profile_id = (select profile_id from qa_homeowner_profile_sync_fixture);

select is(
  (select city from public.homeowner_public_profiles
   where profile_id = (select profile_id from qa_homeowner_profile_sync_fixture)),
  'Updated Fixture City'::text,
  'homeowner-details UPDATE synchronizes NEW.profile_id'
);

update public.profiles
set full_name = 'Updated Synthetic Fixture'
where id = (select profile_id from qa_homeowner_profile_sync_fixture);

select is(
  (select full_name from public.homeowner_public_profiles
   where profile_id = (select profile_id from qa_homeowner_profile_sync_fixture)),
  'Updated Synthetic Fixture'::text,
  'profiles UPDATE resolves NEW.id and refreshes the projection'
);

delete from public.homeowner_profiles
where profile_id = (select profile_id from qa_homeowner_profile_sync_fixture);

select ok(
  exists (
    select 1 from public.homeowner_public_profiles
    where profile_id = (select profile_id from qa_homeowner_profile_sync_fixture)
      and city is null
      and district is null
      and renovation_interests = '{}'
  ),
  'homeowner-details DELETE resolves OLD.profile_id and keeps the profile-only projection'
);

select ok(
  not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'homeowner_public_profiles'
      and column_name in ('phone', 'email', 'password')
  ),
  'the homeowner projection remains free of contact and credential columns'
);

select ok(
  (select prosecdef from pg_proc
   where oid = 'public.tg_sync_homeowner_public_profile()'::regprocedure),
  'the trigger function remains SECURITY DEFINER'
);

select is(
  (select count(*)::integer from pg_trigger
   where tgname in (
     'sync_homeowner_public_profile_on_profile',
     'sync_homeowner_public_profile_on_details'
   )
     and not tgisinternal
     and (
       (tgname = 'sync_homeowner_public_profile_on_profile'
        and tgrelid = 'public.profiles'::regclass)
       or
       (tgname = 'sync_homeowner_public_profile_on_details'
        and tgrelid = 'public.homeowner_profiles'::regclass)
     )),
  2,
  'the profile and homeowner-details trigger bindings remain installed'
);

select * from finish();
rollback;
