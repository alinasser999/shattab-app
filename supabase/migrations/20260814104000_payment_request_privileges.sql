-- Remove legacy table privileges. Payment requests are read-only to the
-- authenticated owner/admin paths; creation is only through the server RPC.
revoke all on table public.payment_requests from public, anon, authenticated;
grant select on table public.payment_requests to authenticated;
