-- =============================================================================
-- Extend ensure_profile() to also return the storefront fields
-- (avatar_url, bio, city) added later in 20250101000006 — the client needs
-- these to render a seller's own avatar/bio right after editing their
-- profile, the same way it already reads role/full_name/has_password.
--
-- Return type is changing, so the old function must be dropped first —
-- `create or replace` alone rejects a changed signature.
-- =============================================================================

drop function if exists public.ensure_profile();

create function public.ensure_profile()
returns table (
  role public.app_role,
  has_password boolean,
  full_name text,
  avatar_url text,
  bio text,
  city_id bigint,
  city_name text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, has_password)
  select
    auth.uid(),
    u.raw_user_meta_data ->> 'full_name',
    'kupac',
    coalesce(u.raw_app_meta_data ->> 'provider', '') = 'email'
  from auth.users u
  where u.id = auth.uid()
  on conflict (id) do nothing;

  return query
    select p.role, p.has_password, p.full_name, p.avatar_url, p.bio,
           p.city_id, c.name
    from public.profiles p
    left join public.cities c on c.id = p.city_id
    where p.id = auth.uid();
end;
$$;

grant execute on function public.ensure_profile() to authenticated;
