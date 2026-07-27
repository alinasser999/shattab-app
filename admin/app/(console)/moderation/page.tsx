import Link from 'next/link';
import { supabaseServer } from '@/lib/supabase/server';
import { resolveReport } from '@/lib/actions';
import { OutcomeBanner } from '@/components/banner';
import {
  Avatar, Badge, Button, EmptyState, ErrorState, Input, Label, Panel, PanelHead,
  Table, TD, TH, TR,
} from '@/components/ui';
import { REPORT_REASON_LABEL, fmtAgo, fmtDateTime, fmtNum } from '@/lib/format';

export const dynamic = 'force-dynamic';

type Report = {
  id: string;
  reporter_id: string;
  target_type: string;
  target_id: string;
  reason: string;
  note: string | null;
  status: string;
  created_at: string;
  reviewed_at: string | null;
};

type BlockRow = { blocked_id: string; count: number; name: string | null };

const TARGET_LABEL: Record<string, string> = {
  post: 'Post',
  comment: 'Comment',
  user: 'Account',
};

export default async function ModerationPage({
  searchParams,
}: {
  searchParams: Promise<{ done?: string; error?: string }>;
}) {
  const sp = await searchParams;
  const supabase = await supabaseServer();

  const [pendingRes, resolvedRes, blocksRes] = await Promise.all([
    supabase
      .from('content_reports')
      .select('*')
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
      .limit(100),
    supabase
      .from('content_reports')
      .select('*')
      .neq('status', 'pending')
      .order('reviewed_at', { ascending: false })
      .limit(25),
    // Mutual blocks are private between the two users, but the aggregate is an
    // abuse signal: several unrelated people blocking one account is worth
    // seeing before a report is even filed.
    supabase.from('user_blocks').select('blocked_id').limit(2000),
  ]);

  const pending = (pendingRes.data ?? []) as Report[];
  const resolved = (resolvedRes.data ?? []) as Report[];

  const blockCounts = new Map<string, number>();
  for (const row of (blocksRes.data ?? []) as Array<{ blocked_id: string }>) {
    blockCounts.set(row.blocked_id, (blockCounts.get(row.blocked_id) ?? 0) + 1);
  }
  const mostBlocked: BlockRow[] = [...blockCounts.entries()]
    .filter(([, count]) => count >= 2)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([blocked_id, count]) => ({ blocked_id, count, name: null }));

  // Resolve display names for the short list only. Fetching names for two
  // thousand block rows to show ten of them would be the classic N+1 inverted.
  if (mostBlocked.length > 0) {
    const { data: names } = await supabase
      .from('profiles')
      .select('id, full_name')
      .in('id', mostBlocked.map((r) => r.blocked_id));
    const byId = new Map((names ?? []).map((n) => [n.id, n.full_name]));
    for (const row of mostBlocked) row.name = byId.get(row.blocked_id) ?? null;
  }

  return (
    <>
      <header className="mb-4">
        <h1 className="text-xl font-semibold tracking-tight text-ink">Moderation</h1>
        <p className="mt-0.5 text-sm text-ink-3">
          Reports from the app, and the accounts users block most.
        </p>
      </header>

      <OutcomeBanner done={sp.done} error={sp.error} />

      <div className="flex flex-col gap-5">
        <Panel>
          <PanelHead
            title="Open reports"
            hint="Oldest first. Removing content keeps its media in storage so an appeal can still be reviewed."
            action={<Badge tone={pending.length > 0 ? 'warn' : 'ok'}>{pending.length} open</Badge>}
          />
          {pendingRes.error ? (
            <ErrorState what="Could not read the report queue." detail={pendingRes.error.message} />
          ) : pending.length === 0 ? (
            <EmptyState
              title="Nothing reported"
              body="Reports arrive here when someone uses Report in the app. Both stores require this queue to exist and to be worked."
            />
          ) : (
            <ul className="stagger divide-y divide-line">
              {pending.map((report, i) => (
                <li key={report.id} style={{ ['--i' as string]: i }} className="px-4 py-4">
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="flex flex-wrap items-center gap-1.5">
                        <Badge tone="accent">{TARGET_LABEL[report.target_type] ?? report.target_type}</Badge>
                        <Badge tone="danger">
                          {REPORT_REASON_LABEL[report.reason] ?? report.reason}
                        </Badge>
                        <span className="text-xs text-ink-3" title={fmtDateTime(report.created_at)}>
                          {fmtAgo(report.created_at)}
                        </span>
                      </p>
                      {report.note ? (
                        <p dir="auto" className="mt-1.5 max-w-[70ch] text-sm text-ink-2">
                          {report.note}
                        </p>
                      ) : (
                        <p className="mt-1.5 text-sm text-ink-3">No note from the reporter.</p>
                      )}
                      <p className="mt-1.5 flex flex-wrap gap-3 text-xs text-ink-3">
                        <Link
                          href={`/users?user=${report.reporter_id}`}
                          className="underline decoration-line-strong underline-offset-4 hover:text-ink hover:decoration-accent"
                        >
                          View the reporter
                        </Link>
                        {report.target_type === 'user' ? (
                          <Link
                            href={`/users?user=${report.target_id}`}
                            className="underline decoration-line-strong underline-offset-4 hover:text-ink hover:decoration-accent"
                          >
                            View the reported account
                          </Link>
                        ) : (
                          <span className="font-mono">{report.target_type} {report.target_id}</span>
                        )}
                      </p>
                    </div>
                  </div>

                  {/* One form, three submit buttons. A submit button's name and
                      value are part of the submitted FormData, so the shared
                      decision note reaches whichever action was chosen — three
                      separate forms could not share one input. */}
                  <form action={resolveReport} className="mt-3 flex flex-wrap items-end gap-2">
                    <input type="hidden" name="report_id" value={report.id} />
                    <input type="hidden" name="path" value="/moderation" />
                    <div className="min-w-48 flex-1">
                      <Label htmlFor={`note-${report.id}`}>Decision note</Label>
                      <Input
                        id={`note-${report.id}`}
                        name="note"
                        placeholder="Recorded in the audit log"
                      />
                    </div>
                    <Button type="submit" name="action" value="dismiss" variant="secondary" size="sm">
                      No violation
                    </Button>
                    <Button type="submit" name="action" value="remove_content" variant="danger" size="sm">
                      Remove content
                    </Button>
                    <Button
                      type="submit"
                      name="action"
                      value="suspend_author"
                      variant="danger"
                      size="sm"
                    >
                      Remove and suspend
                    </Button>
                  </form>
                </li>
              ))}
            </ul>
          )}
        </Panel>

        <div className="grid gap-5 lg:grid-cols-2">
          <Panel className="overflow-hidden">
            <PanelHead
              title="Most blocked accounts"
              hint="Two or more independent blocks. Blocks are private to each user; only the count is shown."
            />
            {mostBlocked.length === 0 ? (
              <EmptyState
                title="No pattern yet"
                body="An account appears here once at least two different people have blocked it."
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>Account</TH>
                    <TH align="right">Blocked by</TH>
                  </tr>
                </thead>
                <tbody className="stagger">
                  {mostBlocked.map((row, i) => (
                    <TR key={row.blocked_id} style={{ ['--i' as string]: i }}>
                      <TD>
                        <Link
                          href={`/users?user=${row.blocked_id}`}
                          className="group flex min-w-0 items-center gap-2.5"
                        >
                          <Avatar name={row.name} />
                          <span
                            dir="auto"
                            className="truncate font-medium text-ink group-hover:underline group-hover:decoration-accent group-hover:underline-offset-4"
                          >
                            {row.name?.trim() || 'Unnamed'}
                          </span>
                        </Link>
                      </TD>
                      <TD align="right">
                        <Badge tone={row.count >= 4 ? 'danger' : 'warn'}>{fmtNum(row.count)} people</Badge>
                      </TD>
                    </TR>
                  ))}
                </tbody>
              </Table>
            )}
          </Panel>

          <Panel className="overflow-hidden">
            <PanelHead title="Recently resolved" hint="The last 25 decisions." />
            {resolved.length === 0 ? (
              <EmptyState
                title="Nothing resolved yet"
                body="Decisions you make above are listed here, and in full detail under Activity."
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>What</TH>
                    <TH>Reason</TH>
                    <TH>Outcome</TH>
                    <TH align="right">When</TH>
                  </tr>
                </thead>
                <tbody>
                  {resolved.map((report) => (
                    <TR key={report.id}>
                      <TD className="text-ink-2">
                        {TARGET_LABEL[report.target_type] ?? report.target_type}
                      </TD>
                      <TD className="text-ink-3">
                        {REPORT_REASON_LABEL[report.reason] ?? report.reason}
                      </TD>
                      <TD>
                        <Badge tone={report.status === 'actioned' ? 'danger' : 'neutral'}>
                          {report.status === 'actioned' ? 'Actioned' : 'Dismissed'}
                        </Badge>
                      </TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(report.reviewed_at)}>{fmtAgo(report.reviewed_at)}</span>
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
