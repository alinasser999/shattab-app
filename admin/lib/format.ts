/** Display formatting shared by every admin route. */
import { t, type AdminLocale, type MessageKey } from './i18n';

// The business is in Egypt. Never let server UTC change which day an operator sees.
const TZ = 'Africa/Cairo';
const intlLocale = (locale: AdminLocale) => (locale === 'ar' ? 'ar-EG' : 'en-GB');

function formatDate(value: string, locale: AdminLocale, options: Intl.DateTimeFormatOptions) {
  return new Intl.DateTimeFormat(intlLocale(locale), { timeZone: TZ, ...options }).format(new Date(value));
}

export function fmtDateTime(iso: string | null | undefined, locale: AdminLocale = 'en'): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? '—'
    : formatDate(iso, locale, { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false });
}

export function fmtDate(iso: string | null | undefined, locale: AdminLocale = 'en'): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? '—'
    : formatDate(iso, locale, { day: '2-digit', month: 'short', year: 'numeric' });
}

export function fmtDayShort(iso: string, locale: AdminLocale = 'en'): string {
  return formatDate(iso, locale, { day: '2-digit', month: 'short' });
}

/** Absolute date strings remain in title attributes at every relative-time call site. */
export function fmtAgo(iso: string | null | undefined, locale: AdminLocale = 'en'): string {
  if (!iso) return t(locale, 'never');
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return '—';
  const secs = Math.round((Date.now() - then) / 1000);
  if (secs < 60) return t(locale, 'just now');
  const mins = Math.round(secs / 60);
  if (mins < 60) return t(locale, '{count}m ago', { count: fmtNum(mins, locale) });
  const hours = Math.round(mins / 60);
  if (hours < 24) return t(locale, '{count}h ago', { count: fmtNum(hours, locale) });
  const days = Math.round(hours / 24);
  if (days < 30) return t(locale, '{count}d ago', { count: fmtNum(days, locale) });
  const months = Math.round(days / 30);
  return months < 12
    ? t(locale, '{count}mo ago', { count: fmtNum(months, locale) })
    : t(locale, '{count}y ago', { count: fmtNum(Math.round(months / 12), locale) });
}

export function fmtNum(n: number | null | undefined, locale: AdminLocale = 'en'): string {
  if (n == null) return '—';
  return new Intl.NumberFormat(locale === 'ar' ? 'ar-EG' : 'en-US').format(n);
}

export function fmtEgp(n: number | null | undefined, locale: AdminLocale = 'en'): string {
  if (n == null) return '—';
  const amount = new Intl.NumberFormat(locale === 'ar' ? 'ar-EG' : 'en-US', { maximumFractionDigits: 0 }).format(n);
  return locale === 'ar' ? `${amount} ج.م.` : `${amount} EGP`;
}

export function fmtDelta(
  current: number,
  previous: number,
  locale: AdminLocale = 'en',
): { text: string; dir: 1 | 0 | -1 } | null {
  if (previous === 0) return current === 0 ? null : { text: t(locale, 'new'), dir: 1 };
  const pct = Math.round(((current - previous) / previous) * 100);
  if (pct === 0) return { text: t(locale, 'flat'), dir: 0 };
  const amount = fmtNum(Math.abs(pct), locale);
  return { text: `${pct > 0 ? '+' : '−'}${amount}%`, dir: pct > 0 ? 1 : -1 };
}

/** Egyptian mobile numbers in a readable grouping: +20 10 1234 5678. */
export function fmtPhone(raw: string | null | undefined): string {
  if (!raw) return '—';
  const digits = raw.replace(/[^\d]/g, '');
  const local = digits.startsWith('20') ? digits.slice(2) : digits;
  if (local.length !== 10) return raw;
  return `+20 ${local.slice(0, 2)} ${local.slice(2, 6)} ${local.slice(6)}`;
}

export function pct(part: number, whole: number): number {
  return whole === 0 ? 0 : Math.round((part / whole) * 100);
}

export function fmtPct(part: number, whole: number, locale: AdminLocale = 'en'): string {
  return `${fmtNum(pct(part, whole), locale)}%`;
}

export function initials(name: string | null | undefined): string {
  const parts = (name ?? '').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '؟';
  const first = [...(parts[0] ?? '')][0] ?? '';
  const second = parts.length > 1 ? ([...(parts[parts.length - 1] ?? '')][0] ?? '') : '';
  return (first + second).toUpperCase();
}

const PROVIDER_KIND_MESSAGE: Record<string, MessageKey> = {
  contractor: 'Contractor', engineer: 'Engineer', engineering_office: 'Engineering office',
  finishing_company: 'Finishing company', interior_designer: 'Interior designer',
  specialized_provider: 'Specialized office/company', tradesman: 'Tradesman',
};

const SPECIALTY_MESSAGE: Record<string, MessageKey> = {
  paint: 'Painting', flooring: 'Flooring', kitchen: 'Kitchens', bathroom: 'Bathrooms',
  electrical: 'Electrical', plumbing: 'Plumbing', carpentry: 'Carpentry', design: 'Interior design',
  full_reno: 'Full renovation', plastering: 'Plastering', gypsum_board: 'Gypsum board and ceilings',
  marble_granite: 'Marble and granite', aluminum_upvc: 'Aluminum and UPVC', hvac: 'Air conditioning and ventilation',
  'flooring:ceramic': 'Ceramic', 'flooring:porcelain': 'Porcelain',
};
const SPECIALTY_PARENT: Record<string, string> = { 'flooring:ceramic': 'flooring', 'flooring:porcelain': 'flooring' };

const APARTMENT_TYPE_MESSAGE: Record<string, MessageKey> = {
  studio: 'Studio',
  one_bedroom: 'One bedroom',
  two_bedroom: 'Two bedrooms',
  three_bedroom_plus: 'Three or more bedrooms',
  duplex: 'Duplex',
  villa: 'Villa',
  penthouse: 'Penthouse',
};

export function formatApartmentType(value: string | null | undefined, locale: AdminLocale): string {
  if (!value) return '—';
  return knownLabel(value, APARTMENT_TYPE_MESSAGE, locale);
}

export function formatProviderKind(value: string | null | undefined, locale: AdminLocale): string {
  if (!value) return '—';
  const key = lookupMessage(value, PROVIDER_KIND_MESSAGE);
  return key ? t(locale, key) : value;
}

export function formatRole(value: string, locale: AdminLocale): string {
  if (value === 'contractor') return t(locale, 'Professional');
  if (value === 'homeowner') return t(locale, 'Homeowner');
  return value;
}

export function formatSpecialties(values: string[] | null | undefined, locale: AdminLocale = 'en'): string {
  const roots: string[] = [];
  const details: string[] = [];
  const seen = new Set<string>();
  for (const raw of values ?? []) {
    const key = raw.trim();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    if (SPECIALTY_PARENT[key]) details.push(key);
    else roots.push(key);
  }
  const label = (key: string) => {
    const message = lookupMessage(key, SPECIALTY_MESSAGE);
    return message ? t(locale, message) : key;
  };
  return [...roots, ...details].map((key) => {
    const parent = SPECIALTY_PARENT[key];
    return parent ? `${label(parent)} · ${label(key)}` : label(key);
  }).join(locale === 'ar' ? '، ' : ', ') || '—';
}

const REPORT_REASON_MESSAGE: Record<string, MessageKey> = {
  spam: 'Spam', scam: 'Scam or fraud', offensive: 'Offensive content', sexual: 'Sexual content',
  violence: 'Violence', impersonation: 'Impersonation', other: 'Other',
};
const TARGET_MESSAGE: Record<string, MessageKey> = {
  post: 'Post', comment: 'Comment', profile: 'Account', brief: 'Job request', review: 'Review',
};
const PURPOSE_MESSAGE: Record<string, MessageKey> = {
  pro: 'Shattab Pro', sponsored: 'Sponsored placement', boost: 'Profile boost',
};
const METHOD_MESSAGE: Record<string, MessageKey> = {
  instapay: 'InstaPay', insta_pay: 'InstaPay', wallet: 'Wallet', bank_transfer: 'Bank transfer',
};
const TERM_MESSAGE: Record<string, MessageKey> = {
  monthly: 'Monthly', month: 'Monthly', quarterly: 'Quarterly', three_months: 'Quarterly',
  yearly: 'Yearly', annual: 'Yearly', year: 'Yearly',
};

function knownLabel(value: string, lookup: Record<string, MessageKey>, locale: AdminLocale): string {
  const key = lookupMessage(value, lookup);
  return key ? t(locale, key) : value;
}

function lookupMessage(value: string, lookup: Record<string, MessageKey>): MessageKey | undefined {
  return Object.prototype.hasOwnProperty.call(lookup, value) ? lookup[value] : undefined;
}

export function formatReportReason(value: string, locale: AdminLocale): string {
  return knownLabel(value, REPORT_REASON_MESSAGE, locale);
}

export function formatReportTarget(value: string, locale: AdminLocale): string {
  return knownLabel(value, TARGET_MESSAGE, locale);
}

export function formatPaymentPurpose(value: string, locale: AdminLocale): string {
  return knownLabel(value, PURPOSE_MESSAGE, locale);
}

export function formatPaymentMethod(value: string, locale: AdminLocale): string {
  return knownLabel(value, METHOD_MESSAGE, locale);
}

export function formatPlanTerm(value: string, locale: AdminLocale): string {
  return knownLabel(value, TERM_MESSAGE, locale);
}
