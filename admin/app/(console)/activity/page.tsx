import Link from 'next/link';
import { supabaseServer } from '@/lib/supabase/server';
import { OutcomeBanner } from '@/components/banner';
import {
  Avatar, Badge, EmptyState, ErrorState, Panel, PanelHead, Table, TD, TH, TR, type Tone,
} from '@/components/ui';
import { fmtAgo, fmtDateTime, fmtNum, fmtPhone, formatRole } from '@/lib/format';
import { getAdminLocale } from '@/lib/locale';
import { t } from '@/lib/i18n';

export const dynamic = 'force-dynamic';

type Entry = {
  id: number;
  actor_id: string;
  action: string;
  target_table: string | null;
  target_id: string | null;
  meta: Record<string, unknown>;
  created_at: string;
};

type Signin = {
  id: string;
  full_name: string | null;
  phone: string | null;
  role: string;
  suspended_at: string | null;
  last_sign_in: string;
  session_count: number;
};

/** Tone by action family, so a suspension does not read like a plan change. */
function toneFor(action: string): Tone {
  if (action.startsWith('user.suspend') || action === 'post.delete' || action.endsWith('.reject')) {
    return 'danger';
  }
  if (action.endsWith('.approve') || action === 'contractor.verify' || action === 'user.unsuspend') {
    return 'ok';
  }
  if (action.startsWith('report.')) return 'warn';
  return 'neutral';
}

export default async function ActivityPage({
  searchParams,
}: {
  searchParams: Promise<{ done?: string; error?: string; days?: string; max?: string }>;
}) {
  const sp = await searchParams;
  const locale = await getAdminLocale();
  const supabase = await supabaseServer();

  const [auditRes, signinsRes] = await Promise.all([
    supabase
      .from('admin_audit_log')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(150),
    supabase.rpc('admin_recent_signins', { p_limit: 50 }),
  ]);

  const entries = (auditRes.data ?? []) as Entry[];
  const signins = (signinsRes.data ?? []) as Signin[];

  // Actor names, resolved in one query rather than per row.
  const actorIds = [...new Set(entries.map((e) => e.actor_id))];
  const actors = new Map<string, string | null>();
  if (actorIds.length > 0) {
    const { data } = await supabase.from('profiles').select('id, full_name').in('id', actorIds);
    for (const row of data ?? []) actors.set(row.id, row.full_name);
  }

  return (
    <>
      <header className="mb-4">
        <h1 className="text-xl font-semibold tracking-tight text-ink">{t(locale, 'Activity')}</h1>
        <p className="mt-0.5 text-sm text-ink-3">
          {t(locale, 'Every privileged action taken in this console, and who has been signing in.')}
        </p>
      </header>

      <OutcomeBanner done={sp.done} error={sp.error} days={sp.days} max={sp.max} locale={locale} />

      <div className="flex flex-col gap-5">
        <Panel className="overflow-hidden">
          <PanelHead
            title={t(locale, 'Admin audit log')}
            hint={t(locale, 'Append-only. No admin, including you, can edit or delete these rows from the console.')}
          />
          {auditRes.error ? (
            <ErrorState what={t(locale, 'Could not read the audit log.')} locale={locale} />
          ) : entries.length === 0 ? (
            <EmptyState
              title={t(locale, 'No admin actions yet')}
              body={t(locale, 'Suspending an account, verifying a professional or resolving a report writes a row here, permanently.')}
            />
          ) : (
            <Table>
              <thead>
                <tr>
                  <TH>{t(locale, 'Action')}</TH>
                  <TH>{t(locale, 'By')}</TH>
                  <TH>{t(locale, 'Target')}</TH>
                  <TH>{t(locale, 'Detail')}</TH>
                  <TH align="right">{t(locale, 'When')}</TH>
                </tr>
              </thead>
              <tbody className="stagger">
                {entries.map((entry, i) => (
                  <TR key={entry.id} style={{ ['--i' as string]: i }}>
                    <TD>
                      <Badge tone={toneFor(entry.action)}><bdi dir="ltr">{entry.action}</bdi></Badge>
                    </TD>
                    <TD>
                      <Link
                        href={`/users?user=${entry.actor_id}`}
                        dir="auto"
                        className="truncate text-ink-2 underline decoration-line-strong underline-offset-4 hover:text-ink hover:decoration-accent"
                      >
                        {actors.get(entry.actor_id)?.trim() || t(locale, 'Admin')}
                      </Link>
                    </TD>
                    <TD className="text-ink-3">
                      {entry.target_id ? (
                        <Link
                          href={`/users?user=${entry.target_id}`}
                          className="font-mono text-xs underline decoration-line-strong underline-offset-4 hover:text-ink hover:decoration-accent"
                          title={`${entry.target_table ?? ''} ${entry.target_id}`}
                          dir="ltr"
                        >
                          {entry.target_id.slice(0, 8)}
                        </Link>
                      ) : (
                        '—'
                      )}
                    </TD>
                    <TD>
                      <MetaCell meta={entry.meta} />
                    </TD>
                    <TD align="right" className="whitespace-nowrap text-ink-3">
                      <span title={fmtDateTime(entry.created_at, locale)}>{fmtAgo(entry.created_at, locale)}</span>
                    </TD>
                  </TR>
                ))}
              </tbody>
            </Table>
          )}
        </Panel>

        <Panel className="overflow-hidden">
          <PanelHead
            title={t(locale, 'Sign-in activity')}
            hint={t(locale, 'From auth.users. Session count is live sessions, which is the closest honest signal GoTrue keeps — it is not a login counter.')}
          />
          {signinsRes.error ? (
            <ErrorState what={t(locale, 'Could not read sign-in activity.')} locale={locale} />
          ) : signins.length === 0 ? (
            <EmptyState
              title={t(locale, 'No sign-ins recorded')}
              body={t(locale, 'An account appears here once it completes an OTP login in the app.')}
            />
          ) : (
            <Table>
              <thead>
                <tr>
                    <TH>{t(locale, 'Account')}</TH>
                    <TH>{t(locale, 'Role')}</TH>
                    <TH align="right">{t(locale, 'Sessions')}</TH>
                    <TH align="right">{t(locale, 'Last sign-in')}</TH>
                </tr>
              </thead>
              <tbody className="stagger">
                {signins.map((user, i) => (
                  <TR key={user.id} style={{ ['--i' as string]: i }}>
                    <TD>
                      <Link href={`/users?user=${user.id}`} className="group flex min-w-0 items-center gap-2.5">
                        <Avatar name={user.full_name} locale={locale} />
                        <span className="min-w-0">
                          <span className="flex items-center gap-1.5">
                            <span
                              dir="auto"
                              className="truncate font-medium text-ink group-hover:underline group-hover:decoration-accent group-hover:underline-offset-4"
                            >
                              {user.full_name?.trim() || t(locale, 'Unnamed')}
                            </span>
                            {user.suspended_at ? <Badge tone="danger">{t(locale, 'Suspended')}</Badge> : null}
                          </span>
                          <span className="block text-xs text-ink-3" dir="ltr">
                            {fmtPhone(user.phone)}
                          </span>
                        </span>
                      </Link>
                    </TD>
                    <TD>
                      <Badge tone={user.role === 'contractor' ? 'accent' : 'info'}>
                        <bdi dir="auto">{formatRole(user.role, locale)}</bdi>
                      </Badge>
                    </TD>
                    <TD align="right" className="text-ink-2">
                      {fmtNum(user.session_count, locale)}
                    </TD>
                    <TD align="right" className="whitespace-nowrap text-ink-3">
                      <span title={fmtDateTime(user.last_sign_in, locale)}>{fmtAgo(user.last_sign_in, locale)}</span>
                    </TD>
                  </TR>
                ))}
              </tbody>
            </Table>
          )}
        </Panel>
      </div>
    </>
  );
}

/** Renders the audit meta jsonb as readable pairs, skipping the ids already
 *  shown in their own column. */
function MetaCell({ meta }: { meta: Record<string, unknown> }) {
  const pairs = Object.entries(meta ?? {}).filter(
    ([key, value]) => value != null && value !== '' && !key.endsWith('_id'),
  );
  if (pairs.length === 0) return <span className="text-ink-3">—</span>;

  return (
    <span className="flex max-w-[42ch] flex-wrap gap-x-2 text-xs text-ink-2">
      {pairs.map(([key, value]) => (
        <span key={key} dir="auto" className="truncate">
          <span className="text-ink-3">{key}:</span> {String(value)}
        </span>
      ))}
    </span>
  );
}
