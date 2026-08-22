-- The Flutter app uses discover_contractors_cursor for public search. Keep the
-- old offset function for already released authenticated clients, but remove
-- its anonymous execute grant so a legacy broad projection cannot remain a
-- public security-definer entry point indefinitely.

revoke execute on function public.discover_contractors(text, text, text, int, int)
  from public, anon;
grant execute on function public.discover_contractors(text, text, text, int, int)
  to authenticated;
