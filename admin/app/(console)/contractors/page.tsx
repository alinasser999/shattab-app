import Link from 'next/link';
import { supabaseServer } from '@/lib/supabase/server';
import { reviewVerification, setVerified } from '@/lib/actions';
import { OutcomeBanner } from '@/components/banner';
import {
  Avatar, Badge, Button, EmptyState, ErrorState, Input, Label, Panel, PanelHead,
  Select, Table, TD, TH, TR,
} from '@/components/ui';
import { PROVIDER_KIND_LABEL, fmtAgo, fmtDateTime, fmtNum } from '@/lib/format';

export const dynamic = 'force-dynamic';

type Pending = {
  id: string;
  contractor_id: string;
  doc_paths: string[];
  note: string | null;
  created_at: string;
  profiles: { full_name: string | null; phone: string | null } | null;
  contractor_profiles: { business_name: string | null; provider_kind: string } | null;
};

type Pro = {
  profile_id: string;
  business_name: string | null;
  provider_kind: string;
  verified: boolean;
  plan: string;
  plan_expires_at: string | null;
  rating_avg: number | null;
  rating_count: number;
  projects_completed: number;
  created_at: string;
  profiles: { full_name: string | null; suspended_at: string | null } | null;
};

const QUEUE_SELECT =
  'id, contractor_id, doc_paths, note, created_at, profiles!inner(full_name, phone), contractor_profiles!inner(business_name, provider_kind)';

const ROSTER_SELECT =
  'profile_id, business_name, provider_kind, verified, plan, plan_expires_at, rating_avg, rating_count, projects_completed, created_at, profiles!inner(full_name, suspended_at)';

export default async function ContractorsPage({
  searchParams,
}: {
  searchParams: Promise<{ filter?: string; done?: string; error?: string }>;
}) {
  const sp = await searchParams;
  const supabase = await supabaseServer();

  // The queue embeds the profile and the professional record, so one request
  // renders a reviewable row. Three round trips per pending item is how a queue
  // becomes too slow to actually work through.
  const queuePromise = supabase
    .from('verification_requests')
    .select(QUEUE_SELECT)
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(50);

  let roster = supabase
    .from('contractor_profiles')
    .select(ROSTER_SELECT)
    .order('created_at', { ascending: false })
    .limit(200);

  if (sp.filter === 'unverified') roster = roster.eq('verified', false);
  if (sp.filter === 'verified') roster = roster.eq('verified', true);
  if (sp.filter === 'pro') roster = roster.eq('plan', 'pro');

  const [queueRes, rosterRes] = await Promise.all([queuePromise, roster]);

  const pending = (queueRes.data ?? []) as unknown as Pending[];
  const pros = (rosterRes.data ?? []) as unknown as Pro[];
  const now = new Date().toISOString();

  // Verification documents live in a private bucket. Signed URLs are minted per
  // render and expire in five minutes: a permanent public URL for somebody's
  // national ID is not a trade worth making to save one request.
  const docs = new Map<string, string[]>();
  await Promise.all(
    pending.map(async (request) => {
      const urls = await Promise.all(
        (request.doc_paths ?? []).slice(0, 6).map(async (path) => {
          const { data } = await supabase.storage.from('verification-docs').createSignedUrl(path, 300);
          return data?.signedUrl ?? null;
        }),
      );
      docs.set(
        request.id,
        urls.filter((u): u is string => Boolean(u)),
      );
    }),
  );

  return (
    <>
      <header className="mb-4">
        <h1 className="text-xl font-semibold tracking-tight text-ink">Professionals</h1>
        <p className="mt-0.5 text-sm text-ink-3">
          The verification queue first, then everyone on the supply side.
        </p>
      </header>

      <OutcomeBanner done={sp.done} error={sp.error} />

      <div className="flex flex-col gap-5">
        <Panel>
          <PanelHead
            title="Verification queue"
            hint="Oldest first. Document links are signed and expire after five minutes."
            action={<Badge tone={pending.length > 0 ? 'warn' : 'ok'}>{pending.length} pending</Badge>}
          />
          {queueRes.error ? (
            <ErrorState what="Could not read the verification queue." />
          ) : pending.length === 0 ? (
            <EmptyState
              title="Queue is clear"
              body="A request lands here when a professional submits their ID or trade licence from the app."
            />
          ) : (
            <ul className="stagger divide-y divide-line">
              {pending.map((request, i) => (
                <QueueItem
                  key={request.id}
                  index={i}
                  request={request}
                  docUrls={docs.get(request.id) ?? []}
                />
              ))}
            </ul>
          )}
        </Panel>

        <Panel className="overflow-hidden">
          <PanelHead
            title="Supply roster"
            hint="Newest first, capped at 200. Rating shows only where real reviews exist."
            action={
              <form className="flex gap-2">
                <Select name="filter" defaultValue={sp.filter ?? ''} aria-label="Filter professionals">
                  <option value="">Everyone</option>
                  <option value="unverified">Not verified</option>
                  <option value="verified">Verified</option>
                  <option value="pro">On Pro</option>
                </Select>
                <Button type="submit" variant="secondary" size="sm">
                  Apply
                </Button>
              </form>
            }
          />
          {rosterRes.error ? (
            <ErrorState what="Could not read the roster." />
          ) : pros.length === 0 ? (
            <EmptyState
              title="No professionals match"
              body="Clear the filter, or wait for contractor accounts to finish onboarding."
            />
          ) : (
            <Table>
              <thead>
                <tr>
                  <TH>Business</TH>
                  <TH>Calls itself</TH>
                  <TH>Trust</TH>
                  <TH align="right">Jobs</TH>
                  <TH align="right">Rating</TH>
                  <TH>Plan</TH>
                  <TH align="right">Verify</TH>
                </tr>
              </thead>
              <tbody className="stagger">
                {pros.map((pro, i) => {
                  const isPro = pro.plan === 'pro' && (pro.plan_expires_at ?? '') > now;
                  return (
                    <TR key={pro.profile_id} style={{ ['--i' as string]: i }}>
                      <TD>
                        <Link
                          href={`/users?user=${pro.profile_id}`}
                          className="group flex min-w-0 items-center gap-2.5"
                        >
                          <Avatar name={pro.business_name || pro.profiles?.full_name} />
                          <span className="min-w-0">
                            <span
                              dir="auto"
                              className="block truncate font-medium text-ink group-hover:underline group-hover:decoration-accent group-hover:underline-offset-4"
                            >
                              {pro.business_name?.trim() || pro.profiles?.full_name?.trim() || 'Unnamed'}
                            </span>
                            <span className="block text-xs text-ink-3" title={fmtDateTime(pro.created_at)}>
                              joined {fmtAgo(pro.created_at)}
                            </span>
                          </span>
                        </Link>
                      </TD>
                      <TD className="text-ink-2">
                        {PROVIDER_KIND_LABEL[pro.provider_kind] ?? pro.provider_kind}
                      </TD>
                      <TD>
                        <span className="flex flex-wrap items-center gap-1.5">
                          {pro.verified ? <Badge tone="ok">Verified</Badge> : <Badge>Unverified</Badge>}
                          {pro.profiles?.suspended_at ? <Badge tone="danger">Suspended</Badge> : null}
                        </span>
                      </TD>
                      <TD align="right" className="text-ink-2">
                        {fmtNum(pro.projects_completed)}
                      </TD>
                      <TD align="right" className="text-ink-2">
                        {/* No fallback rating. An invented average on an unreviewed
                            professional is the one number that must never be shown. */}
                        {pro.rating_count > 0 ? (
                          <span title={`${pro.rating_count} reviews`}>
                            {pro.rating_avg} <span className="text-ink-3">({pro.rating_count})</span>
                          </span>
                        ) : (
                          <span className="text-ink-3">—</span>
                        )}
                      </TD>
                      <TD>
                        {isPro ? (
                          <Badge tone="warn" title={`Until ${fmtDateTime(pro.plan_expires_at)}`}>
                            Pro
                          </Badge>
                        ) : pro.plan === 'pro' ? (
                          <Badge tone="danger" title="Plan is pro but the expiry has passed">
                            Expired
                          </Badge>
                        ) : (
                          <Badge>Free</Badge>
                        )}
                      </TD>
                      <TD align="right">
                        <form action={setVerified}>
                          <input type="hidden" name="contractor_id" value={pro.profile_id} />
                          <input type="hidden" name="path" value="/contractors" />
                          <input type="hidden" name="verified" value={String(!pro.verified)} />
                          <Button type="submit" variant={pro.verified ? 'ghost' : 'secondary'} size="sm">
                            {pro.verified ? 'Remove' : 'Verify'}
                          </Button>
                        </form>
                      </TD>
                    </TR>
                  );
                })}
              </tbody>
            </Table>
          )}
        </Panel>
      </div>
    </>
  );
}

/** One reviewable row in the verification queue. */
function QueueItem({
  index,
  request,
  docUrls,
}: {
  index: number;
  request: Pending;
  docUrls: string[];
}) {
  const name =
    request.contractor_profiles?.business_name?.trim() ||
    request.profiles?.full_name?.trim() ||
    'Unnamed';

  return (
    <li style={{ ['--i' as string]: index }} className="px-4 py-4">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex min-w-0 items-start gap-2.5">
          <Avatar name={name} />
          <div className="min-w-0">
            <Link
              href={`/users?user=${request.contractor_id}`}
              dir="auto"
              className="block truncate font-medium text-ink underline decoration-line-strong underline-offset-4 hover:decoration-accent"
            >
              {name}
            </Link>
            <p className="text-xs text-ink-3">
              {PROVIDER_KIND_LABEL[request.contractor_profiles?.provider_kind ?? ''] ?? 'Contractor'}
              {' · submitted '}
              <span title={fmtDateTime(request.created_at)}>{fmtAgo(request.created_at)}</span>
            </p>
            {request.note ? (
              <p dir="auto" className="mt-1 max-w-[60ch] text-sm text-ink-2">
                {request.note}
              </p>
            ) : null}
          </div>
        </div>

        <div className="flex flex-wrap gap-1.5">
          {docUrls.map((url, n) => (
            <a
              key={url}
              href={url}
              target="_blank"
              // noreferrer as well as noopener: the signed URL is in this page's
              // address, and Referer would leak it to whatever opens next.
              rel="noopener noreferrer"
              className="rounded-md border border-line-strong bg-panel px-2 py-1 text-xs text-ink-2 transition-colors duration-150 hover:bg-raised hover:text-ink"
            >
              Open document {n + 1}
            </a>
          ))}
          {docUrls.length === 0 ? <Badge tone="warn">No readable documents</Badge> : null}
        </div>
      </div>

      <div className="mt-3 flex flex-wrap items-end gap-2">
        <form action={reviewVerification}>
          <input type="hidden" name="request_id" value={request.id} />
          <input type="hidden" name="path" value="/contractors" />
          <input type="hidden" name="approve" value="true" />
          <Button type="submit" variant="primary" size="sm">
            Approve and grant the badge
          </Button>
        </form>

        <form action={reviewVerification} className="flex flex-1 items-end gap-2">
          <input type="hidden" name="request_id" value={request.id} />
          <input type="hidden" name="path" value="/contractors" />
          <input type="hidden" name="approve" value="false" />
          <div className="min-w-40 flex-1">
            <Label htmlFor={`reason-${request.id}`}>Rejection reason</Label>
            <Input
              id={`reason-${request.id}`}
              name="reason"
              placeholder="What was wrong with the documents"
            />
          </div>
          <Button type="submit" variant="danger" size="sm">
            Reject
          </Button>
        </form>
      </div>
    </li>
  );
}
