'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabaseBrowser } from '@/lib/supabase/client';
import { Button, Input, Label, Panel } from '@/components/ui';
import { LanguageSwitcher } from '@/components/language-switcher';
import { t, type AdminLocale, type MessageKey } from '@/lib/i18n';

type LoginErrorKey = Extract<
  MessageKey,
  | 'Enter your email address.'
  | 'Enter a valid email address.'
  | 'Enter your password.'
  | 'Sign in failed. Check your credentials and try again.'
>;

/**
 * Email and password sign-in for the console.
 *
 * The app authenticates with phone OTP; this console deliberately does not. An
 * ops tool that depends on SMS delivery costs money per login, breaks when the
 * provider has an outage, and is unusable from any machine not holding the
 * founder's phone. Those are all reasons to keep consumer auth and operator auth
 * separate — the SMS bill during development is only the most visible one.
 *
 * Being an admin is not decided here. This screen proves who you are; the
 * database decides what that is worth. Signing in with an ordinary account
 * succeeds and then shows nothing, which is the correct outcome.
 */
export function LoginForm({ next, denied = false, locale }: { next: string; denied?: boolean; locale: AdminLocale }) {
  const router = useRouter();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<LoginErrorKey | null>(null);

  async function signIn(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    const emailField = form.elements.namedItem('email');
    const passwordField = form.elements.namedItem('password');
    if (emailField instanceof HTMLInputElement && !emailField.value.trim()) {
      setError('Enter your email address.');
      return;
    }
    if (emailField instanceof HTMLInputElement && emailField.validity.typeMismatch) {
      setError('Enter a valid email address.');
      return;
    }
    if (passwordField instanceof HTMLInputElement && !passwordField.value) {
      setError('Enter your password.');
      return;
    }
    setBusy(true);
    setError(null);

    const { error: err } = await supabaseBrowser().auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (err) {
      setBusy(false);
      // Supabase says "Invalid login credentials" without revealing which half
      // was wrong. That is worth preserving rather than "improving": a message
      // distinguishing a bad password from an unknown email turns this form into
      // an account-enumeration oracle.
      setError('Sign in failed. Check your credentials and try again.');
      return;
    }

    // A full navigation rather than a client-side push. The session cookie was
    // only just written, and the proxy has to see it on a fresh request.
    router.replace(next);
    router.refresh();
  }

  return (
    <main className="grid min-h-dvh place-items-center px-5 py-12">
      <div className="w-full max-w-[23rem]">
        <div className="mb-4 flex justify-end">
          <LanguageSwitcher locale={locale} />
        </div>
        <div className="mb-7 flex items-baseline gap-2.5">
          <span className="text-lg font-semibold tracking-tight text-ink">Shattab</span>
          <span className="text-sm text-accent-ink">{t(locale, 'Admin')}</span>
        </div>

        <Panel className="p-5">
          <h1 className="text-md font-semibold text-ink">{t(locale, 'Sign in')}</h1>
          <p className="mt-1 text-sm text-ink-3">
            {t(locale, 'Operator accounts use email and password. Separate from the app, which signs in by phone.')}
          </p>

          {denied ? (
            <div role="alert" className="mt-4 rounded-md border border-line-strong bg-raised px-3 py-2.5">
              <p className="text-sm font-medium text-ink">{t(locale, 'This account is not an admin.')}</p>
              <p className="mt-0.5 text-xs text-ink-2">
                {t(locale, 'Sign out, then use an operator account to enter the console.')}
              </p>
              <form action="/api/signout" method="post" className="mt-2">
                <Button type="submit" variant="secondary" size="sm">{t(locale, 'Sign out')}</Button>
              </form>
            </div>
          ) : null}

          <form onSubmit={signIn} noValidate className="mt-5">
            <Label htmlFor="email">{t(locale, 'Email')}</Label>
            <Input
              id="email"
              name="email"
              type="email"
              autoComplete="username"
              dir="ltr"
              aria-describedby={error ? 'login-error' : undefined}
              placeholder={t(locale, 'you@example.com')}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoFocus
            />

            <div className="mt-3">
              <Label htmlFor="password">{t(locale, 'Password')}</Label>
              <Input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                dir="ltr"
                aria-describedby={error ? 'login-error' : undefined}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>

            {error ? (
              // role=alert so a failure is announced, not merely recoloured.
              <p id="login-error" role="alert" className="mt-2 text-xs text-danger">
                {t(locale, error)}
              </p>
            ) : null}

            <Button type="submit" variant="primary" loading={busy} className="mt-4 w-full">
              {busy ? t(locale, 'Signing in…') : t(locale, 'Sign in')}
            </Button>
          </form>
        </Panel>

        <p className="mt-4 text-xs text-ink-3">
          {t(locale, 'Admin access is granted per account in the database. Signing in does not grant it. Lost the password? Reset it from the Supabase dashboard.')}
        </p>
      </div>
    </main>
  );
}
