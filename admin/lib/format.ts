/**
 * Display formatting. Everything the console shows a human goes through here so
 * two pages can never disagree about how a date or a phone number looks.
 */

// The business is in Egypt and so is whoever reads this console. Rendering
// timestamps in the server's UTC would make "signed up today" quietly wrong for
// anything after 22:00 Cairo.
const TZ = 'Africa/Cairo';

const dateTime = new Intl.DateTimeFormat('en-GB', {
  timeZone: TZ,
  day: '2-digit',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
});

const dateOnly = new Intl.DateTimeFormat('en-GB', {
  timeZone: TZ,
  day: '2-digit',
  month: 'short',
  year: 'numeric',
});

const dayShort = new Intl.DateTimeFormat('en-GB', { timeZone: TZ, day: '2-digit', month: 'short' });

export function fmtDateTime(iso: string | null | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '—' : dateTime.format(d);
}

export function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '—' : dateOnly.format(d);
}

export function fmtDayShort(iso: string): string {
  return dayShort.format(new Date(iso));
}

/** "3h ago", "5d ago". Absolute dates stay available in the title attribute at
 *  every call site — relative time alone is useless when you need to correlate
 *  with a support message. */
export function fmtAgo(iso: string | null | undefined): string {
  if (!iso) return 'never';
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return '—';
  const secs = Math.round((Date.now() - then) / 1000);
  if (secs < 60) return 'just now';
  const mins = Math.round(secs / 60);
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.round(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.round(hours / 24);
  if (days < 30) return `${days}d ago`;
  const months = Math.round(days / 30);
  return months < 12 ? `${months}mo ago` : `${Math.round(months / 12)}y ago`;
}

export function fmtNum(n: number | null | undefined): string {
  if (n == null) return '—';
  return new Intl.NumberFormat('en-US').format(n);
}

export function fmtEgp(n: number | null | undefined): string {
  if (n == null) return '—';
  return `${new Intl.NumberFormat('en-US').format(n)} EGP`;
}

/**
 * Percentage-point change between two windows, as a signed string.
 * Returns null when there is no baseline: "+100%" from a base of zero is a
 * number that reads as insight and carries none.
 */
export function fmtDelta(current: number, previous: number): { text: string; dir: 1 | 0 | -1 } | null {
  if (previous === 0) return current === 0 ? null : { text: 'new', dir: 1 };
  const pct = Math.round(((current - previous) / previous) * 100);
  if (pct === 0) return { text: 'flat', dir: 0 };
  return { text: `${pct > 0 ? '+' : ''}${pct}%`, dir: pct > 0 ? 1 : -1 };
}

/** Egyptian mobile numbers in a readable grouping: +20 10 1234 5678. */
export function fmtPhone(raw: string | null | undefined): string {
  if (!raw) return '—';
  const digits = raw.replace(/[^\d]/g, '');
  const local = digits.startsWith('20') ? digits.slice(2) : digits;
  if (local.length !== 10) return raw;
  return `+20 ${local.slice(0, 2)} ${local.slice(2, 6)} ${local.slice(6)}`;
}

/** A ratio as a whole percentage, guarding the zero denominator. */
export function pct(part: number, whole: number): number {
  return whole === 0 ? 0 : Math.round((part / whole) * 100);
}

export function initials(name: string | null | undefined): string {
  const parts = (name ?? '').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '؟';
  const first = [...(parts[0] ?? '')][0] ?? '';
  const second = parts.length > 1 ? ([...(parts[parts.length - 1] ?? '')][0] ?? '') : '';
  return (first + second).toUpperCase();
}

export const PROVIDER_KIND_LABEL: Record<string, string> = {
  contractor: 'Contractor',
  engineer: 'Engineer',
  engineering_office: 'Engineering office',
  finishing_company: 'Finishing company',
  interior_designer: 'Interior designer',
  tradesman: 'Tradesman',
};

export const REPORT_REASON_LABEL: Record<string, string> = {
  spam: 'Spam',
  harassment: 'Harassment',
  nudity: 'Nudity',
  scam: 'Scam or fraud',
  impersonation: 'Impersonation',
  other: 'Other',
};
