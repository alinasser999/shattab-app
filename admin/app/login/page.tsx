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
  searchParams: Promise<{ next?: string }>;
}) {
  const { next } = await searchParams;

  // Only same-origin absolute paths. Without this check, /login?next=https://…
  // would turn a successful sign-in into an open redirect off the console.
  const target = next && next.startsWith('/') && !next.startsWith('//') ? next : '/';

  return <LoginForm next={target} />;
}
