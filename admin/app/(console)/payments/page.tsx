import Link from 'next/link';
import { currentAdmin, supabaseServer } from '@/lib/supabase/server';
import { reviewPayment } from '@/lib/actions';
import { OutcomeBanner } from '@/components/banner';
import {
  Avatar, Badge, Button, EmptyState, ErrorState, Input, Label, Panel, PanelHead,
  Table, TD, TH, TR,
} from '@/components/ui';
import { formatPaymentMethod, formatPaymentPurpose, formatPlanTerm, fmtAgo, fmtDateTime, fmtEgp, fmtNum } from '@/lib/format';
import { getAdminLocale } from '@/lib/locale';
import { t, type AdminLocale } from '@/lib/i18n';

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

export default async function PaymentsPage({
  searchParams,
}: {
  searchParams: Promise<{ done?: string; error?: string; days?: string; max?: string }>;
}) {
  const sp = await searchParams;
  const locale = await getAdminLocale();
  const admin = await currentAdmin();
  // Billing is an owner-only write surface. Unknown/null levels fail closed
  // instead of being mistaken for an owner when the level RPC is unavailable.
  const canReviewPayments = admin?.level === 'owner';
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
        <h1 className="text-xl font-semibold tracking-tight text-ink">{t(locale, 'Payments')}</h1>
        <p className="mt-0.5 text-sm text-ink-3">
          {t(locale, 'Manual transfers awaiting confirmation, then what has actually been collected.')}
        </p>
      </header>

      <OutcomeBanner done={sp.done} error={sp.error} days={sp.days} max={sp.max} locale={locale} />

      <div className="flex flex-col gap-5">
        <Panel>
          <PanelHead
            title={t(locale, 'Awaiting confirmation')}
            hint={t(locale, 'Approving writes the payment and applies the plan in one transaction. Check the proof against your bank first.')}
            action={
              <Badge tone={pendingRes.error ? 'danger' : pending.length > 0 ? 'warn' : 'ok'}>
                {pendingRes.error ? t(locale, 'Unavailable') : `${fmtNum(pending.length, locale)} · ${fmtEgp(pendingTotal, locale)}`}
              </Badge>
            }
          />
          {pendingRes.error ? (
            <ErrorState what={t(locale, 'Could not read the payment queue.')} locale={locale} />
          ) : pending.length === 0 ? (
            <EmptyState
              title={t(locale, 'No transfers waiting')}
              body={t(locale, 'A request appears here when a professional submits an InstaPay or wallet transfer from the app.')}
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
                  locale={locale}
                />
              ))}
            </ul>
          )}
        </Panel>

        <div className="grid gap-5 lg:grid-cols-2">
          <Panel className="overflow-hidden">
            <PanelHead title={t(locale, 'Collected')} hint={t(locale, 'Confirmed payments, newest first.')} />
            {paymentsRes.error ? (
              <ErrorState what={t(locale, 'Could not read collected payments.')} locale={locale} />
            ) : payments.length === 0 ? (
              <EmptyState
                title={t(locale, 'No payments recorded')}
                body={t(locale, 'A row is written here the moment you confirm a transfer above.')}
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>{t(locale, 'Professional')}</TH>
                    <TH>{t(locale, 'For')}</TH>
                    <TH align="right">{t(locale, 'Amount')}</TH>
                    <TH align="right">{t(locale, 'When')}</TH>
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
                          {payment.profiles?.full_name?.trim() || t(locale, 'Unnamed')}
                        </Link>
                      </TD>
                      <TD className="text-ink-2">
                        <bdi dir="auto">{formatPaymentPurpose(payment.purpose, locale)}</bdi>
                      </TD>
                      <TD align="right" className="font-medium text-ink">
                        {/* Stored in piastres, shown in pounds. Dividing at the edge
                            keeps the money integral everywhere behind it. */}
                        {fmtEgp(payment.amount_piastres / 100, locale)}
                      </TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(payment.created_at, locale)}>{fmtAgo(payment.created_at, locale)}</span>
                      </TD>
                    </TR>
                  ))}
                </tbody>
              </Table>
            )}
          </Panel>

          <Panel className="overflow-hidden">
            <PanelHead title={t(locale, 'Recently reviewed')} hint={t(locale, 'The last 25 decisions on transfer requests.')} />
            {historyRes.error ? (
              <ErrorState what={t(locale, 'Could not read reviewed payment requests.')} locale={locale} />
            ) : history.length === 0 ? (
              <EmptyState
                title={t(locale, 'Nothing reviewed yet')}
                body={t(locale, 'Approvals and rejections are listed here, with full detail under Activity.')}
              />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <TH>{t(locale, 'Professional')}</TH>
                    <TH align="right">{t(locale, 'Amount')}</TH>
                    <TH>{t(locale, 'Outcome')}</TH>
                    <TH align="right">{t(locale, 'When')}</TH>
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
                            t(locale, 'Unnamed')}
                        </Link>
                      </TD>
                      <TD align="right" className="text-ink-2">
                        {fmtEgp(request.amount_egp, locale)}
                      </TD>
                      <TD>
                        <Badge tone={request.status === 'approved' ? 'ok' : 'danger'}>
                          {request.status === 'approved'
                            ? t(locale, 'Approved')
                            : request.status === 'rejected'
                              ? t(locale, 'Rejected')
                              : <bdi dir="auto">{request.status}</bdi>}
                        </Badge>
                        {request.reject_reason ? (
                          <span dir="auto" className="mt-0.5 block max-w-[28ch] truncate text-xs text-ink-3" title={request.reject_reason}>
                            {request.reject_reason}
                          </span>
                        ) : null}
                      </TD>
                      <TD align="right" className="whitespace-nowrap text-ink-3">
                        <span title={fmtDateTime(request.reviewed_at, locale)}>{fmtAgo(request.reviewed_at, locale)}</span>
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
  locale,
}: {
  index: number;
  request: Request;
  proofUrl?: string;
  canReview: boolean;
  locale: AdminLocale;
}) {
  const name =
    request.contractor_profiles?.business_name?.trim() ||
    request.profiles?.full_name?.trim() ||
    t(locale, 'Unnamed');

  return (
    <li style={{ ['--i' as string]: index }} className="px-4 py-4">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex min-w-0 items-start gap-2.5">
          <Avatar name={name} locale={locale} />
          <div className="min-w-0">
            <Link
              href={`/users?user=${request.contractor_id}`}
              dir="auto"
              className="block truncate font-medium text-ink underline decoration-line-strong underline-offset-4 hover:decoration-accent"
            >
              {name}
            </Link>
            <p className="mt-0.5 flex flex-wrap items-center gap-1.5 text-xs text-ink-3">
              <Badge tone="accent"><bdi dir="auto">{formatPaymentPurpose(request.purpose, locale)}</bdi></Badge>
              {request.plan_term ? <Badge><bdi dir="auto">{formatPlanTerm(request.plan_term, locale)}</bdi></Badge> : null}
              <Badge><bdi dir="auto">{formatPaymentMethod(request.method, locale)}</bdi></Badge>
              <span title={fmtDateTime(request.created_at, locale)}>{fmtAgo(request.created_at, locale)}</span>
            </p>
            {request.reference_text ? (
              <p className="mt-1 font-mono text-xs text-ink-2" dir="ltr">{t(locale, 'Reference: {value}', { value: request.reference_text })}</p>
            ) : null}
          </div>
        </div>

        <div className="flex items-center gap-2.5">
          <span className="text-md font-semibold text-ink" dir={locale === 'ar' ? 'auto' : undefined}>{fmtEgp(request.amount_egp, locale)}</span>
          {proofUrl ? (
            <a
              href={proofUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-md border border-line-strong bg-panel px-2 py-1 text-xs text-ink-2 transition-colors duration-150 hover:bg-raised hover:text-ink"
            >
              {t(locale, 'Open proof')}
            </a>
          ) : (
            <Badge tone="warn">{t(locale, 'No proof attached')}</Badge>
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
            <Label htmlFor={`reason-${request.id}`}>{t(locale, 'Reason, required to reject')}</Label>
            <Input
              id={`reason-${request.id}`}
              name="reason"
              placeholder={t(locale, 'For example: no matching transfer found')}
              dir="auto"
            />
          </div>
          <Button type="submit" name="approve" value="true" variant="primary" size="sm">
            {t(locale, 'Confirm and apply')}
          </Button>
          <Button type="submit" name="approve" value="false" variant="danger" size="sm">
            {t(locale, 'Reject')}
          </Button>
        </form>
      ) : (
        <p className="mt-3 text-xs text-ink-3">
          <Badge>{t(locale, 'Owner approval required')}</Badge>{' '}
          {t(locale, 'Moderator accounts can inspect this queue but cannot change billing state.')}
        </p>
      )}
    </li>
  );
}
