'use client';

import { createBrowserClient } from '@supabase/ssr';

/** Browser client. Used only by the login form — every read and write on the
 *  authenticated surface happens on the server. */
export function supabaseBrowser() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
