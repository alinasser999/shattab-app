import Link from 'next/link';
import { supabaseServer } from '@/lib/supabase/server';
import { OutcomeBanner } from '@/components/banner';
import { UserDrawer } from './drawer';
import { buildHref, type Query } from './query';
import {
  Avatar, Badge, Button, EmptyState, ErrorState, Input, Panel, Select,
  Table, TD, TH, TR,
} from '@/components/ui';
import { fmtAgo, fmtDateTime, fmtNum, fmtPhone } from '@/lib/format';

export const dynamic = 'force-dynamic';

const PAGE_SIZE = 40;

type Row = {
  id: string;
  role: string;
  full_name: string | null;
  phone: string | null;
  onboarding_complete: boolean;
  suspended_at: string | null;
  suspended_reason: string | null;
  created_at: string;
};

export default async function UsersPage({ searchParams }: { searchParams: Promise<Query> }) {
  const sp = await searchParams;
  const page = Math.max(1, Number.parseInt(sp.page ?? '1', 10) || 1);
  const term = (sp.q ?? '').trim();

  const supabase = await supabaseServer();

  let query = supabase
    .from('profiles')
    .select(
      'id, role, full_name, phone, onboarding_complete, suspended_at, suspended_reason, created_at',
      { count: 'exact' },
    );

  if (term) {
    // Stripping commas and parentheses matters: PostgREST parses them as
    // structure inside or(), so an unescaped one turns a search into a filter
    // the operator never wrote.
    const safe = term.replace(/[(),]/g, ' ').trim();
    query = query.or(`full_name.ilike.%${safe}%,phone.ilike.%${safe}%`);
  }
  if (sp.role === 'homeowner' || sp.role === 'contractor') query = query.eq('role', sp.role);
  if (sp.status === 'suspended') query = query.not('suspended_at', 'is', null);
  if (sp.status === 'incomplete') query = query.eq('onboarding_complete', false);

  const { data, error, count } = await query
    .order('created_at', { ascending: false })
    .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);

  const rows = (data ?? []) as Row[];
  const total = count ?? 0;
  const lastPage = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const filtered = Boolean(term || sp.role || sp.status);

  return (
    <>
      <header className="mb-4 flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold tracking-tight text-ink">Users</h1>
          <p className="mt-0.5 text-sm text-ink-3">
            {fmtNum(total)} {total === 1 ? 'account' : 'accounts'}. Select one to see everything about
            it.
          </p>
        </div>

        {/* A GET form: filter state lives in the URL, so a filtered view can be
            bookmarked, shared and reloaded. A client-side filter gives none of
            that and needs JavaScript to do less. */}
        <form className="flex flex-wrap items-center gap-2">
          <Input
            name="q"
            type="search"
            defaultValue={term}
            placeholder="Name or phone"
            aria-label="Search accounts by name or phone"
            className="w-48"
          />
          <Select name="role" defaultValue={sp.role ?? ''} aria-label="Filter by role">
            <option value="">Every role</option>
            <option value="homeowner">Homeowners</option>
            <option value="contractor">Professionals</option>
          </Select>
          <Select name="status" defaultValue={sp.status ?? ''} aria-label="Filter by status">
            <option value="">Any status</option>
            <option value="suspended">Suspended</option>
            <option value="incomplete">Onboarding incomplete</option>
          </Select>
          <Button type="submit" variant="secondary">
            Apply
          </Button>
        </form>
      </header>

      <OutcomeBanner done={sp.done} error={sp.error} />

      <div className="grid gap-5 xl:grid-cols-[1fr_22rem]">
        <Panel className="min-w-0 overflow-hidden">
          {error ? (
            <ErrorState what="Could not read the account list." />
          ) : rows.length === 0 ? (
            <EmptyState
              title="No accounts match"
              body={
                filtered
                  ? 'Widen the filters, or clear the search box and apply again.'
                  : 'Accounts appear here as soon as someone completes phone verification in the app.'
              }
              action={
                filtered ? (
                  <Link href="/users">
                    <Button variant="secondary">Clear all filters</Button>
                  </Link>
                ) : undefined
              }
            />
          ) : (
            <Table>
              <thead>
                <tr>
                  <TH>Account</TH>
                  <TH>Role</TH>
                  <TH>Status</TH>
                  <TH align="right">Joined</TH>
                </tr>
              </thead>
              <tbody className="stagger">
                {rows.map((u, i) => (
                  <TR
                    key={u.id}
                    style={{ ['--i' as string]: i }}
                    className={sp.user === u.id ? 'bg-panel' : undefined}
                  >
                    <TD>
                      <Link
                        href={buildHref(sp, { user: u.id })}
                        className="group flex min-w-0 items-center gap-2.5"
                      >
                        <Avatar name={u.full_name} />
                        <span className="min-w-0">
                          <span
                            dir="auto"
                            className="block truncate font-medium text-ink group-hover:underline group-hover:decoration-accent group-hover:underline-offset-4"
                          >
                            {u.full_name?.trim() || 'Unnamed'}
                          </span>
                          <span className="block text-xs text-ink-3" dir="ltr">
                            {fmtPhone(u.phone)}
                          </span>
                        </span>
                      </Link>
                    </TD>
                    <TD>
                      <Badge tone={u.role === 'contractor' ? 'accent' : 'info'}>
                        {u.role === 'contractor' ? 'Professional' : 'Homeowner'}
                      </Badge>
                    </TD>
                    <TD>
                      <span className="flex flex-wrap items-center gap-1.5">
                        {u.suspended_at ? (
                          <Badge tone="danger" title={u.suspended_reason ?? undefined}>
                            Suspended
                          </Badge>
                        ) : (
                          <Badge tone="ok">Active</Badge>
                        )}
                        {!u.onboarding_complete ? <Badge tone="warn">Incomplete</Badge> : null}
                      </span>
                    </TD>
                    <TD align="right" className="whitespace-nowrap text-ink-3">
                      <span title={fmtDateTime(u.created_at)}>{fmtAgo(u.created_at)}</span>
                    </TD>
                  </TR>
                ))}
              </tbody>
            </Table>
          )}

          {lastPage > 1 ? (
            <nav
              aria-label="Pagination"
              className="flex items-center justify-between gap-3 border-t border-line px-4 py-2.5 text-xs text-ink-3"
            >
              <span>
                Page {page} of {lastPage}
              </span>
              <span className="flex gap-1.5">
                <PageLink sp={sp} to={page - 1} disabled={page <= 1} label="Previous" />
                <PageLink sp={sp} to={page + 1} disabled={page >= lastPage} label="Next" />
              </span>
            </nav>
          ) : null}
        </Panel>

        <UserDrawer userId={sp.user} backHref={buildHref(sp, { user: undefined })} />
      </div>
    </>
  );
}

function PageLink({
  sp,
  to,
  disabled,
  label,
}: {
  sp: Query;
  to: number;
  disabled: boolean;
  label: string;
}) {
  if (disabled) {
    return (
      <span aria-disabled className="rounded-sm px-2 py-1 text-ink-3 opacity-45">
        {label}
      </span>
    );
  }
  return (
    <Link
      href={buildHref(sp, { page: String(to) })}
      className="rounded-sm px-2 py-1 text-ink-2 transition-colors duration-150 hover:bg-panel hover:text-ink"
    >
      {label}
    </Link>
  );
}
