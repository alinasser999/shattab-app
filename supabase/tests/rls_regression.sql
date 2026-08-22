-- Lightweight database contract tests for `supabase test db`.
-- These assertions deliberately inspect grants, RLS enablement and policy
-- ownership rather than manufacturing user data in a shared environment.

begin;

select plan(20);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'profiles keeps row-level security enabled'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
    and policyname = 'Update own profile'
  ),
  'profiles has an owner-scoped update policy'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'contractor_profiles'
    and policyname = 'Owner update contractor profile'
  ),
  'contractor profile writes remain owner-scoped'
);

select ok(
  not has_table_privilege('authenticated', 'public.payment_requests', 'INSERT'),
  'clients cannot insert payment requests directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.payment_requests', 'UPDATE'),
  'clients cannot update payment requests directly'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.submit_payment_request(text, text, text, text, text, text)'::regprocedure,
    'execute'
  ),
  'authenticated clients submit payments through the guarded RPC'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.submit_payment_request(text, text, text, text, text, text)'::regprocedure,
    'execute'
  ),
  'anonymous clients cannot submit payments'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.get_homeowner_contact_for_brief(uuid)'::regprocedure,
    'execute'
  ),
  'brief-scoped homeowner contact is available to signed-in contractors'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.get_homeowner_contact_for_brief(uuid)'::regprocedure,
    'execute'
  ),
  'brief-scoped homeowner contact is not anonymous'
);

select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'verification_requests'
      and policyname = 'vr_insert_own'
      and with_check like '%contractor%'
  ),
  'verification submissions require the contractor role'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'vd_insert_own'
  ),
  'verification documents remain owner-scoped in private storage'
);

select ok(
  not has_table_privilege('anon', 'public.post_likes', 'SELECT'),
  'anonymous clients cannot enumerate post likers'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'post_likes'
      and policyname = 'likes_read_own'
  ),
  'post-like reads are owner-scoped'
);
select ok(
  not has_table_privilege('anon', 'public.post_comment_likes', 'SELECT'),
  'anonymous clients cannot enumerate comment likers'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'post_comment_likes'
      and policyname = 'comment_likes_read_own'
  ),
  'comment-like reads are owner-scoped'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.get_saved_contractors_cursor(uuid, integer, timestamptz, uuid)'::regprocedure,
    'execute'
  ),
  'saved-professional pagination is available to signed-in homeowners'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.get_saved_contractors_cursor(uuid, integer, timestamptz, uuid)'::regprocedure,
    'execute'
  ),
  'saved-professional pagination is not anonymous'
);

select ok(
  to_regprocedure('public.admin_require_action(text)') is not null,
  'admin action authorization guard is installed'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.admin_most_blocked(integer)'::regprocedure,
    'execute'
  ),
  'moderation block aggregate is available to authenticated admins'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.admin_most_blocked(integer)'::regprocedure,
    'execute'
  ),
  'moderation block aggregate is not anonymous'
);

select * from finish();
rollback;
