'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cx } from './ui';

/**
 * Side navigation. The only client component on the authenticated surface — it
 * exists purely because the active item needs the current pathname, which a
 * layout does not receive.
 */

const ITEMS = [
  { href: '/', label: 'Overview' },
  { href: '/users', label: 'Users' },
  { href: '/contractors', label: 'Professionals' },
  { href: '/moderation', label: 'Moderation' },
  { href: '/payments', label: 'Payments' },
  { href: '/activity', label: 'Activity' },
] as const;

export function Nav({ queues }: { queues: { verification: number; payment: number; reports: number } }) {
  const path = usePathname();

  const count: Record<string, number> = {
    '/contractors': queues.verification,
    '/moderation': queues.reports,
    '/payments': queues.payment,
  };

  return (
    <nav aria-label="Console sections" className="flex flex-col gap-0.5">
      {ITEMS.map(({ href, label }) => {
        // Exact match for the root, prefix match elsewhere, so /users?user=… stays
        // highlighted while the drawer is open.
        const active = href === '/' ? path === '/' : path.startsWith(href);
        const pending = count[href] ?? 0;

        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? 'page' : undefined}
            className={cx(
              'group flex items-center justify-between gap-2 rounded-md px-2.5 py-1.5 text-sm',
              'transition-colors duration-150 ease-[var(--ease-out-quart)]',
              active
                ? 'bg-accent-dim/60 font-medium text-ink'
                : 'text-ink-2 hover:bg-panel hover:text-ink',
            )}
          >
            <span className="flex min-w-0 items-center gap-2">
              {/* A 2px rail rather than a coloured left border on the item: a thick
                  side stripe as an accent is never the right answer. */}
              <span
                aria-hidden
                className={cx(
                  'h-4 w-[2px] rounded-full transition-colors duration-150',
                  active ? 'bg-accent' : 'bg-transparent',
                )}
              />
              <span className="truncate">{label}</span>
            </span>

            {pending > 0 ? (
              <span
                title={`${pending} waiting`}
                className="rounded-sm border border-warn-dim bg-warn-dim/50 px-1 text-2xs font-medium text-warn"
              >
                {pending}
              </span>
            ) : null}
          </Link>
        );
      })}
    </nav>
  );
}
