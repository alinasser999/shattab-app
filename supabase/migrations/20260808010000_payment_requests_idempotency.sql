-- Stop a retried payment submission from creating a second claim.
--
-- Every other table behind a repeatable user action is already protected by a
-- natural key: post_likes PK(post_id,user_id), post_saves PK(post_id,user_id),
-- saved_contractors PK(homeowner_id,contractor_id), quotes
-- UNIQUE(brief_id,contractor_id), reviews UNIQUE(brief_id), notifications
-- UNIQUE(recipient_id,dedupe_key). payment_requests had only PRIMARY KEY(id),
-- so it was the one money-carrying table where a retry duplicated the row.
--
-- The client guards with a loading flag, but that is client state: a request
-- that reaches Postgres and commits, then loses its response to a dropped
-- connection, leaves the user looking at a failure they will reasonably retry.
-- Two pending rows for one bank transfer, both approvable by an admin.
--
-- Why not a natural key here. The obvious candidate --
-- UNIQUE(contractor_id, purpose, plan_term, amount_egp) WHERE pending -- would
-- reject a legitimate case: `boost` carries no job reference, so a contractor
-- promoting two different jobs at 49 EGP each is indistinguishable from a
-- double submit. Blocking that would be a product regression disguised as a
-- constraint. An idempotency key separates "the same attempt, sent twice" from
-- "two attempts" without the database having to guess which it is.
--
-- Nullable, and the index is partial on NOT NULL, so every existing row and any
-- older client that does not send a key keeps working unchanged.

alter table public.payment_requests
  add column if not exists idempotency_key text;

comment on column public.payment_requests.idempotency_key is
  'Client-generated per submission attempt, reused across retries of that same '
  'attempt. Scoped to contractor_id by the unique index; NULL for pre-existing '
  'rows and older clients.';

create unique index if not exists payment_requests_idempotency_uidx
  on public.payment_requests (contractor_id, idempotency_key)
  where idempotency_key is not null;
