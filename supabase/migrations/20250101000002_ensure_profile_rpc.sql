-- =============================================================================
-- Fix: the on_auth_user_created trigger on auth.users never actually
-- existed (confirmed via diagnostics — function existed, trigger didn't),
-- even though its migration reported success. Triggers directly on
-- auth.users are known to sometimes get wiped by Supabase's own managed
-- upgrades of the auth schema, so depending on one for something this
-- important is fragile.
--
-- Fix: stop depending on the trigger. `ensure_profile()` is called by the
-- app on every sign-in (see AuthRemoteDataSource._fetchProfile) and
-- idempotently creates the profile row if it's missing, then returns it —
-- so a profile always exists by the time the app reads it, regardless of
-- whether any trigger fired.
-- =============================================================================

-- Re-create the trigger anyway, best-effort — harmless if it works, and
-- means new sign-ups get their profile a moment earlier.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.ensure_profile()
returns table (role public.app_role, has_password boolean, full_name text)
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
    select p.role, p.has_password, p.full_name
    from public.profiles p
    where p.id = auth.uid();
end;
$$;

grant execute on function public.ensure_profile() to authenticated;

-- mark_password_set() had the same fragility: if the profile row somehow
-- doesn't exist yet, a plain UPDATE silently affects zero rows. Upsert
-- instead so it's correct no matter what ran before it.
create or replace function public.mark_password_set()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, has_password)
  values (auth.uid(), null, 'kupac', true)
  on conflict (id) do update set has_password = true;
end;
$$;
