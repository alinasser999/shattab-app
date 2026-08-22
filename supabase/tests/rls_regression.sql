-- Lightweight database contract tests for `supabase test db`.
-- These assertions deliberately inspect grants, RLS enablement and policy
-- ownership rather than manufacturing user data in a shared environment.

begin;

select plan(27);

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

-- ── Hire-integrity contract (20260822090001) ──────────────────

select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'quotes'
      and policyname = 'homeowner_status'
      and cmd = 'UPDATE'
      and with_check like '%''declined''%'
      and with_check not like '%accepted%'
  ),
  'homeowners can only decline directly; accepting goes through the RPC'
);
select ok(
  exists (
    select 1 from pg_trigger
    where tgrelid = 'public.quotes'::regclass
      and tgname = 'only_rpc_accepts_quotes'
      and not tgisinternal
  ),
  'direct quote accepts are gated to the accept_quote RPC transaction'
);
select ok(
  position('hired_at is null' in pg_get_functiondef('public.accept_quote(uuid)'::regprocedure)) > 0,
  'accept_quote claims the brief atomically instead of read-then-write'
);

-- ── Suspension covers edits, not just inserts (20260822090002) ─

select ok(
  (select count(*) from pg_trigger
    where tgname = 'reject_if_suspended_update'
      and not tgisinternal
      and tgrelid in (
        'public.posts'::regclass,
        'public.post_comments'::regclass,
        'public.quotes'::regclass,
        'public.briefs'::regclass,
        'public.reviews'::regclass
      )) = 5,
  'suspended accounts cannot edit their existing content either'
);

-- ── Search escaping + catalogue expiry (20260822090003/05) ────

select ok(
  (select position(repeat(chr(92), 4) in pg_get_functiondef(p.oid)) = 0
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'discover_contractors_cursor'),
  'search cursor uses correct LIKE escaping literals (no doubled backslashes)'
);
select ok(
  (select position('plan_expires_at' in pg_get_functiondef(p.oid)) > 0
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'discover_contractors_cursor'),
  'catalogue emits subscription expiry so Pro badges honour it'
);
select ok(
  (select position('plan_expires_at' in pg_get_functiondef(p.oid)) > 0
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'list_sponsored_contractors'),
  'sponsored rail emits subscription expiry so Pro badges honour it'
);

select * from finish();
rollback;
