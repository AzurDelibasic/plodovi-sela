-- =============================================================================
-- Fix: track "does this account have an e-mail/password sign-in method" as
-- our own column on public.profiles, instead of relying on the Supabase
-- Auth API's `user.identities` field.
--
-- Why: `identities` is only reliably populated on some auth responses
-- (e.g. right after an OAuth code exchange) but not others (e.g. the
-- response from a plain e-mail+password sign-in) — so a Google-only user
-- who *did* successfully set a password kept getting sent back to
-- /set-password on their next login, because the client-side check read
-- an incomplete `identities` list and concluded (incorrectly) that no
-- password had been set.
-- =============================================================================

alter table public.profiles
  add column has_password boolean not null default false;

-- New accounts: true for a normal e-mail+password sign-up, false for a
-- Google-only sign-up (auth.users.raw_app_meta_data.provider reflects how
-- the account was actually created, set server-side — unlike user_metadata,
-- the client can't influence it).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, has_password)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    'kupac',
    coalesce(new.raw_app_meta_data ->> 'provider', '') = 'email'
  );
  return new;
end;
$$;

-- Called by the app right after auth.updateUser() successfully adds a
-- password to a Google-only account.
create or replace function public.mark_password_set()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set has_password = true where id = auth.uid();
end;
$$;

grant execute on function public.mark_password_set() to authenticated;

-- One-time backfill for accounts created before this column existed:
-- anyone with an 'email' identity in auth.identities already has a
-- password and shouldn't be sent through the set-password screen.
update public.profiles p
set has_password = true
where exists (
  select 1 from auth.identities i
  where i.user_id = p.id and i.provider = 'email'
);
