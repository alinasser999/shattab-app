-- Cover the foreign keys the performance advisor flagged.
--
-- An unindexed FK costs twice. Reads that filter or join on it fall back to a
-- sequential scan, and — less obviously — every DELETE or UPDATE of the
-- referenced parent row has to scan the whole child table to enforce the
-- constraint. `profiles` cascades on delete to most of these, so account
-- deletion gets slower in proportion to total table size rather than to how
-- much that one account actually wrote.
--
-- Only Shattab's own tables are covered here. The mokawen tables the advisor
-- also flags belong to another product and were locked down in
-- 20260808001500; indexing them would be maintaining schema this app does not
-- own.

-- Comment author. Read on every comment list and on account deletion.
create index if not exists post_comments_user_id_idx
  on public.post_comments (user_id);

-- Review author. Cascade target when a homeowner deletes their account.
create index if not exists reviews_homeowner_id_idx
  on public.reviews (homeowner_id);

-- The reverse direction of the saved list: "who saved this contractor", and
-- the cascade when a contractor account is removed.
create index if not exists saved_contractors_contractor_id_idx
  on public.saved_contractors (contractor_id);

-- Notification actor. Nullable with ON DELETE SET NULL, so an account deletion
-- rewrites every notification that account triggered.
create index if not exists notifications_actor_id_idx
  on public.notifications (actor_id);

-- Posts linked to a portfolio project; read when a project is opened or
-- deleted.
create index if not exists posts_portfolio_project_id_idx
  on public.posts (portfolio_project_id);

-- Audit actor. The admin console filters activity by actor, and this table is
-- append-only so it grows without bound.
create index if not exists admin_audit_log_actor_id_idx
  on public.admin_audit_log (actor_id);
