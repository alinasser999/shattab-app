-- A suspended account could keep editing content it had already created:
-- tg_reject_if_suspended() was only wired to BEFORE INSERT (0027), while
-- every one of these tables also has client-facing UPDATE policies.
-- Compose the same check onto UPDATE with a sibling trigger name so the
-- original INSERT trigger is untouched.

do $$
declare
  t text;
begin
  foreach t in array array['posts', 'post_comments', 'quotes', 'briefs', 'reviews']
  loop
    execute format('drop trigger if exists reject_if_suspended_update on public.%I', t);
    execute format(
      'create trigger reject_if_suspended_update before update on public.%I
         for each row execute function public.tg_reject_if_suspended()', t);
  end loop;
end;
$$;
