-- Allow signed-in homeowners to open the same contact-free homeowner profile
-- projection that contractors already use from opportunity details.
-- Private profiles and homeowner_profiles remain owner-only.
drop policy if exists "Read homeowner public profiles" on public.homeowner_public_profiles;

create policy "Read homeowner public profiles"
  on public.homeowner_public_profiles for select
  to authenticated
  using (
    (select auth.uid()) = profile_id
    or exists (
      select 1
      from public.profiles viewer
      where viewer.id = (select auth.uid())
        and viewer.role in ('homeowner', 'contractor')
    )
  );
