import Link from 'next/link';
import { supabaseServer } from '@/lib/supabase/server';
import { ActivityChart, Funnel, StatStrip, type Stat } from '@/components/charts';
import { OutcomeBanner } from '@/components/banner';
import { Avatar, Badge, EmptyState, ErrorState, Panel, PanelHead, Table, TD, TH, TR } from '@/components/ui';
import { fmtAgo, fmtDateTime, fmtEgp, fmtNum, fmtPhone, pct } from '@/lib/format';

// Operational data. Rendered per request, never from a build cache.
export const dynamic = 'force-dynamic';

type Overview = {
  users: {
    total: number; homeowners: number; contractors: number; onboarded: number;
    suspended: number; new_7d: number; prev_7d: number; new_30d: number;
    active_7d: number; active_30d: number;
  };
  supply: { verified: number; pro: number; with_portfolio: number; quoting_7d: number };
  demand: {
    briefs: number; briefs_open: number; briefs_7d: number; quotes: number;
    quotes_7d: number; accepted: number; completed: number;
  };
  content: { posts: number; posts_7d: number; comments: number; reviews: number; rating_avg: number | null };
  queues: { verification: number; payment: number; reports: number };
  revenue: { egp_total: number; egp_30d: number };
};

type Day = { day: string; signups: number; briefs: number; quotes: number; posts: number; signins: number };
type Signup = { id: string; full_name: string | null; phone: string | null; role: string; onboarded: boolean; suspended_at: string | null; created_at: string };
type Signin = { id: string; full_name: string | null; phone: string | null; role: string; suspended_at: string | null; last_sign_in: string; session_count: number };

export default async function OverviewPage({
  searchParams,
}: {
  searchParams: Promise<{ done?: string; error?: string }>;
}) {
  const { done, error } = await searchParams;
  const supabase = await supabaseServer();

  // Four independent reads, so they go out together rather than in series.
  const [overviewRes, seriesRes, funnelRes, signupsRes, signinsRes] = await Promise.all([
    supabase.rpc('admin_overview'),
    supabase.rpc('admin_timeseries', { p_days: 30 }),
    supabase.rpc('admin_funnel'),
    supabase.rpc('admin_recent_signups', { p_limit: 8 }),
    supabase.rpc('admin_recent_signins', { p_limit: 8 }),
  ]);

  if (overviewRes.error || !overviewRes.data) {
    return (
      <Panel>
        <ErrorState what="Could not read the overview metrics." />
      </Panel>
    );
  }

  const o = overviewRes.data as Overview;
  const days = (seriesRes.data ?? []) as Day[];
  const f = (funnelRes.data ?? {}) as Record<string, number>;
  const signups = (signupsRes.data ?? []) as Signup[];
  const signins = (signinsRes.data ?? []) as Signin[];

  const stats: Stat[] = [
    {
      label: 'Accounts',
      value: fmtNum(o.users.total),
      foot: `${fmtNum(o.users.homeowners)} homeowners · ${fmtNum(o.users.contractors)} pros`,
      delta: { current: o.users.new_7d, previous: o.users.prev_7d },
    },
    {
      label: 'New this week',
      value: fmtNum(o.users.new_7d),
      foot: `${fmtNum(o.users.new_30d)} in 30 days`,
    },
    {
      label: 'Active this week',
      value: fmtNum(o.users.active_7d),
      foot: `${pct(o.users.active_7d, o.users.total)}% of all accounts`,
    },
    {
      label: 'Briefs',
      value: fmtNum(o.demand.briefs),
      foot: `${fmtNum(o.demand.briefs_open)} still open`,
    },
    {
      label: 'Quotes',
      value: fmtNum(o.demand.quotes),
      foot: `${fmtNum(o.demand.accepted)} accepted · ${fmtNum(o.demand.completed)} completed`,
    },
    {
      label: 'Collected',
      value: fmtEgp(o.revenue.egp_total),
      foot: `${fmtEgp(o.revenue.egp_30d)} in 30 days`,
    },
  ];

  const pendingTotal = o.queues.verification + o.queues.payment + o.queues.reports;

  return (
    <>
      <header className="mb-5">
        <h1 className="text-xl font-semibold tracking-tight text-ink">Overview</h1>
        <p className="mt-0.5 text-sm text-ink-3">
          Live from the database. Times are Cairo.
        </p>
      </header>

      <OutcomeBanner done={done} error={error} />

      <div className="flex flex-col gap-5">
        <StatStrip stats={stats} />

        {pendingTotal > 0 ? (
          <Panel className="flex flex-wrap items-center gap-x-5 gap-y-2 px-4 py-3">
            <span className="text-sm font-medium text-ink">Waiting on you</span>
            <QueueLink href="/contractors" count={o.queues.verification} label="verification" />
            <QueueLink href="/payments" count={o.queues.payment} label="payment" />
            <QueueLink href="/moderation" count={o.queues.reports} label="report" />
          </Panel>
        ) : null}

        <div className="grid gap-5 xl:grid-cols-[1.6fr_1fr]">
          <Panel>
            <PanelHead
              title="Daily activity"
              hint="Last 30 days. Zero-activity days are shown as gaps, not skipped."
            />
            {seriesRes.error ? (
              <ErrorState what="Could not read daily activity." />
            ) : days.length === 0 ? (
              <EmptyState
                title="No activity yet"
                body="Signups, briefs and quotes appear here the day they happen."
              />
            ) : (
              <ActivityChart
                days={days.map((d) => d.day)}
                series={[
                  { key: 'signups', label: 'Signups', tone: 'accent', values: days.map((d) => d.signups) },
                  { key: 'signins', label: 'Sign-ins', tone: 'info', values: days.map((d) => d.signins) },
                  { key: 'briefs', label: 'Briefs', tone: 'warn', values: days.map((d) => d.briefs) },
                  { key: 'quotes', label: 'Quotes', tone: 'ok', values: days.map((d) => d.quotes) },
                ]}
              />
            )}
          </Panel>

          <Panel>
            <PanelHead title="Marketplace funnel" hint="Each step as a share of the one above it." />
            {funnelRes.error ? (
              <ErrorState what="Could not read the marketplace funnel." />
            ) : (
              <Funnel
                steps={[
                  { label: 'Homeowners', value: f.homeowners ?? 0 },
                  { label: 'Posted a brief', value: f.posted_brief ?? 0 },
                  { label: 'Briefs with a quote', value: f.briefs_quoted ?? 0, note: liquidityNote(f) },
                  { label: 'Quote accepted', value: f.briefs_accepted ?? 0 },
                  { label: 'Job completed', value: f.briefs_completed ?? 0 },
                  { label: 'Reviewed', value: f.briefs_reviewed ?? 0 },
                ]}
              />
            )}
          </Panel>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          <Panel>
            <PanelHead
              title="Supply health"
              hint="A professional who never quotes is not supply."
            />
            <dl className="grid grid-cols-2 gap-x-4 gap-y-3 px-4 py-4">
              <Metric label="Professionals" value={fmtNum(o.users.contractors)} />
              <Metric
                label="Quoted this week"
                value={fmtNum(o.supply.quoting_7d)}
                foot={`${pct(o.supply.quoting_7d, o.users.contractors)}% of them`}
              />
              <Metric
                label="Verified"
                value={fmtNum(o.supply.verified)}
                foot={`${pct(o.supply.verified, o.users.contractors)}% of them`}
              />
              <Metric label="On Pro" value={fmtNum(o.supply.pro)} />
              <Metric label="With a portfolio" value={fmtNum(o.supply.with_portfolio)} />
              <Metric
                label="Finished onboarding"
                value={fmtNum(o.users.onboarded)}
                foot={`${pct(o.users.onboarded, o.users.total)}% of all accounts`}
              />
            </dl>
          </Panel>

          <Panel>
            <PanelHead title="Content and trust" />
            <dl className="grid grid-cols-2 gap-x-4 gap-y-3 px-4 py-4">
              <Metric label="Posts" value={fmtNum(o.content.posts)} foot={`${fmtNum(o.content.posts_7d)} this week`} />
              <Metric label="Comments" value={fmtNum(o.content.comments)} />
              <Metric
                label="Reviews"
                value={fmtNum(o.content.reviews)}
                foot={o.content.rating_avg ? `${o.content.rating_avg} average` : 'no ratings yet'}
              />
              <Metric
                label="Suspended accounts"
                value={fmtNum(o.users.suspended)}
                foot={o.users.suspended > 0 ? 'see Users' : undefined}
              />
            </dl>
          </Panel>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          <Panel>
            <PanelHead title="Newest accounts" action={<SeeAll href="/users" />} />
            {signupsRes.error ? (
              <ErrorState what="Could not read recent signups." />
            ) : signups.length === 0 ? (
              <EmptyState title="Nobody has signed up yet" body="New accounts appear here as they register." />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>Name</TH>
                    <TH>Role</TH>
                    <TH align="right">Joined</TH>
                  </tr>
                </thead>
                <tbody className="stagger">
                  {signups.map((u, i) => (
                    <TR key={u.id} style={{ ['--i' as string]: i }}>
                      <TD>
                        <PersonCell id={u.id} name={u.full_name} phone={u.phone} suspended={u.suspended_at} />
                      </TD>
                      <TD>
                        <RoleBadge role={u.role} onboarded={u.onboarded} />
                      </TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(u.created_at)}>{fmtAgo(u.created_at)}</span>
                      </TD>
                    </TR>
                  ))}
                </tbody>
              </Table>
            )}
          </Panel>

          <Panel>
            <PanelHead title="Most recent sign-ins" action={<SeeAll href="/activity" />} />
            {signinsRes.error ? (
              <ErrorState what="Could not read recent sign-ins." />
            ) : signins.length === 0 ? (
              <EmptyState
                title="No sign-ins recorded"
                body="An account shows here once it completes an OTP login."
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>Name</TH>
                    <TH align="right">Sessions</TH>
                    <TH align="right">Last seen</TH>
                  </tr>
                </thead>
                <tbody className="stagger">
                  {signins.map((u, i) => (
                    <TR key={u.id} style={{ ['--i' as string]: i }}>
                      <TD>
                        <PersonCell id={u.id} name={u.full_name} phone={u.phone} suspended={u.suspended_at} />
                      </TD>
                      <TD align="right" className="text-ink-3">{fmtNum(u.session_count)}</TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(u.last_sign_in)}>{fmtAgo(u.last_sign_in)}</span>
                      </TD>
                    </TR>
                  ))}
                </tbody>
              </Table>
            )}
          </Panel>
        </div>
      </div>
    </>
  );
}

/* ── page-local pieces ────────────────────────────────────── */

/**
 * The one number that decides whether the marketplace works. A brief with no
 * quote is a homeowner who tried the product and got silence, so it is called
 * out in words rather than left to be inferred from two bar heights.
 */
function liquidityNote(f: Record<string, number>): string | undefined {
  const briefs = f.briefs ?? 0;
  const quoted = f.briefs_quoted ?? 0;
  if (briefs === 0) return undefined;
  const unanswered = briefs - quoted;
  if (unanswered === 0) return 'Every brief has at least one quote.';
  return `${unanswered} of ${briefs} briefs have no quote at all.`;
}

function QueueLink({ href, count, label }: { href: string; count: number; label: string }) {
  if (count === 0) return null;
  return (
    <Link
      href={href}
      className="flex items-center gap-1.5 text-sm text-ink-2 underline decoration-line-strong underline-offset-4 transition-colors duration-150 hover:text-ink hover:decoration-accent"
    >
      <Badge tone="warn">{count}</Badge>
      {count === 1 ? label : `${label}s`}
    </Link>
  );
}

function SeeAll({ href }: { href: string }) {
  // Standalone meaning: a screen reader announcing this out of context still
  // knows where it goes.
  return (
    <Link
      href={href}
      className="text-xs text-ink-2 underline decoration-line-strong underline-offset-4 transition-colors duration-150 hover:text-ink hover:decoration-accent"
    >
      View all
    </Link>
  );
}

function Metric({ label, value, foot }: { label: string; value: string; foot?: string }) {
  return (
    <div>
      <dt className="text-xs text-ink-3">{label}</dt>
      <dd className="mt-0.5 text-md font-medium text-ink">{value}</dd>
      {foot ? <p className="text-xs text-ink-3">{foot}</p> : null}
    </div>
  );
}

function PersonCell({
  id,
  name,
  phone,
  suspended,
}: {
  id: string;
  name: string | null;
  phone: string | null;
  suspended: string | null;
}) {
  return (
    <Link href={`/users?user=${id}`} className="flex min-w-0 items-center gap-2.5 group">
      <Avatar name={name} />
      <span className="min-w-0">
        <span className="flex items-center gap-1.5">
          <span
            dir="auto"
            className="truncate font-medium text-ink group-hover:underline group-hover:decoration-accent group-hover:underline-offset-4"
          >
            {name?.trim() || 'Unnamed'}
          </span>
          {suspended ? <Badge tone="danger">Suspended</Badge> : null}
        </span>
        <span className="block text-xs text-ink-3" dir="ltr">
          {fmtPhone(phone)}
        </span>
      </span>
    </Link>
  );
}

function RoleBadge({ role, onboarded }: { role: string; onboarded?: boolean }) {
  return (
    <span className="flex items-center gap-1.5">
      <Badge tone={role === 'contractor' ? 'accent' : 'info'}>
        {role === 'contractor' ? 'Professional' : 'Homeowner'}
      </Badge>
      {onboarded === false ? (
        <Badge tone="warn" title="Signed up but never finished onboarding">
          Incomplete
        </Badge>
      ) : null}
    </span>
  );
}
