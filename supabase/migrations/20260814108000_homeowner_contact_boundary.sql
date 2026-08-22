-- Contractor contact is a detail-surface capability, not a public profile
-- read. Authorize it against the brief so a profile id cannot be turned into
-- an arbitrary homeowner phone directory.

create or replace function public.get_homeowner_contact_for_brief(
  p_brief_id uuid
)
returns table(full_name text, phone text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select owner.full_name, owner.phone
  from public.briefs b
  join public.profiles owner on owner.id = b.homeowner_id
  join public.profiles viewer on viewer.id = (select auth.uid())
  where b.id = p_brief_id
    and viewer.role = 'contractor'
    and (
      b.target_contractor_id = viewer.id
      or (
        b.target_contractor_id is null
        and b.status = 'open'
        and exists (
          select 1
          from public.contractor_profiles cp
          where cp.profile_id = viewer.id
            and b.target_specialties && cp.specialties
            and b.city = any (cp.service_areas)
        )
      )
      or exists (
        select 1
        from public.quotes q
        where q.brief_id = b.id
          and q.contractor_id = viewer.id
      )
    );
$$;

revoke all on function public.get_homeowner_contact_for_brief(uuid)
  from public, anon, authenticated;
grant execute on function public.get_homeowner_contact_for_brief(uuid)
  to authenticated;

comment on function public.get_homeowner_contact_for_brief(uuid) is
  'Returns homeowner contact only to a contractor authorized for the brief; never use with a standalone profile id.';
