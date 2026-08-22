import Link from 'next/link';
import { supabaseServer } from '@/lib/supabase/server';
import { setPlan, setVerified, suspendUser, unsuspendUser } from '@/lib/actions';
import {
  Avatar, Badge, Button, ErrorState, Input, Label, Panel, Select, Textarea,
} from '@/components/ui';
import { PROVIDER_KIND_LABEL, fmtAgo, fmtDateTime, fmtNum, fmtPhone } from '@/lib/format';

/**
 * Detail panel for one account.
 *
 * A side panel driven by ?user=<id>, not a modal. Modals are usually laziness:
 * this way the table stays visible and usable beside it, the view is
 * linkable, and Back closes it. It is also a plain server component, so opening
 * an account ships no JavaScript at all.
 */

type Detail = {
  profile: {
    id: string; role: string; full_name: string | null; phone: string | null;
    onboarding_complete: boolean; suspended_at: string | null;
    suspended_reason: string | null; created_at: string;
  };
  auth: { created_at: string; last_sign_in_at: string | null; phone_confirmed_at: string | null } | null;
  contractor: {
    business_name: string | null; verified: boolean; plan: string;
    plan_expires_at: string | null; provider_kind: string; rating_avg: number | null;
    rating_count: number; projects_completed: number; specialties: string[] | null;
    service_areas: string[] | null;
  } | null;
  homeowner: { city: string | null; district: string | null; apartment_type: string | null } | null;
  stats: Record<string, number>;
  audit: Array<{
    id: number; action: string; created_at: string; meta: Record<string, unknown>;
  }>;
};

export async function UserDrawer({ userId, backHref }: { userId?: string; backHref: string }) {
  if (!userId) {
    return (
      <Panel className="hidden h-fit p-5 xl:block">
        <p className="text-sm font-medium text-ink">No account selected</p>
        <p className="mt-1 text-sm text-ink-3">
          Select a row to see its full history, its activity, and the controls for suspending or
          verifying it.
        </p>
      </Panel>
    );
  }

  const supabase = await supabaseServer();
  const { data, error } = await supabase.rpc('admin_user_detail', { p_user: userId });

  if (error || !data) {
    return (
      <Panel className="h-fit">
        <ErrorState what="Could not load this account." />
      </Panel>
    );
  }

  const d = data as Detail;
  const p = d.profile;
  const { data: adminLevel, error: adminLevelError } = await supabase.rpc('admin_level');
  // Plan changes are owner-only. Unknown levels (including a missing
  // hardening migration) must not fall through to write-capable UI.
  const canManagePlan = !adminLevelError && adminLevel === 'owner';
  const suspended = Boolean(p.suspended_at);
  const isPro = d.contractor?.plan === 'pro' && (d.contractor.plan_expires_at ?? '') > new Date().toISOString();

  return (
    <Panel className="enter h-fit">
      <header className="flex items-start gap-3 border-b border-line px-4 py-4">
        <Avatar name={p.full_name} size={38} />
        <div className="min-w-0 flex-1">
          <h2 dir="auto" className="truncate text-md font-semibold text-ink">
            {p.full_name?.trim() || 'Unnamed account'}
          </h2>
          <p className="text-xs text-ink-3" dir="ltr">
            {fmtPhone(p.phone)}
          </p>
          <div className="mt-1.5 flex flex-wrap gap-1.5">
            <Badge tone={p.role === 'contractor' ? 'accent' : 'info'}>
              {p.role === 'contractor' ? 'Professional' : 'Homeowner'}
            </Badge>
            {suspended ? <Badge tone="danger">Suspended</Badge> : <Badge tone="ok">Active</Badge>}
            {d.contractor?.verified ? <Badge tone="ok">Verified</Badge> : null}
            {isPro ? <Badge tone="warn">Pro</Badge> : null}
            {!p.onboarding_complete ? <Badge tone="warn">Onboarding incomplete</Badge> : null}
          </div>
        </div>
        <Link
          href={backHref}
          aria-label="Close account details"
          className="rounded-sm px-1.5 text-ink-3 transition-colors duration-150 hover:text-ink"
        >
          ✕
        </Link>
      </header>

      <dl className="grid grid-cols-2 gap-x-4 gap-y-2.5 border-b border-line px-4 py-3.5 text-sm">
        <Row label="Joined" value={fmtDateTime(p.created_at)} />
        <Row
          label="Last sign-in"
          value={d.auth?.last_sign_in_at ? fmtAgo(d.auth.last_sign_in_at) : 'never'}
          title={d.auth?.last_sign_in_at ? fmtDateTime(d.auth.last_sign_in_at) : undefined}
        />
        <Row label="Phone confirmed" value={d.auth?.phone_confirmed_at ? 'yes' : 'no'} />
        <Row label="Account id" value={p.id} mono />
      </dl>

      {d.contractor ? (
        <dl className="grid grid-cols-2 gap-x-4 gap-y-2.5 border-b border-line px-4 py-3.5 text-sm">
          <Row label="Business" value={d.contractor.business_name || '—'} rtl />
          <Row
            label="Calls itself"
            value={PROVIDER_KIND_LABEL[d.contractor.provider_kind] ?? d.contractor.provider_kind}
          />
          <Row
            label="Rating"
            value={
              d.contractor.rating_count > 0
                ? `${d.contractor.rating_avg} from ${d.contractor.rating_count}`
                : 'no reviews yet'
            }
          />
          <Row label="Jobs completed" value={fmtNum(d.contractor.projects_completed)} />
          <Row
            label="Plan"
            value={
              isPro
                ? `Pro until ${fmtDateTime(d.contractor.plan_expires_at)}`
                : d.contractor.plan === 'pro'
                  ? 'Pro, expired'
                  : 'Free'
            }
          />
          <Row label="Specialties" value={(d.contractor.specialties ?? []).join(', ') || '—'} rtl />
          <Row label="Areas" value={(d.contractor.service_areas ?? []).join(', ') || '—'} rtl />
        </dl>
      ) : null}

      {d.homeowner ? (
        <dl className="grid grid-cols-2 gap-x-4 gap-y-2.5 border-b border-line px-4 py-3.5 text-sm">
          <Row label="City" value={d.homeowner.city || '—'} rtl />
          <Row label="District" value={d.homeowner.district || '—'} rtl />
          <Row label="Home type" value={d.homeowner.apartment_type || '—'} />
        </dl>
      ) : null}

      <div className="border-b border-line px-4 py-3.5">
        <p className="mb-2 text-xs font-medium text-ink-2">Activity</p>
        <dl className="grid grid-cols-3 gap-x-3 gap-y-2.5 text-sm">
          <Stat label="Briefs" value={d.stats.briefs} />
          <Stat label="Quotes" value={d.stats.quotes} />
          <Stat label="Posts" value={d.stats.posts} />
          <Stat label="Comments" value={d.stats.comments} />
          <Stat label="Reviews given" value={d.stats.reviews_written} />
          <Stat label="Reviews got" value={d.stats.reviews_received} />
          {/* Two signals worth reading together: reports filed against this
              account, and how many people blocked it independently. */}
          <Stat label="Reported" value={d.stats.reports_against} warnAbove={0} />
          <Stat label="Blocked by" value={d.stats.blocked_by} warnAbove={2} />
        </dl>
      </div>

      {/* ── controls ── */}
      <div className="flex flex-col gap-4 px-4 py-4">
        {suspended ? (
          <div>
            <p className="text-xs font-medium text-ink-2">Suspension</p>
            <p className="mt-1 text-sm text-ink-3">
              Since {fmtDateTime(p.suspended_at)}.
              {p.suspended_reason ? (
                <>
                  {' '}
                  Reason: <span className="text-ink-2">{p.suspended_reason}</span>
                </>
              ) : null}
            </p>
            <form action={unsuspendUser} className="mt-2">
              <input type="hidden" name="user_id" value={p.id} />
              <input type="hidden" name="path" value="/users" />
              <Button type="submit" variant="secondary" size="sm">
                Lift suspension
              </Button>
            </form>
          </div>
        ) : (
          <form action={suspendUser}>
            <input type="hidden" name="user_id" value={p.id} />
            <input type="hidden" name="path" value="/users" />
            <Label htmlFor="suspend-reason">Suspend this account</Label>
            <Textarea
              id="suspend-reason"
              name="reason"
              rows={2}
              required
              placeholder="Why. Recorded in the audit log and shown here afterwards."
              className="text-sm"
            />
            <p className="mt-1 text-xs text-ink-3">
              Blocks new briefs, quotes, posts, comments and reviews. Existing content stays up.
            </p>
            <Button type="submit" variant="danger" size="sm" className="mt-2">
              Suspend account
            </Button>
          </form>
        )}

        {d.contractor ? (
          <>
            <form action={setVerified} className="border-t border-line pt-4">
              <input type="hidden" name="contractor_id" value={p.id} />
              <input type="hidden" name="path" value="/users" />
              <input type="hidden" name="verified" value={String(!d.contractor.verified)} />
              <Label htmlFor="verify-reason">
                {d.contractor.verified ? 'Remove the verified badge' : 'Grant the verified badge'}
              </Label>
              <Input
                id="verify-reason"
                name="reason"
                placeholder="Note for the audit log (optional)"
              />
              <Button
                type="submit"
                variant={d.contractor.verified ? 'danger' : 'primary'}
                size="sm"
                className="mt-2"
              >
                {d.contractor.verified ? 'Remove verification' : 'Verify this professional'}
              </Button>
            </form>

            {canManagePlan ? (
              <form action={setPlan} className="border-t border-line pt-4">
                <input type="hidden" name="contractor_id" value={p.id} />
                <input type="hidden" name="path" value="/users" />
                <Label htmlFor="plan">Plan</Label>
                <div className="flex gap-2">
                  <Select id="plan" name="plan" defaultValue={d.contractor.plan}>
                    <option value="free">Free</option>
                    <option value="pro">Pro</option>
                  </Select>
                  <Input
                    name="days"
                    type="number"
                    min={0}
                    max={3650}
                    defaultValue={30}
                    aria-label="Days of Pro access"
                    className="w-20"
                  />
                  <Button type="submit" variant="secondary" size="sm">
                    Apply
                  </Button>
                </div>
                <p className="mt-1 text-xs text-ink-3">
                  Grants Pro without a payment, for comped accounts or a transfer that arrived outside
                  the app. Days are ignored on the free plan.
                </p>
              </form>
            ) : (
              <p className="border-t border-line pt-4 text-xs text-ink-3">
                <Badge>Owner access required</Badge>{' '}
                Plan changes are reserved for owner accounts.
              </p>
            )}
          </>
        ) : null}
      </div>

      {d.audit.length > 0 ? (
        <div className="border-t border-line px-4 py-3.5">
          <p className="mb-2 text-xs font-medium text-ink-2">Admin history</p>
          <ol className="flex flex-col gap-1.5 text-xs">
            {d.audit.map((entry) => (
              <li key={entry.id} className="flex items-baseline justify-between gap-3">
                <span className="font-mono text-ink-2">{entry.action}</span>
                <span className="shrink-0 text-ink-3" title={fmtDateTime(entry.created_at)}>
                  {fmtAgo(entry.created_at)}
                </span>
              </li>
            ))}
          </ol>
        </div>
      ) : null}
    </Panel>
  );
}

function Row({
  label,
  value,
  title,
  mono,
  rtl,
}: {
  label: string;
  value: string;
  title?: string;
  mono?: boolean;
  rtl?: boolean;
}) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-ink-3">{label}</dt>
      <dd
        title={title ?? value}
        dir={rtl ? 'auto' : undefined}
        className={`truncate text-ink-2 ${mono ? 'font-mono text-xs' : ''}`}
      >
        {value}
      </dd>
    </div>
  );
}

function Stat({
  label,
  value,
  warnAbove,
}: {
  label: string;
  value: number | undefined;
  warnAbove?: number;
}) {
  const n = value ?? 0;
  // Only coloured when there is something to notice. Heavy colour on a zero or
  // inactive state trains the reader to ignore the colour entirely.
  const hot = warnAbove !== undefined && n > warnAbove;
  return (
    <div>
      <dt className="text-xs text-ink-3">{label}</dt>
      <dd className={`font-medium ${hot ? 'text-warn' : 'text-ink'}`}>{fmtNum(n)}</dd>
    </div>
  );
}
