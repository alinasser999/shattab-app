import { Badge } from './ui';

/**
 * Outcome banner for the ?done= / ?error= convention the server actions use.
 * A toast would need client state and would vanish before it was read; this
 * persists until the next navigation, which is what an operator wants after
 * suspending an account.
 */
export function OutcomeBanner({ done, error }: { done?: string; error?: string }) {
  if (!done && !error) return null;
  const isError = Boolean(error);

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
      <Badge tone={isError ? 'danger' : 'ok'}>{isError ? 'Failed' : 'Done'}</Badge>
      <p className="min-w-0 flex-1">{error ?? done}</p>
    </div>
  );
}
