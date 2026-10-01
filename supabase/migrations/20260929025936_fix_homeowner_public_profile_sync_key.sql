-- Resolve the source key from the row type that fired the trigger.
-- profiles uses id, while homeowner_profiles uses profile_id.
create or replace function public.tg_sync_homeowner_public_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_role text;
begin
  if tg_table_name = 'profiles' then
    v_profile_id := new.id;
  elsif tg_table_name = 'homeowner_profiles' then
    v_profile_id := case
      when tg_op = 'DELETE' then old.profile_id
      else new.profile_id
    end;
  else
    raise exception 'Unsupported table for homeowner public profile sync: %',
      tg_table_name
      using errcode = '0A000';
  end if;

  select p.role
    into v_role
  from public.profiles p
  where p.id = v_profile_id;

  if v_role is distinct from 'homeowner' then
    delete from public.homeowner_public_profiles
    where profile_id = v_profile_id;
  else
    insert into public.homeowner_public_profiles (
      profile_id,
      role,
      full_name,
      avatar_url,
      apartment_type,
      city,
      district,
      renovation_interests,
      updated_at
    )
    select
      p.id,
      'homeowner',
      p.full_name,
      p.avatar_url,
      h.apartment_type,
      h.city,
      h.district,
      coalesce(h.renovation_interests, '{}'),
      now()
    from public.profiles p
    left join public.homeowner_profiles h on h.profile_id = p.id
    where p.id = v_profile_id
    on conflict (profile_id) do update set
      role = excluded.role,
      full_name = excluded.full_name,
      avatar_url = excluded.avatar_url,
      apartment_type = excluded.apartment_type,
      city = excluded.city,
      district = excluded.district,
      renovation_interests = excluded.renovation_interests,
      updated_at = now();
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke execute on function public.tg_sync_homeowner_public_profile()
  from public, anon, authenticated;
