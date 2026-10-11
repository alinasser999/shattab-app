'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { currentAdmin, supabaseServer } from './supabase/server';
import type { DoneCode, ErrorCode } from './i18n';

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

type Result = { ok: true } | { ok: false; code: ErrorCode };

const RETURN_PATHS = new Set(['/users', '/contractors', '/payments', '/moderation']);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const MAX_REASON_LENGTH = 2000;

async function callRpc(fn: string, args: Record<string, unknown>): Promise<Result> {
  // Re-checked on every mutation. The layout checked once when the page
  // rendered; a form posted twenty minutes later from a stale tab has to be
  // checked again, because admin rights may have been revoked in between.
  const admin = await currentAdmin();
  if (!admin) return { ok: false, code: 'session_expired' };

  const supabase = await supabaseServer();
  const { error } = await supabase.rpc(fn, args);
  if (!error) return { ok: true };
  return { ok: false, code: humanise(error.message) };
}

/** The database raises short machine codes; operators need sentences. */
function humanise(raw: string): ErrorCode {
  if (raw.includes('not_authorized')) return 'not_authorized';
  if (raw.includes('not_allowed')) return 'not_allowed';
  if (raw.includes('cannot_suspend_admin')) return 'cannot_suspend_admin';
  if (raw.includes('already approved')) return 'already_approved';
  if (raw.includes('already rejected')) return 'already_rejected';
  if (raw.includes('not found')) return 'not_found';
  if (raw.includes('reason_required')) return 'reason_required';
  if (raw.includes('reason_too_long')) return 'reason_too_long';
  if (raw.includes('invalid plan days')) return 'invalid_plan_days';
  if (raw.includes('unsupported_report_target')) {
    return 'unsupported_report_target';
  }
  if (raw.includes('billing fields are not user-writable')) {
    return 'billing_guard';
  }
  return 'generic';
}

/**
 * Sends the operator back where they were, carrying the outcome.
 * `path` is always a literal supplied by a page component, never user input, so
 * there is no open-redirect surface here.
 */
function returnPath(raw: string, fallback: string): string {
  // Hidden form fields are client-controlled. Keep redirects inside the
  // console even when a request is forged outside the rendered page.
  return RETURN_PATHS.has(raw) ? raw : fallback;
}

function finish(path: string, result: Result, done: DoneCode, params?: { days?: number }): never {
  const safePath = returnPath(path, '/users');
  revalidatePath(safePath);
  const query = result.ok
    ? `?done=${encodeURIComponent(done)}${params?.days === undefined ? '' : `&days=${params.days}`}`
    : `?error=${encodeURIComponent(result.code)}`;
  redirect(`${safePath}${query}`);
}

function str(form: FormData, key: string): string {
  const value = form.get(key);
  return typeof value === 'string' ? value.trim() : '';
}

function uuid(form: FormData, key: string, path: string): string {
  const value = str(form, key);
  if (!UUID.test(value)) fail(path, 'invalid_id');
  return value;
}

function boundedReason(form: FormData, key: string, path: string): string {
  const value = str(form, key);
  if (value.length > MAX_REASON_LENGTH) {
    fail(path, 'reason_length');
  }
  return value;
}

function fail(path: string, code: ErrorCode): never {
  redirect(`${returnPath(path, '/users')}?error=${encodeURIComponent(code)}${code === 'reason_length' ? `&max=${MAX_REASON_LENGTH}` : ''}`);
}

/* ── users ────────────────────────────────────────────────── */

export async function suspendUser(form: FormData) {
  const path = str(form, 'path') || '/users';
  const reason = boundedReason(form, 'reason', path);

  // A suspension with no stated reason is unreviewable later, by you or by the
  // person appealing it. Required here rather than in the database so the
  // message can be a sentence instead of a constraint violation.
  if (!reason) fail(path, 'give_suspend_reason');

  finish(
    path,
    await callRpc('admin_set_suspended', {
      p_user: uuid(form, 'user_id', path),
      p_suspended: true,
      p_reason: reason,
    }),
    'user_suspended',
  );
}

export async function unsuspendUser(form: FormData) {
  const path = str(form, 'path') || '/users';
  finish(
    path,
    await callRpc('admin_set_suspended', {
      p_user: uuid(form, 'user_id', path),
      p_suspended: false,
      p_reason: null,
    }),
    'user_unsuspended',
  );
}

/* ── professionals ────────────────────────────────────────── */

export async function setVerified(form: FormData) {
  const path = str(form, 'path') || '/contractors';
  const verified = str(form, 'verified') === 'true';
  finish(
    path,
    await callRpc('admin_set_verified', {
      p_contractor: uuid(form, 'contractor_id', path),
      p_verified: verified,
      p_reason: boundedReason(form, 'reason', path) || null,
    }),
    verified ? 'verified' : 'unverified',
  );
}

export async function setPlan(form: FormData) {
  const path = str(form, 'path') || '/contractors';
  const plan = str(form, 'plan');
  const days = Number.parseInt(str(form, 'days') || '30', 10);

  if (plan !== 'free' && plan !== 'pro') fail(path, 'invalid_plan');
  if (!Number.isFinite(days) || days < 0 || days > 3650) {
    fail(path, 'days_range');
  }

  finish(
    path,
    await callRpc('admin_set_plan', {
      p_contractor: uuid(form, 'contractor_id', path),
      p_plan: plan,
      p_days: days,
    }),
    plan === 'pro' ? 'plan_pro' : 'plan_free',
    plan === 'pro' ? { days } : undefined,
  );
}

export async function reviewVerification(form: FormData) {
  const path = str(form, 'path') || '/contractors';
  const approve = str(form, 'approve') === 'true';
  const reason = boundedReason(form, 'reason', path);

  // A rejection the contractor cannot understand becomes a support ticket.
  if (!approve && !reason) fail(path, 'give_verification_reason');

  finish(
    path,
    await callRpc('admin_review_verification', {
      p_request: uuid(form, 'request_id', path),
      p_approve: approve,
      p_reason: reason || null,
    }),
    approve ? 'verification_approved' : 'verification_rejected',
  );
}

/* ── payments ─────────────────────────────────────────────── */

export async function reviewPayment(form: FormData) {
  const path = str(form, 'path') || '/payments';
  const approve = str(form, 'approve') === 'true';
  const reason = boundedReason(form, 'reason', path);

  if (!approve && !reason) fail(path, 'give_payment_reason');

  finish(
    path,
    await callRpc('admin_review_payment', {
      p_request: uuid(form, 'request_id', path),
      p_approve: approve,
      p_reason: reason || null,
    }),
    approve ? 'payment_approved' : 'payment_rejected',
  );
}

/* ── moderation ───────────────────────────────────────────── */

export async function resolveReport(form: FormData) {
  const path = str(form, 'path') || '/moderation';
  const action = str(form, 'action');
  const note = boundedReason(form, 'note', path);

  if (!['dismiss', 'remove_content', 'suspend_author'].includes(action)) {
    fail(path, 'unknown_moderation');
  }
  if (action !== 'dismiss' && !note) {
    fail(path, 'give_decision_note');
  }

  finish(
    path,
    await callRpc('admin_resolve_report', {
      p_report: uuid(form, 'report_id', path),
      p_action: action,
      p_note: note || null,
    }),
    action === 'dismiss'
      ? 'report_dismissed'
      : action === 'remove_content'
        ? 'content_removed'
        : 'content_removed_suspended',
  );
}

export async function deletePost(form: FormData) {
  const path = str(form, 'path') || '/moderation';
  const reason = boundedReason(form, 'reason', path);

  if (!reason) fail(path, 'give_post_reason');

  finish(
    path,
    await callRpc('admin_delete_post', { p_post: uuid(form, 'post_id', path), p_reason: reason }),
    'post_removed',
  );
}
