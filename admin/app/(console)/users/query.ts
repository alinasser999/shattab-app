/**
 * URL state for the users table.
 *
 * Lives outside page.tsx because a Next route file may only export a fixed set
 * of names (default, dynamic, metadata, and friends). Exporting a helper from
 * page.tsx compiles under `tsc --noEmit` and then fails the real build, which is
 * why the build is the check that counts.
 */
export type Query = {
  q?: string;
  role?: string;
  status?: string;
  page?: string;
  user?: string;
  done?: string;
  error?: string;
};

/**
 * Rebuilds the current URL with some params replaced. Keeps the active filters
 * when opening a row, which is the difference between a usable table and one
 * that resets every time you look at something.
 *
 * `done` and `error` are deliberately dropped: carrying a stale success banner
 * into the next navigation makes it look like the new action succeeded too.
 */
export function buildHref(sp: Query, patch: Partial<Query>): string {
  const merged = { ...sp, ...patch };
  const next = new URLSearchParams();
  for (const key of ['q', 'role', 'status', 'page', 'user'] as const) {
    const value = merged[key];
    if (value) next.set(key, value);
  }
  const qs = next.toString();
  return qs ? `/users?${qs}` : '/users';
}
