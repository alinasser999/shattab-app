import { cookies } from 'next/headers';
import { createServerClient, type CookieOptions } from '@supabase/ssr';

/**
 * Server-side Supabase client, bound to the request's cookies.
 *
 * The anon key is the ONLY key this project holds. There is no service-role
 * client anywhere, deliberately: every admin capability is gated by
 * `public.is_admin()` inside Postgres, so a mistake in this app's routing or
 * middleware cannot widen access. A service-role client would invert that —
 * the web layer would become the only thing standing between a bug and the
 * whole database.
 */
export async function supabaseServer() {
  const store = await cookies();

  return createServerClient(env('NEXT_PUBLIC_SUPABASE_URL'), env('NEXT_PUBLIC_SUPABASE_ANON_KEY'), {
    cookies: {
      getAll: () => store.getAll(),
      setAll: (list: Array<{ name: string; value: string; options: CookieOptions }>) => {
        try {
          for (const { name, value, options } of list) store.set(name, value, options);
        } catch {
          // Server Components cannot set cookies. The proxy refreshes the
          // session on every request, so a failure here is expected and safe to
          // swallow — this is the one place where doing so is not a silent bug.
        }
      },
    },
  });
}

function env(key: 'NEXT_PUBLIC_SUPABASE_URL' | 'NEXT_PUBLIC_SUPABASE_ANON_KEY'): string {
  const value = process.env[key];
  // Failing loudly at first use beats a runtime "Invalid URL" ten frames deep,
  // and beats silently pointing at undefined.
  if (!value) throw new Error(`Missing ${key}. Copy admin/.env.local.example to admin/.env.local.`);
  return value;
}

/**
 * The signed-in admin, or null.
 *
 * `is_admin()` is asked of the database rather than inferred from a claim in the
 * JWT: the database is what enforces it, so the console must not disagree with
 * it. A user who is signed in but not an admin gets null, same as a stranger.
 */
export async function currentAdmin() {
  const supabase = await supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (!isAdmin) return null;

  const { data: level, error: levelError } = await supabase.rpc('admin_level');
  // The level is what turns the broad admin read boundary into a least-
  // privilege write boundary. If the migration is missing or the RPC fails,
  // do not silently treat an unknown level as owner access.
  if (levelError || (level !== 'owner' && level !== 'moderator')) return null;

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, full_name, phone, role')
    .eq('id', user.id)
    .maybeSingle();

  return {
    id: user.id,
    phone: user.phone ?? profile?.phone ?? '',
    name: profile?.full_name ?? '',
    level: level === 'owner' ? 'owner' : 'moderator',
  };
}
