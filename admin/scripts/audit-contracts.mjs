import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

const adminRoot = path.resolve(import.meta.dirname, '..');
const repoRoot = path.resolve(adminRoot, '..');

async function text(file) {
  return readFile(path.join(repoRoot, file), 'utf8');
}

const adminActions = await readFile(path.join(adminRoot, 'lib/actions.ts'), 'utf8');
const moderationPage = await readFile(
  path.join(adminRoot, 'app', '(console)', 'moderation', 'page.tsx'),
  'utf8',
);
const flutterModeration = await text('lib/features/moderation/data/moderation_repository.dart');
const hardeningMigration = await readFile(
  path.join(repoRoot, 'supabase', 'migrations', '20260803035018_admin_hardening_report_contract.sql'),
  'utf8',
);

const sourceFiles = [
  await readFile(path.join(adminRoot, 'middleware.ts'), 'utf8'),
  await readFile(path.join(adminRoot, 'lib', 'supabase', 'server.ts'), 'utf8'),
  adminActions,
];

for (const source of sourceFiles) {
  assert(!source.includes('service_role'), 'Admin source must never mention a service-role key.');
  assert(!source.includes('SUPABASE_SERVICE_ROLE_KEY'), 'Admin source must never use a service-role env var.');
}

for (const value of ['post', 'comment', 'profile', 'brief', 'review']) {
  assert(flutterModeration.includes(`enum ReportTarget { post, comment, profile, brief, review }`));
  assert(moderationPage.includes(`${value}:`), `Admin moderation labels are missing ${value}.`);
}

for (const value of ['spam', 'scam', 'offensive', 'sexual', 'violence', 'impersonation', 'other']) {
  assert(flutterModeration.includes(`  ${value},`), `Flutter report reasons are missing ${value}.`);
}

assert(adminActions.includes('const RETURN_PATHS'), 'Server actions must define an allowlisted return path set.');
assert(adminActions.includes('returnPath(path'), 'Server actions must sanitize form-controlled redirects.');
assert(hardeningMigration.includes('admin_require_action'), 'Database action authorization guard is missing.');
assert(hardeningMigration.includes("raise exception 'reason_required'"), 'Database reason validation is missing.');
assert(hardeningMigration.includes("r.target_type = 'profile'"), 'Database report handling is missing profile reports.');

console.log('Admin contract audit passed: security boundary, redirect guard, and report enums are aligned.');
