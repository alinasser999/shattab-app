import type { ComponentProps, ReactNode } from 'react';

/**
 * The console's component vocabulary. One button shape, one badge shape, one
 * table. Every page composes from here, so "approve" never looks different in
 * two places.
 */

export function cx(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(' ');
}

/* ── surfaces ─────────────────────────────────────────────── */

// A 1px line is enough definition on a dark surface. Deliberately no wide soft
// drop shadow alongside it: border-plus-blurry-shadow is the ghost-card tell.
export function Panel({ className, children, ...rest }: ComponentProps<'section'>) {
  return (
    <section className={cx('rounded-lg border border-line bg-surface', className)} {...rest}>
      {children}
    </section>
  );
}

export function PanelHead({
  title,
  hint,
  action,
}: {
  title: string;
  hint?: string;
  action?: ReactNode;
}) {
  return (
    <header className="flex items-start justify-between gap-4 border-b border-line px-4 py-3">
      <div className="min-w-0">
        <h2 className="text-md font-semibold text-ink">{title}</h2>
        {hint ? <p className="mt-0.5 text-xs text-ink-3">{hint}</p> : null}
      </div>
      {action ? <div className="shrink-0">{action}</div> : null}
    </header>
  );
}

/* ── badges ───────────────────────────────────────────────── */

export type Tone = 'neutral' | 'ok' | 'warn' | 'danger' | 'info' | 'accent';

const TONE: Record<Tone, string> = {
  neutral: 'border-line-strong bg-panel text-ink-2',
  ok: 'border-ok-dim bg-ok-dim/50 text-ok',
  warn: 'border-warn-dim bg-warn-dim/50 text-warn',
  danger: 'border-danger-dim bg-danger-dim/50 text-danger',
  info: 'border-info-dim bg-info-dim/50 text-info',
  accent: 'border-accent-dim bg-accent-dim/50 text-accent-ink',
};

export function Badge({
  tone = 'neutral',
  children,
  title,
}: {
  tone?: Tone;
  children: ReactNode;
  title?: string;
}) {
  return (
    <span
      title={title}
      className={cx(
        'inline-flex items-center gap-1 rounded-sm border px-1.5 py-0.5 text-2xs font-medium whitespace-nowrap',
        TONE[tone],
      )}
    >
      {children}
    </span>
  );
}

// Always paired with a label at the call site. Colour alone fails in greyscale
// and says nothing at all to a screen reader.
export function Dot({ tone }: { tone: Tone }) {
  const fill: Record<Tone, string> = {
    neutral: 'bg-ink-3',
    ok: 'bg-ok',
    warn: 'bg-warn',
    danger: 'bg-danger',
    info: 'bg-info',
    accent: 'bg-accent',
  };
  return <span aria-hidden className={cx('size-1.5 shrink-0 rounded-full', fill[tone])} />;
}

/* ── buttons ──────────────────────────────────────────────── */

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';

const VARIANT: Record<Variant, string> = {
  primary: 'bg-accent text-bg hover:bg-accent-ink active:brightness-95',
  secondary: 'border border-line-strong bg-panel text-ink hover:bg-raised active:brightness-95',
  ghost: 'text-ink-2 hover:bg-panel hover:text-ink',
  danger: 'border border-danger-dim bg-danger-dim/40 text-danger hover:bg-danger-dim/70',
};

export function Button({
  variant = 'secondary',
  size = 'md',
  loading = false,
  className,
  children,
  ...rest
}: ComponentProps<'button'> & { variant?: Variant; size?: 'sm' | 'md'; loading?: boolean }) {
  return (
    <button
      // aria-busy as well as disabled: `disabled` alone announces "unavailable"
      // to assistive tech, which is not the same message as "working".
      aria-busy={loading || undefined}
      disabled={rest.disabled || loading}
      className={cx(
        'inline-flex items-center justify-center gap-1.5 rounded-md font-medium',
        'transition-[background-color,color,filter] duration-150 ease-[var(--ease-out-quart)]',
        'disabled:cursor-not-allowed disabled:opacity-45',
        size === 'sm' ? 'h-7 px-2 text-xs' : 'h-8 px-3 text-sm',
        VARIANT[variant],
        className,
      )}
      {...rest}
    >
      {loading ? <Spinner /> : null}
      {children}
    </button>
  );
}

function Spinner() {
  return (
    <span
      aria-hidden
      className="size-3 animate-spin rounded-full border-[1.5px] border-current border-t-transparent"
    />
  );
}

/* ── table ────────────────────────────────────────────────── */

export function Table({ children }: { children: ReactNode }) {
  return (
    <div className="scroll-x">
      <table className="w-full border-collapse text-left">{children}</table>
    </div>
  );
}

export function TH({
  children,
  align = 'left',
  className,
}: {
  children?: ReactNode;
  align?: 'left' | 'right';
  className?: string;
}) {
  return (
    <th
      scope="col"
      className={cx(
        'sticky top-0 z-[var(--z-sticky)] border-b border-line bg-surface px-3 py-2',
        'text-xs font-medium whitespace-nowrap text-ink-3',
        align === 'right' && 'text-right',
        className,
      )}
    >
      {children}
    </th>
  );
}

export function TD({
  children,
  align = 'left',
  className,
  ...rest
}: ComponentProps<'td'> & { align?: 'left' | 'right' }) {
  return (
    <td
      className={cx(
        'border-b border-line/60 px-3 py-2.5 align-middle',
        align === 'right' && 'text-right',
        className,
      )}
      {...rest}
    >
      {children}
    </td>
  );
}

export function TR({ children, className, ...rest }: ComponentProps<'tr'>) {
  return (
    <tr className={cx('transition-colors duration-150 hover:bg-panel/60', className)} {...rest}>
      {children}
    </tr>
  );
}

/* ── states ───────────────────────────────────────────────── */

// Empty states teach the surface. "No results" tells the reader nothing they did
// not already know, so every one of these says what would put something here.
export function EmptyState({
  title,
  body,
  action,
}: {
  title: string;
  body: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center gap-2 px-6 py-14 text-center">
      <p className="text-md font-medium text-ink">{title}</p>
      <p className="max-w-[46ch] text-sm text-ink-3">{body}</p>
      {action ? <div className="mt-2">{action}</div> : null}
    </div>
  );
}

// Skeletons, never a spinner in the middle of content: the page keeps its shape
// so nothing jumps when the data lands.
export function Skeleton({ className }: { className?: string }) {
  return <div className={cx('shimmer rounded-sm', className)} />;
}

export function TableSkeleton({ rows = 6, cols = 5 }: { rows?: number; cols?: number }) {
  return (
    <div className="px-3 py-2">
      {Array.from({ length: rows }, (_, r) => (
        <div key={r} className="flex items-center gap-3 border-b border-line/60 py-2.5">
          {Array.from({ length: cols }, (_, c) => (
            <Skeleton key={c} className={cx('h-3.5', c === 0 ? 'w-40' : 'w-20')} />
          ))}
        </div>
      ))}
    </div>
  );
}

// Shown when a read fails. An empty table on error reads as "no data", which is
// the wrong conclusion to hand an operator.
export function ErrorState({ what, detail }: { what: string; detail?: string }) {
  return (
    <div className="flex flex-col items-center gap-2 px-6 py-12 text-center">
      <Badge tone="danger">Failed to load</Badge>
      <p className="text-sm text-ink-2">{what}</p>
      {detail ? <p className="max-w-[60ch] font-mono text-xs text-ink-3">{detail}</p> : null}
      <p className="text-xs text-ink-3">
        Reload the page. If it persists, check the Supabase project status.
      </p>
    </div>
  );
}

/* ── identity ─────────────────────────────────────────────── */

export function Avatar({ name, size = 28 }: { name: string | null | undefined; size?: number }) {
  const parts = (name ?? '').trim().split(/\s+/).filter(Boolean);
  // Spread-then-index rather than charAt: Arabic is fine either way, but an
  // emoji or surrogate pair in a display name would otherwise render as half a
  // character.
  const first = [...(parts[0] ?? '')][0] ?? '?';
  const last = parts.length > 1 ? ([...(parts[parts.length - 1] ?? '')][0] ?? '') : '';
  return (
    <span
      aria-hidden
      style={{ width: size, height: size, fontSize: size * 0.36 }}
      className="inline-flex shrink-0 items-center justify-center rounded-full border border-line-strong bg-panel font-semibold text-ink-2"
    >
      {(first + last).toUpperCase()}
    </span>
  );
}

/* ── forms ────────────────────────────────────────────────── */

export function Input({ className, ...rest }: ComponentProps<'input'>) {
  return (
    <input
      className={cx(
        'h-8 w-full rounded-md border border-line-strong bg-panel px-2.5 text-sm text-ink',
        // Placeholders get the same 4.5:1 floor as body text. The default faint
        // grey placeholder is unreadable, and that is a bug, not a style.
        'placeholder:text-ink-3',
        'transition-colors duration-150 disabled:opacity-45',
        className,
      )}
      {...rest}
    />
  );
}

export function Select({ className, children, ...rest }: ComponentProps<'select'>) {
  return (
    <select
      className={cx(
        'h-8 rounded-md border border-line-strong bg-panel px-2 text-sm text-ink disabled:opacity-45',
        className,
      )}
      {...rest}
    >
      {children}
    </select>
  );
}

export function Textarea({ className, ...rest }: ComponentProps<'textarea'>) {
  return (
    <textarea
      className={cx(
        'w-full rounded-md border border-line-strong bg-panel px-2.5 py-2 text-sm text-ink',
        'placeholder:text-ink-3 disabled:opacity-45',
        className,
      )}
      {...rest}
    />
  );
}

export function Label({ children, htmlFor }: { children: ReactNode; htmlFor?: string }) {
  return (
    <label htmlFor={htmlFor} className="mb-1 block text-xs font-medium text-ink-2">
      {children}
    </label>
  );
}
