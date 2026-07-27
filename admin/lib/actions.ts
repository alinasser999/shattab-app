'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { currentAdmin, supabaseServer } from './supabase/server';

/**
 * Every privileged mutation in the console.
 *
 * These are thin on purpose: validate shape, call the RPC, report the outcome.
 * All authorisation and all business rules live in Postgres, so this file cannot
 * be the place a rule is enforced — and therefore cannot be the place one is
 * forgotten. If a call here succeeded that should not have, the bug is in the
 * migration, not here.
 *
 * Outcomes are surfaced by redirecting back with ?done= or ?error=, which keeps
 * the whole authenticated surface free of client-side JavaScript.
 */

type Result = { ok: true } | { ok: false; message: string };

async function callRpc(fn: string, args: Record<string, unknown>): Promise<Result> {
  // Re-checked on every mutation. The layout checked once when the page
  // rendered; a form posted twenty minutes later from a stale tab has to be
  // checked again, because admin rights may have been revoked in between.
  const admin = await currentAdmin();
  if (!admin) return { ok: false, message: 'Your admin session has expired. Sign in again.' };

  const supabase = await supabaseServer();
  const { error } = await supabase.rpc(fn, args);
  if (!error) return { ok: true };
  return { ok: false, message: humanise(error.message) };
}

/** The database raises short machine codes; operators need sentences. */
function humanise(raw: string): string {
  if (raw.includes('not_authorized')) return 'You are not an admin, or your session has expired.';
  if (raw.includes('cannot_suspend_admin')) return 'Admins cannot be suspended from the console.';
  if (raw.includes('already approved')) return 'Already approved by someone else. Reload the page.';
  if (raw.includes('already rejected')) return 'Already rejected by someone else. Reload the page.';
  if (raw.includes('not found')) return 'That record no longer exists. Reload the page.';
  if (raw.includes('billing fields are not user-writable')) {
    return 'Blocked by the billing guard, which means this account is missing admin rights in the database.';
  }
  return raw;
}

/**
 * Sends the operator back where they were, carrying the outcome.
 * `path` is always a literal supplied by a page component, never user input, so
 * there is no open-redirect surface here.
 */
function finish(path: string, result: Result, done: string): never {
  revalidatePath(path);
  const query = result.ok
    ? `?done=${encodeURIComponent(done)}`
    : `?error=${encodeURIComponent(result.message)}`;
  redirect(`${path}${query}`);
}

function str(form: FormData, key: string): string {
  const value = form.get(key);
  return typeof value === 'string' ? value.trim() : '';
}

function fail(path: string, message: string): never {
  redirect(`${path}?error=${encodeURIComponent(message)}`);
}

/* ── users ────────────────────────────────────────────────── */

export async function suspendUser(form: FormData) {
  const path = str(form, 'path') || '/users';
  const reason = str(form, 'reason');

  // A suspension with no stated reason is unreviewable later, by you or by the
  // person appealing it. Required here rather than in the database so the
  // message can be a sentence instead of a constraint violation.
  if (!reason) fail(path, 'Give a reason before suspending an account.');

  finish(
    path,
    await callRpc('admin_set_suspended', {
      p_user: str(form, 'user_id'),
      p_suspended: true,
      p_reason: reason,
    }),
    'Account suspended.',
  );
}

export async function unsuspendUser(form: FormData) {
  const path = str(form, 'path') || '/users';
  finish(
    path,
    await callRpc('admin_set_suspended', {
      p_user: str(form, 'user_id'),
      p_suspended: false,
      p_reason: null,
    }),
    'Suspension lifted.',
  );
}

/* ── professionals ────────────────────────────────────────── */

export async function setVerified(form: FormData) {
  const path = str(form, 'path') || '/contractors';
  const verified = str(form, 'verified') === 'true';
  finish(
    path,
    await callRpc('admin_set_verified', {
      p_contractor: str(form, 'contractor_id'),
      p_verified: verified,
      p_reason: str(form, 'reason') || null,
    }),
    verified ? 'Verified badge granted.' : 'Verified badge removed.',
  );
}

export async function setPlan(form: FormData) {
  const path = str(form, 'path') || '/contractors';
  const plan = str(form, 'plan');
  const days = Number.parseInt(str(form, 'days') || '30', 10);

  if (plan !== 'free' && plan !== 'pro') fail(path, 'Plan must be free or pro.');
  if (!Number.isFinite(days) || days < 0 || days > 3650) {
    fail(path, 'Days must be between 0 and 3650.');
  }

  finish(
    path,
    await callRpc('admin_set_plan', {
      p_contractor: str(form, 'contractor_id'),
      p_plan: plan,
      p_days: days,
    }),
    plan === 'pro' ? `Pro granted for ${days} days.` : 'Moved to the free plan.',
  );
}

export async function reviewVerification(form: FormData) {
  const path = str(form, 'path') || '/contractors';
  const approve = str(form, 'approve') === 'true';
  const reason = str(form, 'reason');

  // A rejection the contractor cannot understand becomes a support ticket.
  if (!approve && !reason) fail(path, 'Give a reason when rejecting a verification.');

  finish(
    path,
    await callRpc('admin_review_verification', {
      p_request: str(form, 'request_id'),
      p_approve: approve,
      p_reason: reason || null,
    }),
    approve ? 'Verification approved.' : 'Verification rejected.',
  );
}

/* ── payments ─────────────────────────────────────────────── */

export async function reviewPayment(form: FormData) {
  const path = str(form, 'path') || '/payments';
  const approve = str(form, 'approve') === 'true';
  const reason = str(form, 'reason');

  if (!approve && !reason) fail(path, 'Give a reason when rejecting a payment.');

  finish(
    path,
    await callRpc('admin_review_payment', {
      p_request: str(form, 'request_id'),
      p_approve: approve,
      p_reason: reason || null,
    }),
    approve ? 'Payment approved and the plan applied.' : 'Payment rejected.',
  );
}

/* ── moderation ───────────────────────────────────────────── */

export async function resolveReport(form: FormData) {
  const path = str(form, 'path') || '/moderation';
  const action = str(form, 'action');

  if (!['dismiss', 'remove_content', 'suspend_author'].includes(action)) {
    fail(path, 'Unknown moderation action.');
  }

  finish(
    path,
    await callRpc('admin_resolve_report', {
      p_report: str(form, 'report_id'),
      p_action: action,
      p_note: str(form, 'note') || null,
    }),
    action === 'dismiss'
      ? 'Report dismissed.'
      : action === 'remove_content'
        ? 'Content removed.'
        : 'Content removed and the author suspended.',
  );
}

export async function deletePost(form: FormData) {
  const path = str(form, 'path') || '/moderation';
  const reason = str(form, 'reason');

  if (!reason) fail(path, 'Give a reason before removing a post.');

  finish(
    path,
    await callRpc('admin_delete_post', { p_post: str(form, 'post_id'), p_reason: reason }),
    'Post removed.',
  );
}
