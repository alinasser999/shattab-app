import type { Metadata, Viewport } from 'next';
import { Inter, Noto_Sans_Arabic } from 'next/font/google';
import { getAdminLocale } from '@/lib/locale';
import { t } from '@/lib/i18n';
import './globals.css';

// One family carries headings, labels, data and buttons — product UI does not
// need a display/body pairing. The Arabic face is a script fallback for names
// and report text, not a second voice: adding it does not make this two fonts
// competing for the same role.
const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});

const arabic = Noto_Sans_Arabic({
  subsets: ['arabic'],
  variable: '--font-arabic-sans',
  display: 'swap',
});

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getAdminLocale();
  return {
    title: t(locale, 'Shattab Admin'),
    description: t(locale, 'Operations console for Shattab.'),
    icons: { icon: '/icon.png' },
    // A privileged surface has no business in a search index.
    robots: { index: false, follow: false },
  };
}

export const viewport: Viewport = { themeColor: '#2b201a' };

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const locale = await getAdminLocale();
  return (
    <html lang={locale} dir={locale === 'ar' ? 'rtl' : 'ltr'} className={`${inter.variable} ${arabic.variable}`}>
      <body>{children}</body>
    </html>
  );
}
