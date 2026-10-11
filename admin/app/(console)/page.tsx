import Link from 'next/link';
import { supabaseServer } from '@/lib/supabase/server';
import { ActivityChart, Funnel, StatStrip, type Stat } from '@/components/charts';
import { OutcomeBanner } from '@/components/banner';
import { Avatar, Badge, EmptyState, ErrorState, Panel, PanelHead, Table, TD, TH, TR } from '@/components/ui';
import { fmtAgo, fmtDateTime, fmtEgp, fmtNum, fmtPhone, formatRole } from '@/lib/format';
import { fmtPct } from '@/lib/format';
import { getAdminLocale } from '@/lib/locale';
import { t, type AdminLocale } from '@/lib/i18n';

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
  const locale = await getAdminLocale();
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
        <ErrorState what={t(locale, 'Could not read the overview metrics.')} locale={locale} />
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
      label: t(locale, 'Accounts'),
      value: fmtNum(o.users.total, locale),
      foot: t(locale, '{homeowners} homeowners · {pros} pros', { homeowners: fmtNum(o.users.homeowners, locale), pros: fmtNum(o.users.contractors, locale) }),
      delta: { current: o.users.new_7d, previous: o.users.prev_7d },
    },
    {
      label: t(locale, 'New this week'),
      value: fmtNum(o.users.new_7d, locale),
      foot: t(locale, '{count} in 30 days', { count: fmtNum(o.users.new_30d, locale) }),
    },
    {
      label: t(locale, 'Active this week'),
      value: fmtNum(o.users.active_7d, locale),
      foot: t(locale, '{percent}% of all accounts', { percent: fmtPct(o.users.active_7d, o.users.total, locale).replace('%', '') }),
    },
    {
      label: t(locale, 'Briefs'),
      value: fmtNum(o.demand.briefs, locale),
      foot: t(locale, '{count} still open', { count: fmtNum(o.demand.briefs_open, locale) }),
    },
    {
      label: t(locale, 'Quotes'),
      value: fmtNum(o.demand.quotes, locale),
      foot: t(locale, '{accepted} accepted · {completed} completed', { accepted: fmtNum(o.demand.accepted, locale), completed: fmtNum(o.demand.completed, locale) }),
    },
    {
      label: t(locale, 'Collected'),
      value: fmtEgp(o.revenue.egp_total, locale),
      foot: t(locale, '{count} in 30 days', { count: fmtEgp(o.revenue.egp_30d, locale) }),
    },
  ];

  const pendingTotal = o.queues.verification + o.queues.payment + o.queues.reports;

  return (
    <>
      <header className="mb-5">
        <h1 className="text-xl font-semibold tracking-tight text-ink">{t(locale, 'Overview')}</h1>
        <p className="mt-0.5 text-sm text-ink-3">
          {t(locale, 'Live from the database. Times are Cairo.')}
        </p>
      </header>

      <OutcomeBanner done={done} error={error} locale={locale} />

      <div className="flex flex-col gap-5">
        <StatStrip stats={stats} locale={locale} />

        {pendingTotal > 0 ? (
          <Panel className="flex flex-wrap items-center gap-x-5 gap-y-2 px-4 py-3">
            <span className="text-sm font-medium text-ink">{t(locale, 'Waiting on you')}</span>
            <QueueLink href="/contractors" count={o.queues.verification} label="verification" locale={locale} />
            <QueueLink href="/payments" count={o.queues.payment} label="payment" locale={locale} />
            <QueueLink href="/moderation" count={o.queues.reports} label="report" locale={locale} />
          </Panel>
        ) : null}

        <div className="grid gap-5 xl:grid-cols-[1.6fr_1fr]">
          <Panel>
            <PanelHead
              title={t(locale, 'Daily activity')}
              hint={t(locale, 'Last 30 days. Zero-activity days are shown as gaps, not skipped.')}
            />
            {seriesRes.error ? (
              <ErrorState what={t(locale, 'Could not read daily activity.')} locale={locale} />
            ) : days.length === 0 ? (
              <EmptyState
                title={t(locale, 'No activity yet')}
                body={t(locale, 'Signups, briefs and quotes appear here the day they happen.')}
              />
            ) : (
              <ActivityChart
                days={days.map((d) => d.day)}
                locale={locale}
                series={[
                  { key: 'signups', label: t(locale, 'Signups'), tone: 'accent', values: days.map((d) => d.signups) },
                  { key: 'signins', label: t(locale, 'Sign-ins'), tone: 'info', values: days.map((d) => d.signins) },
                  { key: 'briefs', label: t(locale, 'Briefs'), tone: 'warn', values: days.map((d) => d.briefs) },
                  { key: 'quotes', label: t(locale, 'Quotes'), tone: 'ok', values: days.map((d) => d.quotes) },
                ]}
              />
            )}
          </Panel>

          <Panel>
            <PanelHead title={t(locale, 'Marketplace funnel')} hint={t(locale, 'Each step as a share of the one above it.')} />
            {funnelRes.error ? (
              <ErrorState what={t(locale, 'Could not read the marketplace funnel.')} locale={locale} />
            ) : (
              <Funnel
                steps={[
                  { label: t(locale, 'Homeowners'), value: f.homeowners ?? 0 },
                  { label: t(locale, 'Posted a brief'), value: f.posted_brief ?? 0 },
                  { label: t(locale, 'Briefs with a quote'), value: f.briefs_quoted ?? 0, note: liquidityNote(f, locale) },
                  { label: t(locale, 'Quote accepted'), value: f.briefs_accepted ?? 0 },
                  { label: t(locale, 'Job completed'), value: f.briefs_completed ?? 0 },
                  { label: t(locale, 'Reviewed'), value: f.briefs_reviewed ?? 0 },
                ]}
                locale={locale}
              />
            )}
          </Panel>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          <Panel>
            <PanelHead
              title={t(locale, 'Supply health')}
              hint={t(locale, 'A professional who never quotes is not supply.')}
            />
            <dl className="grid grid-cols-2 gap-x-4 gap-y-3 px-4 py-4">
              <Metric label={t(locale, 'Professionals')} value={fmtNum(o.users.contractors, locale)} />
              <Metric
                label={t(locale, 'Quoted this week')}
                value={fmtNum(o.supply.quoting_7d, locale)}
                foot={t(locale, '{percent}% of them', { percent: fmtPct(o.supply.quoting_7d, o.users.contractors, locale).replace('%', '') })}
              />
              <Metric
                label={t(locale, 'Verified')}
                value={fmtNum(o.supply.verified, locale)}
                foot={t(locale, '{percent}% of them', { percent: fmtPct(o.supply.verified, o.users.contractors, locale).replace('%', '') })}
              />
              <Metric label={t(locale, 'On Pro')} value={fmtNum(o.supply.pro, locale)} />
              <Metric label={t(locale, 'With a portfolio')} value={fmtNum(o.supply.with_portfolio, locale)} />
              <Metric
                label={t(locale, 'Finished onboarding')}
                value={fmtNum(o.users.onboarded, locale)}
                foot={t(locale, '{percent}% of all accounts', { percent: fmtPct(o.users.onboarded, o.users.total, locale).replace('%', '') })}
              />
            </dl>
          </Panel>

          <Panel>
            <PanelHead title={t(locale, 'Content and trust')} />
            <dl className="grid grid-cols-2 gap-x-4 gap-y-3 px-4 py-4">
              <Metric label={t(locale, 'Posts')} value={fmtNum(o.content.posts, locale)} foot={t(locale, '{count} this week', { count: fmtNum(o.content.posts_7d, locale) })} />
              <Metric label={t(locale, 'Comments')} value={fmtNum(o.content.comments, locale)} />
              <Metric
                label={t(locale, 'Reviews')}
                value={fmtNum(o.content.reviews, locale)}
                foot={o.content.rating_avg ? t(locale, '{rating} average', { rating: fmtNum(o.content.rating_avg, locale) }) : t(locale, 'no ratings yet')}
              />
              <Metric
                label={t(locale, 'Suspended accounts')}
                value={fmtNum(o.users.suspended, locale)}
                foot={o.users.suspended > 0 ? t(locale, 'see Users') : undefined}
              />
            </dl>
          </Panel>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          <Panel>
            <PanelHead title={t(locale, 'Newest accounts')} action={<SeeAll href="/users" locale={locale} />} />
            {signupsRes.error ? (
              <ErrorState what={t(locale, 'Could not read recent signups.')} locale={locale} />
            ) : signups.length === 0 ? (
              <EmptyState title={t(locale, 'Nobody has signed up yet')} body={t(locale, 'New accounts appear here as they register.')} />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>{t(locale, 'Name')}</TH>
                    <TH>{t(locale, 'Role')}</TH>
                    <TH align="right">{t(locale, 'Joined')}</TH>
                  </tr>
                </thead>
                <tbody className="stagger">
                  {signups.map((u, i) => (
                    <TR key={u.id} style={{ ['--i' as string]: i }}>
                      <TD>
                        <PersonCell id={u.id} name={u.full_name} phone={u.phone} suspended={u.suspended_at} locale={locale} />
                      </TD>
                      <TD>
                        <RoleBadge role={u.role} onboarded={u.onboarded} locale={locale} />
                      </TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(u.created_at, locale)}>{fmtAgo(u.created_at, locale)}</span>
                      </TD>
                    </TR>
                  ))}
                </tbody>
              </Table>
            )}
          </Panel>

          <Panel>
            <PanelHead title={t(locale, 'Most recent sign-ins')} action={<SeeAll href="/activity" locale={locale} />} />
            {signinsRes.error ? (
              <ErrorState what={t(locale, 'Could not read recent sign-ins.')} locale={locale} />
            ) : signins.length === 0 ? (
              <EmptyState
                title={t(locale, 'No sign-ins recorded')}
                body={t(locale, 'An account shows here once it completes an OTP login.')}
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>{t(locale, 'Name')}</TH>
                    <TH align="right">{t(locale, 'Sessions')}</TH>
                    <TH align="right">{t(locale, 'Last seen')}</TH>
                  </tr>
                </thead>
                <tbody className="stagger">
                  {signins.map((u, i) => (
                    <TR key={u.id} style={{ ['--i' as string]: i }}>
                      <TD>
                        <PersonCell id={u.id} name={u.full_name} phone={u.phone} suspended={u.suspended_at} locale={locale} />
                      </TD>
                      <TD align="right" className="text-ink-3">{fmtNum(u.session_count, locale)}</TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(u.last_sign_in, locale)}>{fmtAgo(u.last_sign_in, locale)}</span>
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
function liquidityNote(f: Record<string, number>, locale: AdminLocale): string | undefined {
  const briefs = f.briefs ?? 0;
  const quoted = f.briefs_quoted ?? 0;
  if (briefs === 0) return undefined;
  const unanswered = briefs - quoted;
  if (unanswered === 0) return t(locale, 'Every brief has at least one quote.');
  return t(locale, '{unanswered} of {briefs} briefs have no quote at all.', { unanswered: fmtNum(unanswered, locale), briefs: fmtNum(briefs, locale) });
}

function QueueLink({ href, count, label, locale }: { href: string; count: number; label: 'verification' | 'payment' | 'report'; locale: AdminLocale }) {
  if (count === 0) return null;
  const messageKey = label === 'verification'
    ? count === 1 ? '{count} verification' : '{count} verifications'
    : label === 'payment'
      ? count === 1 ? '{count} payment' : '{count} payments'
      : count === 1 ? '{count} report' : '{count} reports';
  const text = t(locale, messageKey, { count: fmtNum(count, locale) });
  return (
    <Link
      href={href}
      className="flex items-center gap-1.5 text-sm text-ink-2 underline decoration-line-strong underline-offset-4 transition-colors duration-150 hover:text-ink hover:decoration-accent"
    >
      <Badge tone="warn">{fmtNum(count, locale)}</Badge>
      {text}
    </Link>
  );
}

function SeeAll({ href, locale }: { href: string; locale: AdminLocale }) {
  // Standalone meaning: a screen reader announcing this out of context still
  // knows where it goes.
  return (
    <Link
      href={href}
      className="text-xs text-ink-2 underline decoration-line-strong underline-offset-4 transition-colors duration-150 hover:text-ink hover:decoration-accent"
    >
      {t(locale, 'View all')}
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
  locale,
}: {
  id: string;
  name: string | null;
  phone: string | null;
  suspended: string | null;
  locale: AdminLocale;
}) {
  return (
    <Link href={`/users?user=${id}`} className="flex min-w-0 items-center gap-2.5 group">
      <Avatar name={name} locale={locale} />
      <span className="min-w-0">
        <span className="flex items-center gap-1.5">
          <span
            dir="auto"
            className="truncate font-medium text-ink group-hover:underline group-hover:decoration-accent group-hover:underline-offset-4"
          >
            {name?.trim() || t(locale, 'Unnamed')}
          </span>
          {suspended ? <Badge tone="danger">{t(locale, 'Suspended')}</Badge> : null}
        </span>
        <span className="block text-xs text-ink-3" dir="ltr">
          {fmtPhone(phone)}
        </span>
      </span>
    </Link>
  );
}

function RoleBadge({ role, onboarded, locale }: { role: string; onboarded?: boolean; locale: AdminLocale }) {
  return (
    <span className="flex items-center gap-1.5">
      <Badge tone={role === 'contractor' ? 'accent' : 'info'}>
        <bdi dir="auto">{formatRole(role, locale)}</bdi>
      </Badge>
      {onboarded === false ? (
        <Badge tone="warn" title={t(locale, 'Signed up but never finished onboarding')}>
          {t(locale, 'Incomplete')}
        </Badge>
      ) : null}
    </span>
  );
}
