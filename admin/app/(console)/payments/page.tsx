import Link from 'next/link';
import { currentAdmin, supabaseServer } from '@/lib/supabase/server';
import { reviewPayment } from '@/lib/actions';
import { OutcomeBanner } from '@/components/banner';
import {
  Avatar, Badge, Button, EmptyState, ErrorState, Input, Label, Panel, PanelHead,
  Table, TD, TH, TR,
} from '@/components/ui';
import { fmtAgo, fmtDateTime, fmtEgp } from '@/lib/format';

export const dynamic = 'force-dynamic';

type Request = {
  id: string;
  contractor_id: string;
  method: string;
  purpose: string;
  plan_term: string | null;
  amount_egp: number;
  proof_path: string | null;
  reference_text: string | null;
  status: string;
  reject_reason: string | null;
  created_at: string;
  reviewed_at: string | null;
  profiles: { full_name: string | null } | null;
  contractor_profiles: { business_name: string | null } | null;
};

type Payment = {
  id: string;
  contractor_id: string;
  provider: string;
  purpose: string;
  amount_piastres: number;
  status: string;
  period_end: string | null;
  created_at: string;
  profiles: { full_name: string | null } | null;
};

const REQUEST_SELECT = '*, profiles!inner(full_name), contractor_profiles!inner(business_name)';

const PAYMENT_SELECT =
  'id, contractor_id, provider, purpose, amount_piastres, status, period_end, created_at, profiles!inner(full_name)';

const PURPOSE_LABEL: Record<string, string> = {
  pro: 'Shattab Pro',
  sponsored: 'Sponsored placement',
  boost: 'Profile boost',
};

export default async function PaymentsPage({
  searchParams,
}: {
  searchParams: Promise<{ done?: string; error?: string }>;
}) {
  const sp = await searchParams;
  const admin = await currentAdmin();
  const canReviewPayments = admin?.level !== 'moderator';
  const supabase = await supabaseServer();

  const [pendingRes, historyRes, paymentsRes] = await Promise.all([
    supabase
      .from('payment_requests')
      .select(REQUEST_SELECT)
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
      .limit(50),
    supabase
      .from('payment_requests')
      .select(REQUEST_SELECT)
      .neq('status', 'pending')
      .order('reviewed_at', { ascending: false })
      .limit(25),
    supabase.from('payments').select(PAYMENT_SELECT).order('created_at', { ascending: false }).limit(25),
  ]);

  const pending = (pendingRes.data ?? []) as unknown as Request[];
  const history = (historyRes.data ?? []) as unknown as Request[];
  const payments = (paymentsRes.data ?? []) as unknown as Payment[];

  // Payment proofs are screenshots of a bank or wallet transfer. Same reasoning
  // as verification documents: signed and short-lived, never a public URL.
  const proofs = new Map<string, string>();
  await Promise.all(
    pending.map(async (request) => {
      if (!request.proof_path) return;
      const { data } = await supabase.storage
        .from('payment-proofs')
        .createSignedUrl(request.proof_path, 300);
      if (data?.signedUrl) proofs.set(request.id, data.signedUrl);
    }),
  );

  const pendingTotal = pending.reduce((sum, r) => sum + r.amount_egp, 0);

  return (
    <>
      <header className="mb-4">
        <h1 className="text-xl font-semibold tracking-tight text-ink">Payments</h1>
        <p className="mt-0.5 text-sm text-ink-3">
          Manual transfers awaiting confirmation, then what has actually been collected.
        </p>
      </header>

      <OutcomeBanner done={sp.done} error={sp.error} />

      <div className="flex flex-col gap-5">
        <Panel>
          <PanelHead
            title="Awaiting confirmation"
            hint="Approving writes the payment and applies the plan in one transaction. Check the proof against your bank first."
            action={
              <Badge tone={pending.length > 0 ? 'warn' : 'ok'}>
                {pending.length} · {fmtEgp(pendingTotal)}
              </Badge>
            }
          />
          {pendingRes.error ? (
            <ErrorState what="Could not read the payment queue." />
          ) : pending.length === 0 ? (
            <EmptyState
              title="No transfers waiting"
              body="A request appears here when a professional submits an InstaPay or wallet transfer from the app."
            />
          ) : (
            <ul className="stagger divide-y divide-line">
              {pending.map((request, i) => (
                <PayItem
                  key={request.id}
                  index={i}
                  request={request}
                  proofUrl={proofs.get(request.id)}
                  canReview={canReviewPayments}
                />
              ))}
            </ul>
          )}
        </Panel>

        <div className="grid gap-5 lg:grid-cols-2">
          <Panel className="overflow-hidden">
            <PanelHead title="Collected" hint="Confirmed payments, newest first." />
            {payments.length === 0 ? (
              <EmptyState
                title="No payments recorded"
                body="A row is written here the moment you confirm a transfer above."
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>Professional</TH>
                    <TH>For</TH>
                    <TH align="right">Amount</TH>
                    <TH align="right">When</TH>
                  </tr>
                </thead>
                <tbody className="stagger">
                  {payments.map((payment, i) => (
                    <TR key={payment.id} style={{ ['--i' as string]: i }}>
                      <TD>
                        <Link
                          href={`/users?user=${payment.contractor_id}`}
                          dir="auto"
                          className="truncate font-medium text-ink underline decoration-line-strong underline-offset-4 hover:decoration-accent"
                        >
                          {payment.profiles?.full_name?.trim() || 'Unnamed'}
                        </Link>
                      </TD>
                      <TD className="text-ink-2">
                        {PURPOSE_LABEL[payment.purpose] ?? payment.purpose}
                      </TD>
                      <TD align="right" className="font-medium text-ink">
                        {/* Stored in piastres, shown in pounds. Dividing at the edge
                            keeps the money integral everywhere behind it. */}
                        {fmtEgp(payment.amount_piastres / 100)}
                      </TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(payment.created_at)}>{fmtAgo(payment.created_at)}</span>
                      </TD>
                    </TR>
                  ))}
                </tbody>
              </Table>
            )}
          </Panel>

          <Panel className="overflow-hidden">
            <PanelHead title="Recently reviewed" hint="The last 25 decisions on transfer requests." />
            {history.length === 0 ? (
              <EmptyState
                title="Nothing reviewed yet"
                body="Approvals and rejections are listed here, with full detail under Activity."
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>Professional</TH>
                    <TH align="right">Amount</TH>
                    <TH>Outcome</TH>
                    <TH align="right">When</TH>
                  </tr>
                </thead>
                <tbody>
                  {history.map((request) => (
                    <TR key={request.id}>
                      <TD>
                        <Link
                          href={`/users?user=${request.contractor_id}`}
                          dir="auto"
                          className="truncate text-ink-2 underline decoration-line-strong underline-offset-4 hover:text-ink hover:decoration-accent"
                        >
                          {request.contractor_profiles?.business_name?.trim() ||
                            request.profiles?.full_name?.trim() ||
                            'Unnamed'}
                        </Link>
                      </TD>
                      <TD align="right" className="text-ink-2">
                        {fmtEgp(request.amount_egp)}
                      </TD>
                      <TD>
                        <Badge tone={request.status === 'approved' ? 'ok' : 'danger'}>
                          {request.status === 'approved' ? 'Approved' : 'Rejected'}
                        </Badge>
                        {request.reject_reason ? (
                          <span className="mt-0.5 block max-w-[28ch] truncate text-xs text-ink-3" title={request.reject_reason}>
                            {request.reject_reason}
                          </span>
                        ) : null}
                      </TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(request.reviewed_at)}>{fmtAgo(request.reviewed_at)}</span>
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

/** One transfer awaiting confirmation. */
function PayItem({
  index,
  request,
  proofUrl,
  canReview,
}: {
  index: number;
  request: Request;
  proofUrl?: string;
  canReview: boolean;
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
            <p className="mt-0.5 flex flex-wrap items-center gap-1.5 text-xs text-ink-3">
              <Badge tone="accent">{PURPOSE_LABEL[request.purpose] ?? request.purpose}</Badge>
              {request.plan_term ? <Badge>{request.plan_term}</Badge> : null}
              <Badge>{request.method}</Badge>
              <span title={fmtDateTime(request.created_at)}>{fmtAgo(request.created_at)}</span>
            </p>
            {request.reference_text ? (
              <p className="mt-1 font-mono text-xs text-ink-2">Reference: {request.reference_text}</p>
            ) : null}
          </div>
        </div>

        <div className="flex items-center gap-2.5">
          <span className="text-md font-semibold text-ink">{fmtEgp(request.amount_egp)}</span>
          {proofUrl ? (
            <a
              href={proofUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-md border border-line-strong bg-panel px-2 py-1 text-xs text-ink-2 transition-colors duration-150 hover:bg-raised hover:text-ink"
            >
              Open proof
            </a>
          ) : (
            <Badge tone="warn">No proof attached</Badge>
          )}
        </div>
      </div>

      {canReview ? (
        /* One form, two submit buttons carrying approve=true/false, so the
           shared reason field reaches whichever was pressed. */
        <form action={reviewPayment} className="mt-3 flex flex-wrap items-end gap-2">
          <input type="hidden" name="request_id" value={request.id} />
          <input type="hidden" name="path" value="/payments" />
          <div className="min-w-48 flex-1">
            <Label htmlFor={`reason-${request.id}`}>Reason, required to reject</Label>
            <Input
              id={`reason-${request.id}`}
              name="reason"
              placeholder="For example: no matching transfer found"
            />
          </div>
          <Button type="submit" name="approve" value="true" variant="primary" size="sm">
            Confirm and apply
          </Button>
          <Button type="submit" name="approve" value="false" variant="danger" size="sm">
            Reject
          </Button>
        </form>
      ) : (
        <p className="mt-3 text-xs text-ink-3">
          <Badge>Owner approval required</Badge>{' '}
          Moderator accounts can inspect this queue but cannot change billing state.
        </p>
      )}
    </li>
  );
}
