import { redirect } from 'next/navigation';
import { currentAdmin } from '@/lib/supabase/server';
import { LoginForm } from './form';

/**
 * Server wrapper around the sign-in form.
 *
 * The redirect target is read here and handed down as a prop instead of being
 * pulled from useSearchParams() inside the client component. That hook forces a
 * client-side bailout during prerender, and wrapping it in Suspense would only
 * hide the problem — the server already has the value.
 */
export const dynamic = 'force-dynamic';

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string; denied?: string }>;
}) {
  const { next, denied } = await searchParams;

  // Keep the convenience redirect for a real admin, but leave authenticated
  // non-admins on this page so the console does not bounce them indefinitely.
  if (denied !== '1' && (await currentAdmin())) redirect('/');

  // Only same-origin absolute paths. Without this check, /login?next=https://…
  // would turn a successful sign-in into an open redirect off the console.
  const target = next && next.startsWith('/') && !next.startsWith('//') ? next : '/';

  return <LoginForm next={target} denied={denied === '1'} />;
}
