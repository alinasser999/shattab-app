-- Focused security regression for the homeowner-only brief budget note.
-- All identities and briefs are synthetic; the transaction is rolled back.

begin;
SET LOCAL search_path = pg_catalog, extensions, public, auth, storage, pg_temp;

select plan(26);

create temporary table qa_brief_private_fixture (
  homeowner_id uuid not null,
  other_homeowner_id uuid not null,
  contractor_id uuid not null,
  homeowner_brief_id uuid not null,
  legacy_insert_brief_id uuid not null,
  legacy_update_brief_id uuid not null
) on commit drop;

insert into qa_brief_private_fixture
values (
  gen_random_uuid(),
  gen_random_uuid(),
  gen_random_uuid(),
  gen_random_uuid(),
  gen_random_uuid(),
  gen_random_uuid()
);

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
select fixture_user.id,
       'authenticated',
       'authenticated',
       fixture_user.id::text || '@example.test',
       '',
       '{}'::jsonb,
       jsonb_build_object('role', fixture_user.profile_role),
       now(),
       now()
from qa_brief_private_fixture as fixture
cross join lateral (
  values
    (fixture.homeowner_id, 'homeowner'::text),
    (fixture.other_homeowner_id, 'homeowner'::text),
    (fixture.contractor_id, 'contractor'::text)
) as fixture_user(id, profile_role);

select is(
  auth.uid(),
  null::uuid,
  'no authenticated user claim is set before test-runner role preparation'
);

-- The maintained auth trigger intentionally creates every new account as a
-- homeowner, ignoring authorization-bearing user metadata. Prepare this
-- synthetic contractor as the database test runner, before setting JWT claims
-- or changing roles. The profile role trigger has a trusted early return when
-- auth.uid() is null, so normal trigger execution remains enabled.
update public.profiles as profile
set role = 'contractor'
from qa_brief_private_fixture as fixture
where profile.id = fixture.contractor_id;

select is(
  (select profile.role
   from public.profiles as profile
   join qa_brief_private_fixture as fixture
     on fixture.contractor_id = profile.id),
  'contractor'::text,
  'database test runner prepares the synthetic contractor profile explicitly'
);

insert into public.briefs (
  id,
  homeowner_id,
  apartment_type,
  city,
  district,
  work_description
)
select fixture.homeowner_brief_id,
       fixture.homeowner_id,
       'two_bedroom',
       'Fixture City',
       'Fixture District',
       'Synthetic private-field security fixture'
from qa_brief_private_fixture as fixture;

insert into public.briefs (
  id,
  homeowner_id,
  apartment_type,
  city,
  district,
  work_description
)
select fixture.legacy_update_brief_id,
       fixture.homeowner_id,
       'two_bedroom',
       'Fixture City',
       'Fixture District',
       'Synthetic legacy update fixture'
from qa_brief_private_fixture as fixture;

select set_config('qa.brief_owner_id', homeowner_id::text, true),
       set_config('qa.brief_other_homeowner_id', other_homeowner_id::text, true),
       set_config('qa.brief_contractor_id', contractor_id::text, true),
       set_config('qa.brief_owner_brief_id', homeowner_brief_id::text, true),
       set_config('qa.brief_legacy_insert_id', legacy_insert_brief_id::text, true),
       set_config('qa.brief_legacy_update_id', legacy_update_brief_id::text, true)
from qa_brief_private_fixture;

select ok(
  (select relrowsecurity
   from pg_class
   where oid = 'public.brief_private_fields'::regclass),
  'private brief fields have row-level security enabled'
);

select ok(
  (select relforcerowsecurity
   from pg_class
   where oid = 'public.brief_private_fields'::regclass),
  'private brief fields force row-level security'
);

select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'brief_private_fields'
      and policyname = 'brief_private_fields_homeowner_only'
      and roles = array['authenticated']::name[]
      and cmd = 'ALL'
      and qual like '%auth.uid%'
      and qual like '%homeowner%'
      and with_check like '%auth.uid%'
      and with_check like '%homeowner%'
  ),
  'private table policy scopes both access and writes to the authenticated homeowner owner'
);

select ok(
  not has_table_privilege('anon', 'public.brief_private_fields', 'SELECT')
  and not has_table_privilege('anon', 'public.brief_private_fields', 'INSERT')
  and not has_table_privilege('anon', 'public.brief_private_fields', 'UPDATE')
  and not has_table_privilege('anon', 'public.brief_private_fields', 'DELETE'),
  'anonymous role has no direct private-table privileges'
);

select ok(
  not has_table_privilege('authenticated', 'public.brief_private_fields', 'SELECT')
  and not has_table_privilege('authenticated', 'public.brief_private_fields', 'INSERT')
  and not has_table_privilege('authenticated', 'public.brief_private_fields', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.brief_private_fields', 'DELETE'),
  'authenticated role has no direct private-table privileges'
);

select ok(
  not exists (
    select 1
    from pg_class as class_entry
    cross join lateral aclexplode(
      coalesce(class_entry.relacl, acldefault('r', class_entry.relowner))
    ) as privilege
    where class_entry.oid = 'public.brief_private_fields'::regclass
      and privilege.grantee = 0
      and privilege.privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
  ),
  'PUBLIC has no direct private-table privileges'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.save_homeowner_brief_private_fields(uuid, text)'::regprocedure,
    'EXECUTE'
  )
  and has_function_privilege(
    'authenticated',
    'public.save_homeowner_brief_private_fields_for_publish(uuid, text, text)'::regprocedure,
    'EXECUTE'
  )
  and has_function_privilege(
    'authenticated',
    'public.get_homeowner_brief_private_fields(uuid)'::regprocedure,
    'EXECUTE'
  ),
  'authenticated users can call the three ownership-checked private-field RPCs'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.save_homeowner_brief_private_fields(uuid, text)'::regprocedure,
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.save_homeowner_brief_private_fields_for_publish(uuid, text, text)'::regprocedure,
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.get_homeowner_brief_private_fields(uuid)'::regprocedure,
    'EXECUTE'
  ),
  'anonymous users cannot execute the private-field RPCs'
);

select ok(
  not exists (
    select 1
    from pg_proc as proc
    cross join lateral aclexplode(
      coalesce(proc.proacl, acldefault('f', proc.proowner))
    ) as privilege
    where proc.oid in (
      'public.save_homeowner_brief_private_fields(uuid, text)'::regprocedure,
      'public.save_homeowner_brief_private_fields_for_publish(uuid, text, text)'::regprocedure,
      'public.get_homeowner_brief_private_fields(uuid)'::regprocedure
    )
      and privilege.grantee = 0
      and privilege.privilege_type = 'EXECUTE'
  ),
  'PUBLIC cannot execute the private-field RPCs'
);

-- ACL denial was asserted above. Grant SELECT only within this fixture
-- transaction so the following role checks isolate RLS row visibility.
-- ROLLBACK restores the original ACL after the suite completes.
grant select on table public.brief_private_fields to authenticated;

select set_config('request.jwt.claim.sub', current_setting('qa.brief_owner_id'), true),
       set_config(
         'request.jwt.claims',
         jsonb_build_object(
           'sub', current_setting('qa.brief_owner_id'),
           'role', 'authenticated'
         )::text,
         true
       );
set local role authenticated;

select is(
  public.save_homeowner_brief_private_fields_for_publish(
    current_setting('qa.brief_owner_brief_id')::uuid,
    'Fixture budget note',
    repeat('a', 64)
  ),
  current_setting('qa.brief_owner_brief_id')::uuid,
  'homeowner can save the private note through the publish RPC'
);

select is(
  public.save_homeowner_brief_private_fields(
    current_setting('qa.brief_owner_brief_id')::uuid,
    'Fixture budget note'
  ),
  current_setting('qa.brief_owner_brief_id')::uuid,
  'homeowner can save the same note through the compatibility RPC'
);

select is(
  (select fields.budget_note
   from public.get_homeowner_brief_private_fields(
     current_setting('qa.brief_owner_brief_id')::uuid
   ) as fields),
  'Fixture budget note'::text,
  'homeowner can read their own private note through the protected RPC'
);

select is(
  (select count(*)::integer
   from public.brief_private_fields
   where brief_id = current_setting('qa.brief_owner_brief_id')::uuid),
  1,
  'row-level security lets the owner see their private row with temporary SELECT privilege'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  current_setting('qa.brief_other_homeowner_id'),
  true
),
set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub', current_setting('qa.brief_other_homeowner_id'),
    'role', 'authenticated'
  )::text,
  true
);
set local role authenticated;

select throws_ok(
  'select * from public.get_homeowner_brief_private_fields(current_setting(''qa.brief_owner_brief_id'')::uuid)',
  '42501',
  null,
  'another homeowner cannot read the owner private note'
);

select is(
  (select count(*)::integer
   from public.brief_private_fields
   where brief_id = current_setting('qa.brief_owner_brief_id')::uuid),
  0,
  'row-level security hides the owner private row from another homeowner'
);

select throws_ok(
  'select public.save_homeowner_brief_private_fields(current_setting(''qa.brief_owner_brief_id'')::uuid, ''unauthorized note'')',
  '42501',
  null,
  'another homeowner cannot overwrite the owner private note'
);

reset role;
select set_config('request.jwt.claim.sub', '', true),
       set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

select throws_ok(
  'select * from public.get_homeowner_brief_private_fields(current_setting(''qa.brief_owner_brief_id'')::uuid)',
  '42501',
  null,
  'anonymous callers cannot execute the private-field RPC'
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  current_setting('qa.brief_contractor_id'),
  true
),
set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub', current_setting('qa.brief_contractor_id'),
    'role', 'authenticated'
  )::text,
  true
);
set local role authenticated;

select throws_ok(
  'select * from public.get_homeowner_brief_private_fields(current_setting(''qa.brief_owner_brief_id'')::uuid)',
  '42501',
  null,
  'a signed-in contractor cannot read a homeowner private note'
);

select is(
  (select count(*)::integer
   from public.brief_private_fields
   where brief_id = current_setting('qa.brief_owner_brief_id')::uuid),
  0,
  'row-level security hides homeowner private rows from contractors'
);

reset role;
select set_config('request.jwt.claim.sub', current_setting('qa.brief_owner_id'), true),
       set_config(
         'request.jwt.claims',
         jsonb_build_object(
           'sub', current_setting('qa.brief_owner_id'),
           'role', 'authenticated'
         )::text,
         true
       );
set local role authenticated;

insert into public.briefs (
  id,
  homeowner_id,
  apartment_type,
  city,
  district,
  work_description,
  budget_note
)
values (
  current_setting('qa.brief_legacy_insert_id')::uuid,
  current_setting('qa.brief_owner_id')::uuid,
  'two_bedroom',
  'Fixture City',
  'Fixture District',
  'Synthetic legacy insert fixture',
  'Legacy insert note'
);

reset role;
select is(
  (select budget_note
   from public.briefs
   where id = current_setting('qa.brief_legacy_insert_id')::uuid),
  null::text,
  'legacy insert leaves no budget note on the public brief row'
);

select is(
  (select budget_note
   from public.brief_private_fields
   where brief_id = current_setting('qa.brief_legacy_insert_id')::uuid),
  'Legacy insert note'::text,
  'legacy insert copies the note to the private row'
);

select set_config('request.jwt.claim.sub', current_setting('qa.brief_owner_id'), true),
       set_config(
         'request.jwt.claims',
         jsonb_build_object(
           'sub', current_setting('qa.brief_owner_id'),
           'role', 'authenticated'
         )::text,
         true
       );
set local role authenticated;

update public.briefs
set budget_note = 'Legacy update note'
where id = current_setting('qa.brief_legacy_update_id')::uuid;

reset role;
select is(
  (select budget_note
   from public.briefs
   where id = current_setting('qa.brief_legacy_update_id')::uuid),
  null::text,
  'legacy update leaves no budget note on the public brief row'
);

select is(
  (select budget_note
   from public.brief_private_fields
   where brief_id = current_setting('qa.brief_legacy_update_id')::uuid),
  'Legacy update note'::text,
  'legacy update copies the note to the private row'
);

select set_config(
  'request.jwt.claim.sub',
  current_setting('qa.brief_other_homeowner_id'),
  true
),
set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub', current_setting('qa.brief_other_homeowner_id'),
    'role', 'authenticated'
  )::text,
  true
);
set local role authenticated;

select throws_ok(
  'select * from public.get_homeowner_brief_private_fields(current_setting(''qa.brief_legacy_update_id'')::uuid)',
  '42501',
  null,
  'another user cannot recover the legacy-updated private note'
);

reset role;
select * from finish();
rollback;
