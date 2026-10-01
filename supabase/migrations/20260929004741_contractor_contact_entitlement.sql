-- Contact access is an entitlement tied to an open brief or the accepted
-- contractor quote. Keep contact lookup brief-scoped; never expose a profile
-- directory through the Data API.

create or replace function public.get_homeowner_contact_for_brief(
  p_brief_id uuid
)
returns table(full_name text, phone text)
language sql
stable
security definer
set search_path = ''
as $$
  select owner.full_name, owner.phone
  from public.briefs b
  join public.profiles owner on owner.id = b.homeowner_id
  where b.id = p_brief_id
    and (select auth.uid()) is not null
    and exists (
      select 1
      from public.profiles viewer
      where viewer.id = (select auth.uid())
        and viewer.role = 'contractor'
    )
    and (
      exists (
        select 1
        from public.quotes q
        where q.brief_id = b.id
          and q.contractor_id = (select auth.uid())
          and q.status = 'accepted'
      )
      or (
        b.status = 'open'
        and not exists (
          select 1
          from public.quotes accepted
          where accepted.brief_id = b.id
            and accepted.status = 'accepted'
        )
        and exists (
          select 1
          from public.contractor_profiles cp
          where cp.profile_id = (select auth.uid())
            and cp.plan = 'pro'
            and cp.plan_expires_at > now()
            and (
              b.target_contractor_id = (select auth.uid())
              or (
                b.target_contractor_id is null
                and b.target_specialties && cp.specialties
                and b.city = any (cp.service_areas)
              )
            )
        )
      )
    );
$$;

revoke all on function public.get_homeowner_contact_for_brief(uuid)
  from public, anon, authenticated;
grant execute on function public.get_homeowner_contact_for_brief(uuid)
  to authenticated;

comment on function public.get_homeowner_contact_for_brief(uuid) is
  'Returns homeowner contact to an active Pro contractor authorized for an open brief, or to the contractor with its accepted quote.';
