import { cookies } from 'next/headers';
import type { AdminLocale } from './i18n';

export const ADMIN_LOCALE_COOKIE = 'admin_locale';

export function isAdminLocale(value: unknown): value is AdminLocale {
  return value === 'en' || value === 'ar';
}

export async function getAdminLocale(): Promise<AdminLocale> {
  try {
    const store = await cookies();
    const value = store.get(ADMIN_LOCALE_COOKIE)?.value;
    return isAdminLocale(value) ? value : 'en';
  } catch {
    return 'en';
  }
}
