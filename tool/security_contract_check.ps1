$ErrorActionPreference = 'Stop'

function Require-File($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing security contract input: $Path"
  }
}

function Require-Text($Text, $Pattern, $Message) {
  if ($Text -notmatch $Pattern) {
    throw $Message
  }
}

function Forbid-Text($Text, $Pattern, $Message) {
  if ($Text -match $Pattern) {
    throw $Message
  }
}

Require-File '.env.example'
Require-File 'lib/features/discovery/data/discovery_repository.dart'
Require-File 'lib/features/saved/data/saved_repository.dart'
Require-File 'lib/features/explore/data/post_repository.dart'
Require-File 'lib/features/auth/data/auth_repository.dart'
Require-File 'lib/features/billing/data/payment_repository.dart'
Require-File 'lib/features/verification/data/verification_repository.dart'
Require-File 'supabase/migrations/20260813182739_profile_authority_and_public_projections.sql'
Require-File 'supabase/migrations/20260813183739_public_projection_view_cleanup.sql'
Require-File 'supabase/migrations/20260813190710_billing_state_and_operational_indexes.sql'
Require-File 'supabase/migrations/20260814101000_server_owned_payment_submission.sql'
Require-File 'supabase/migrations/20260814102000_comment_rpc_search_path.sql'
Require-File 'supabase/migrations/20260814104000_payment_request_privileges.sql'
Require-File 'supabase/migrations/20260814105000_payment_proof_required.sql'
Require-File 'supabase/migrations/20260814106000_public_catalogue_data_quality.sql'
Require-File 'supabase/migrations/20260814107000_discovery_keyset_pagination.sql'
Require-File 'supabase/migrations/20260814108000_homeowner_contact_boundary.sql'
Require-File 'supabase/migrations/20260814109000_retire_legacy_catalogue_anon.sql'
Require-File 'supabase/migrations/20260814110000_verification_contractor_only.sql'
Require-File 'supabase/migrations/20260814111000_interaction_read_privacy.sql'
Require-File 'supabase/migrations/20260814111500_saved_contractors_schema_normalization.sql'
Require-File 'supabase/migrations/20260814112000_saved_contractors_keyset_pagination.sql'
Require-File 'supabase/migrations/20260814123000_special_pro_placement.sql'
Require-File 'supabase/migrations/20260820001650_private_submission_storage_hardening.sql'
Require-File 'supabase/migrations/20260803035018_admin_hardening_report_contract.sql'
Require-File 'supabase/migrations/20260820010358_admin_most_blocked_aggregate.sql'
Require-File 'supabase/tests/rls_regression.sql'

$envExample = Get-Content -Raw '.env.example'
Forbid-Text $envExample '(?m)^\s*SUPABASE_(SERVICE_ROLE|SECRET)_KEY\s*=' `
  'A service-role or secret Supabase key is present in .env.example.'

$discovery = Get-Content -Raw 'lib/features/discovery/data/discovery_repository.dart'
$saved = Get-Content -Raw 'lib/features/saved/data/saved_repository.dart'
$posts = Get-Content -Raw 'lib/features/explore/data/post_repository.dart'
$authRepository = Get-Content -Raw 'lib/features/auth/data/auth_repository.dart'
$paymentRepository = Get-Content -Raw 'lib/features/billing/data/payment_repository.dart'
$verificationRepository = Get-Content -Raw 'lib/features/verification/data/verification_repository.dart'
Forbid-Text $discovery 'from\(''profiles''\)' `
  'Discovery must use the narrow catalogue RPC, not direct profiles reads.'
Forbid-Text $saved 'from\(''profiles''\)' `
  'Saved professionals must use the narrow saved-contractors RPC.'
Forbid-Text $discovery 'select\([^)]*phone' `
  'Discovery catalogue selection must never include phone.'
Forbid-Text $saved 'select\([^)]*phone' `
  'Saved catalogue selection must never include phone.'
Require-Text $posts 'get_contractor_contact' `
  'Post detail contact access must remain an explicit detail RPC.'
Require-Text $authRepository 'get_homeowner_contact_for_brief' `
  'Homeowner contact access must remain brief-scoped.'
Forbid-Text $authRepository "from\('profiles'\).*phone" `
  'Auth repository must not read arbitrary profile phone numbers.'
Forbid-Text $paymentRepository 'upsert:\s*true' `
  'Unique payment proof uploads must not require Storage UPDATE permission.'
Forbid-Text $verificationRepository 'upsert:\s*true' `
  'Unique verification document uploads must not require Storage UPDATE permission.'

$authority = Get-Content -Raw 'supabase/migrations/20260813182739_profile_authority_and_public_projections.sql'
$cleanup = Get-Content -Raw 'supabase/migrations/20260813183739_public_projection_view_cleanup.sql'
$billing = Get-Content -Raw 'supabase/migrations/20260813190710_billing_state_and_operational_indexes.sql'
$payment = Get-Content -Raw 'supabase/migrations/20260814101000_server_owned_payment_submission.sql'
$comments = Get-Content -Raw 'supabase/migrations/20260814102000_comment_rpc_search_path.sql'
$paymentPrivileges = Get-Content -Raw 'supabase/migrations/20260814104000_payment_request_privileges.sql'
$paymentProof = Get-Content -Raw 'supabase/migrations/20260814105000_payment_proof_required.sql'
$catalogueQuality = Get-Content -Raw 'supabase/migrations/20260814106000_public_catalogue_data_quality.sql'
$discoveryCursor = Get-Content -Raw 'supabase/migrations/20260814107000_discovery_keyset_pagination.sql'
$homeownerContact = Get-Content -Raw 'supabase/migrations/20260814108000_homeowner_contact_boundary.sql'
$legacyCatalogue = Get-Content -Raw 'supabase/migrations/20260814109000_retire_legacy_catalogue_anon.sql'
$verificationAuthority = Get-Content -Raw 'supabase/migrations/20260814110000_verification_contractor_only.sql'
$interactionPrivacy = Get-Content -Raw 'supabase/migrations/20260814111000_interaction_read_privacy.sql'
$savedSchema = Get-Content -Raw 'supabase/migrations/20260814111500_saved_contractors_schema_normalization.sql'
$savedPagination = Get-Content -Raw 'supabase/migrations/20260814112000_saved_contractors_keyset_pagination.sql'
$specialPlacement = Get-Content -Raw 'supabase/migrations/20260814123000_special_pro_placement.sql'
$privateSubmissionStorage = Get-Content -Raw 'supabase/migrations/20260820001650_private_submission_storage_hardening.sql'
$adminHardening = Get-Content -Raw 'supabase/migrations/20260803035018_admin_hardening_report_contract.sql'
$adminMostBlocked = Get-Content -Raw 'supabase/migrations/20260820010358_admin_most_blocked_aggregate.sql'
$rlsRegression = Get-Content -Raw 'supabase/tests/rls_regression.sql'

Forbid-Text $authority 'from\s+public\.(contractor_directory|community_author_directory)' `
  'The authority migration references a removed public view.'
Forbid-Text $cleanup 'from\s+public\.(contractor_directory|community_author_directory)' `
  'The projection cleanup migration references a removed public view.'
Require-Text $authority 'role_locked_after_onboarding' `
  'Role authority lock is missing from the migration.'
Require-Text $authority 'get_contractor_contact' `
  'The authenticated contractor-contact boundary is missing.'
Require-Text $billing 'get_my_billing_state' `
  'The server-owned billing snapshot RPC is missing.'
Require-Text $billing 'grant execute on function public\.get_my_billing_state\(\) to authenticated' `
  'Billing state must be authenticated-only.'
Forbid-Text $billing 'grant execute on function public\.get_my_billing_state\(\) to anon' `
  'Billing state must never be callable by anon.'
Require-Text $payment 'revoke insert, update, delete on public\.payment_requests' `
  'Payment requests must not be directly mutable by the client.'
Require-Text $payment 'submit_payment_request' `
  'Server-owned payment submission RPC is missing.'
Require-Text $payment 'when .monthly. then 299' `
  'Monthly Pro price is not owned by the payment RPC.'
Require-Text $payment 'when .annual. then 2990' `
  'Annual Pro price is not owned by the payment RPC.'
Require-Text $comments 'set search_path = public, pg_temp' `
  'Public comment RPC must pin its search path.'
Require-Text $paymentPrivileges 'revoke all on table public\.payment_requests' `
  'Legacy payment table privileges must be removed.'
Require-Text $paymentProof 'payment proof is required' `
  'Payment submission must require proof server-side.'
Require-Text $paymentProof 'from storage\.objects' `
  'Payment submission must verify the uploaded proof exists.'
Forbid-Text $catalogueQuality "'response_rate'" `
  'Public discovery responses must not expose the legacy response-rate field.'
Require-Text $discoveryCursor 'create or replace function public\.list_contractors_cursor' `
  'Stable contractor catalogue pagination is missing.'
Require-Text $discoveryCursor 'create or replace function public\.discover_contractors_cursor' `
  'Stable contractor search pagination is missing.'
Require-Text $discoveryCursor 'set search_path = public, pg_temp' `
  'Discovery cursor RPCs must pin their search path.'
Require-Text $discoveryCursor 'revoke all on function public\.list_contractors_cursor' `
  'Discovery catalogue cursor privileges must be explicit.'
Require-Text $discoveryCursor 'revoke all on function public\.discover_contractors_cursor' `
  'Discovery search cursor privileges must be explicit.'
Require-Text $homeownerContact 'create or replace function public\.get_homeowner_contact_for_brief' `
  'Brief-scoped homeowner contact access is missing.'
Require-Text $homeownerContact 'set search_path = public, pg_temp' `
  'Homeowner contact RPC must pin its search path.'
Require-Text $homeownerContact 'b\.target_contractor_id = viewer\.id' `
  'Homeowner contact RPC must authorize the target contractor.'
Require-Text $homeownerContact 'grant execute on function public\.get_homeowner_contact_for_brief\(uuid\)\s+to authenticated' `
  'Homeowner contact RPC must be authenticated-only.'
Forbid-Text $homeownerContact 'grant execute on function public\.get_homeowner_contact_for_brief\(uuid\)\s+to anon' `
  'Homeowner contact RPC must never be callable by anon.'
Require-Text $legacyCatalogue 'revoke execute on function public\.discover_contractors' `
  'Legacy offset discovery must not remain anonymously callable.'
Require-Text $legacyCatalogue 'grant execute on function public\.discover_contractors[\s\S]*to authenticated' `
  'Legacy discovery compatibility must remain authenticated-only.'
Require-Text $verificationAuthority 'vr_insert_own' `
  'Verification requests must remain owner-scoped.'
Require-Text $verificationAuthority "p\.role = 'contractor'" `
  'Verification writes must require a contractor role.'
Require-Text $verificationAuthority "bucket_id = 'verification-docs'" `
  'Verification document storage must remain in the private bucket.'
Require-Text $interactionPrivacy 'revoke select on public\.post_likes' `
  'Post-like reads must not be globally exposed.'
Require-Text $interactionPrivacy 'create policy "likes_read_own"' `
  'Post-like reads must remain owner-scoped.'
Require-Text $interactionPrivacy 'revoke select on public\.post_comment_likes' `
  'Comment-like reads must not be globally exposed.'
Require-Text $interactionPrivacy 'create policy "comment_likes_read_own"' `
  'Comment-like reads must remain owner-scoped.'
Require-Text $savedPagination 'create or replace function public\.get_saved_contractors_cursor' `
  'Saved-professional cursor pagination is missing.'
Require-Text $savedSchema 'rename column created_at to saved_at' `
  'Saved-professional schema normalization is missing.'
Require-Text $savedPagination 'set search_path = public, pg_temp' `
  'Saved-professional pagination must pin its search path.'
Require-Text $savedPagination 'revoke all on function public\.get_saved_contractors_cursor' `
  'Saved-professional cursor privileges must be explicit.'
Require-Text $savedPagination 'grant execute on function public\.get_saved_contractors_cursor[\s\S]*to authenticated' `
  'Saved-professional cursor pagination must be authenticated-only.'
Forbid-Text $savedPagination 'grant execute on function public\.get_saved_contractors_cursor[\s\S]*to anon' `
  'Saved-professional cursor pagination must never be callable by anon.'
Require-Text $specialPlacement 'p_purpose = .sponsored.' `
  'Special Pro payment purpose is missing from the server-owned payment RPC.'
Require-Text $specialPlacement 'v_amount := 199' `
  'Special Pro pricing is not owned by the payment RPC.'
Require-Text $specialPlacement 'create or replace function public\.list_sponsored_contractors' `
  'Sponsored placement catalogue boundary is missing.'
Require-Text $specialPlacement 'is_sponsored.*true' `
  'Paid placement must be disclosed by the catalogue response.'
Require-Text $specialPlacement 'grant execute on function public\.list_sponsored_contractors[\s\S]*to anon, authenticated' `
  'Sponsored catalogue reads must be explicitly public-safe.'
Require-Text $privateSubmissionStorage 'create policy "pp_insert_own"[\s\S]*for insert to authenticated' `
  'Payment proof uploads must be authenticated-only.'
Require-Text $privateSubmissionStorage 'create policy "vd_insert_own"[\s\S]*for insert to authenticated' `
  'Verification document uploads must be authenticated-only.'
Require-Text $privateSubmissionStorage "p\.role = 'contractor'" `
  'Private submission uploads must require a contractor profile.'
Require-Text $privateSubmissionStorage 'owner_id = \(select auth\.uid\(\)\)::text' `
  'Private submission reads must be object-owner scoped.'
Forbid-Text $privateSubmissionStorage 'for update' `
  'Submitted payment and verification evidence must remain append-only.'
Require-Text $adminHardening 'create or replace function public\.admin_require_action' `
  'Admin action authorization guard is missing.'
Require-Text $adminHardening 'admin_require_action\(case when p_approve' `
  'Admin payment and verification actions must use the action guard.'
Require-Text $adminMostBlocked 'create or replace function public\.admin_most_blocked' `
  'Moderation block aggregation must be database-backed.'
Require-Text $adminMostBlocked 'having count\(\*\) >= 2' `
  'Moderation block aggregation must exclude single-user noise.'
Require-Text $rlsRegression 'select plan\(20\)' `
  'RLS regression coverage must keep its expected assertion count explicit.'
Require-Text $rlsRegression 'get_homeowner_contact_for_brief' `
  'RLS regression coverage must include the homeowner-contact boundary.'
Require-Text $rlsRegression 'submit_payment_request' `
  'RLS regression coverage must include the payment RPC boundary.'
Require-Text $rlsRegression 'admin_most_blocked' `
  'RLS regression coverage must include the admin moderation aggregate boundary.'

Write-Host 'Security contract checks passed.'
