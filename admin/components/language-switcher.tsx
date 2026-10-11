'use client';

import { useRouter } from 'next/navigation';
import { t, type AdminLocale } from '@/lib/i18n';

export function LanguageSwitcher({ locale }: { locale: AdminLocale }) {
  const router = useRouter();

  function changeLanguage(value: string) {
    if (value !== 'en' && value !== 'ar') return;
    const secure = window.location.protocol === 'https:' ? '; Secure' : '';
    document.cookie = `admin_locale=${value}; Path=/; Max-Age=31536000; SameSite=Lax${secure}`;
    router.refresh();
  }

  return (
    <label className="flex min-w-0 items-center gap-2 text-xs text-ink-3">
      <span>{t(locale, 'Language')}</span>
      <select
        aria-label={t(locale, 'Language')}
        value={locale}
        onChange={(event) => changeLanguage(event.target.value)}
        className="h-8 min-w-0 rounded-md border border-line-strong bg-panel px-2 text-xs text-ink"
      >
        <option value="en">English</option>
        <option value="ar">العربية المبسّطة</option>
      </select>
    </label>
  );
}
