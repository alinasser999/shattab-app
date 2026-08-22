import { redirect } from 'next/navigation';
import Image from 'next/image';
import { currentAdmin, supabaseServer } from '@/lib/supabase/server';
import { Nav } from '@/components/nav';
import { Button } from '@/components/ui';

/**
 * Shell for every authenticated page.
 *
 * The admin check lives here rather than only in the proxy because the proxy
 * knows whether you are signed in, not whether you are an admin. A signed-in
 * non-admin would otherwise reach the layout and see chrome around a set of
 * empty panels, which looks like a broken console instead of a closed door.
 */
export default async function ConsoleLayout({ children }: { children: React.ReactNode }) {
  const admin = await currentAdmin();
  if (!admin) redirect('/login?denied=1');

  // Queue counts drive the sidebar badges. Read here so every page shows the
  // same numbers and no page has to fetch them again.
  const supabase = await supabaseServer();
  const { data: overview } = await supabase.rpc('admin_overview');
  const queues = (overview?.queues ?? { verification: 0, payment: 0, reports: 0 }) as {
    verification: number;
    payment: number;
    reports: number;
  };

  return (
    <div className="min-h-dvh md:grid md:grid-cols-[13.5rem_1fr]">
      {/* The sidebar is a second neutral layer, one step off the content surface,
          so the two never read as one continuous slab. */}
      <aside className="flex flex-col gap-5 border-b border-line bg-surface px-3 py-4 md:sticky md:top-0 md:h-dvh md:border-b-0 md:border-r">
        <div className="flex items-center gap-2 px-1.5">
          <Image src="/icon.png" alt="" width={22} height={22} className="rounded-sm" priority />
          <span className="text-sm font-semibold tracking-tight text-ink">Shattab</span>
          <span className="text-xs text-accent-ink">Admin</span>
        </div>

        <Nav queues={queues} />

        <div className="mt-auto border-t border-line pt-3">
          <p className="truncate px-1.5 text-xs text-ink-2" dir="auto" title={admin.phone}>
            {admin.name || admin.phone || 'Admin'}
          </p>
          <p className="px-1.5 text-2xs text-ink-3">
            {admin.level === 'owner'
              ? 'Owner access'
              : admin.level === 'moderator'
                ? 'Moderator access'
                : 'Admin access'}
          </p>
          {/* A form POST, not a link: sign-out must not be reachable by GET. */}
          <form action="/api/signout" method="post" className="mt-1.5">
            <Button type="submit" variant="ghost" size="sm" className="w-full justify-start">
              Sign out
            </Button>
          </form>
        </div>
      </aside>

      <main className="min-w-0 px-4 py-5 md:px-6 md:py-7">{children}</main>
    </div>
  );
}
