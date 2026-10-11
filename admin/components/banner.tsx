import { Badge } from './ui';
import { outcomeKey, t, type AdminLocale } from '@/lib/i18n';
import { fmtNum } from '@/lib/format';

/**
 * Outcome banner for the ?done= / ?error= convention the server actions use.
 * A toast would need client state and would vanish before it was read; this
 * persists until the next navigation, which is what an operator wants after
 * suspending an account.
 */
export function OutcomeBanner({ done, error, days, max, locale = 'en' }: { done?: string; error?: string; days?: string; max?: string; locale?: AdminLocale }) {
  if (!done && !error) return null;
  const isError = Boolean(error);
  const params = {
    ...(days && Number.isFinite(Number(days)) ? { days: fmtNum(Number(days), locale) } : {}),
    ...(max && Number.isFinite(Number(max)) ? { max: fmtNum(Number(max), locale) } : {}),
  };

  return (
    <div
      // Errors get role=alert so they are announced immediately; a success
      // confirmation is polite by design and should not interrupt.
      role={isError ? 'alert' : 'status'}
      className={`mb-4 flex items-start gap-2.5 rounded-lg border px-3.5 py-2.5 text-sm ${
        isError
          ? 'border-danger-dim bg-danger-dim/40 text-ink'
          : 'border-ok-dim bg-ok-dim/40 text-ink'
      }`}
    >
      <Badge tone={isError ? 'danger' : 'ok'}>{isError ? t(locale, 'Failed') : t(locale, 'Done')}</Badge>
      <p className="min-w-0 flex-1">
        {isError
          ? t(locale, outcomeKey('error', error ?? ''), params)
          : t(locale, outcomeKey('done', done ?? ''), params)}
      </p>
    </div>
  );
}
