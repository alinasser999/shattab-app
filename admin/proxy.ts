import { NextResponse, type NextRequest } from 'next/server';
import { createServerClient, type CookieOptions } from '@supabase/ssr';

/**
 * Refreshes the Supabase session cookie and keeps unauthenticated visitors off
 * the console.
 *
 * This is a redirect, not a security boundary. The boundary is `is_admin()` in
 * Postgres: if this proxy were deleted entirely, a non-admin reaching /users
 * would still see nothing, because the RLS policies and every RPC would refuse
 * them. Treating the proxy as the gate is how "admin panel found by URL
 * guessing" happens.
 */
export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (list: Array<{ name: string; value: string; options: CookieOptions }>) => {
          for (const { name, value } of list) request.cookies.set(name, value);
          response = NextResponse.next({ request });
          for (const { name, value, options } of list) response.cookies.set(name, value, options);
        },
      },
    },
  );

  // getUser(), not getSession(): getSession trusts the cookie as-is, while
  // getUser revalidates it with the auth server. On a privileged surface the
  // extra round trip is the point.
  // Fail closed when the auth service is unavailable. Treating an unverified
  // cookie as an authenticated user would be the dangerous failure mode; a
  // temporary redirect to login is recoverable after the service returns.
  let user: Awaited<ReturnType<typeof supabase.auth.getUser>>['data']['user'] = null;
  try {
    const result = await supabase.auth.getUser();
    user = result.data.user;
  } catch {
    user = null;
  }

  const path = request.nextUrl.pathname;
  const isLogin = path === '/login';

  if (!user && !isLogin) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    // Preserve where they were headed so login lands them there, but only the
    // path — never the query string, which could carry an id we would then echo.
    url.search = path === '/' ? '' : `?next=${encodeURIComponent(path)}`;
    return NextResponse.redirect(url);
  }

  // Do not redirect signed-in users away from /login here. The console layout
  // may send a signed-in non-admin back to this route with an access-denied
  // message; redirecting again would create /login -> / -> /login forever.
  // LoginPage handles the nicer admin-only shortcut after it can ask the
  // database whether the user actually has console access.

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\.png$).*)'],
};
