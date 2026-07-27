import { NextResponse } from 'next/server';
import { supabaseServer } from '@/lib/supabase/server';

/**
 * POST-only sign-out. A GET route here would let any page on the internet log
 * the admin out with an <img src>, and would be pre-fetched by the browser.
 */
export async function POST(request: Request) {
  const supabase = await supabaseServer();
  await supabase.auth.signOut();
  return NextResponse.redirect(new URL('/login', request.url), { status: 303 });
}
