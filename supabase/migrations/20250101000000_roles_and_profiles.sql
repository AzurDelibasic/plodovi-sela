-- =============================================================================
-- Plodovi sela — roles & profiles
--
-- Design:
--   * `role` lives in public.profiles, NOT in auth.users.user_metadata — the
--     user metadata is client-editable (supabase.auth.updateUser), so storing
--     a security-relevant field there would let anyone promote themselves.
--   * Every account starts as 'kupac' (buyer) automatically via a trigger on
--     auth.users. There is no self-service way to become 'prodavac' or
--     'admin' — those changes only ever happen through SECURITY DEFINER RPCs
--     below, which re-check permissions server-side regardless of what the
--     client claims.
--   * 'admin' is never granted through the app. After creating your own
--     account normally, promote it manually once via the SQL editor:
--       update public.profiles set role = 'admin' where id = '<your-uuid>';
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Role enum
-- ---------------------------------------------------------------------------
create type public.app_role as enum ('kupac', 'prodavac', 'admin');

-- ---------------------------------------------------------------------------
-- 2. Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role public.app_role not null default 'kupac',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'One row per auth.users. Holds the user''s role and public profile info. '
  'The role column must never be updated directly by clients — only through '
  'the review_seller_request() RPC or manually by a project admin.';

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile (role='kupac') whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, new.raw_user_meta_data ->> 'full_name', 'kupac');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 3. Seller upgrade requests (kupac -> prodavac, admin-reviewed)
-- ---------------------------------------------------------------------------
create table public.seller_upgrade_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  message text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references auth.users (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.seller_upgrade_requests is
  'Requests from a kupac to become a prodavac. Only ever written through '
  'request_seller_upgrade() / review_seller_request() — never a direct '
  'client-side INSERT/UPDATE.';

create index seller_upgrade_requests_user_id_idx
  on public.seller_upgrade_requests (user_id);

-- At most one pending request per user at a time.
create unique index seller_upgrade_requests_one_pending_per_user
  on public.seller_upgrade_requests (user_id)
  where status = 'pending';

-- ---------------------------------------------------------------------------
-- 4. Security-definer helpers (used inside RLS policies to avoid recursive
--    RLS lookups on public.profiles referencing itself)
-- ---------------------------------------------------------------------------
create or replace function public.current_role()
returns public.app_role
language sql
security definer
set search_path = public
stable
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------------
-- 5. Business-rule RPCs (the ONLY way role/status ever change)
-- ---------------------------------------------------------------------------
create or replace function public.request_seller_upgrade(note text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  my_role public.app_role;
begin
  select role into my_role from public.profiles where id = auth.uid();

  if my_role is distinct from 'kupac' then
    raise exception 'Samo kupci mogu zatražiti da postanu prodavci.';
  end if;

  if exists (
    select 1 from public.seller_upgrade_requests
    where user_id = auth.uid() and status = 'pending'
  ) then
    raise exception 'Već imate zahtjev na čekanju.';
  end if;

  insert into public.seller_upgrade_requests (user_id, message)
  values (auth.uid(), note)
  returning id into new_id;

  return new_id;
end;
$$;

create or replace function public.review_seller_request(
  request_id uuid,
  approve boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user uuid;
begin
  if not public.is_admin() then
    raise exception 'Samo administrator može odobriti/odbiti zahtjev.';
  end if;

  select user_id into target_user
  from public.seller_upgrade_requests
  where id = request_id and status = 'pending'
  for update;

  if target_user is null then
    raise exception 'Zahtjev ne postoji ili je već obrađen.';
  end if;

  update public.seller_upgrade_requests
    set status = case when approve then 'approved' else 'rejected' end,
        reviewed_by = auth.uid(),
        reviewed_at = now()
    where id = request_id;

  if approve then
    update public.profiles set role = 'prodavac' where id = target_user;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.seller_upgrade_requests enable row level security;

create policy "profiles_select_own_or_admin"
  on public.profiles for select
  using (id = auth.uid() or public.is_admin());

create policy "profiles_update_own"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "seller_requests_select_own_or_admin"
  on public.seller_upgrade_requests for select
  using (user_id = auth.uid() or public.is_admin());

-- Deliberately no INSERT/UPDATE policies on either table for regular users:
-- profiles rows are created only by the handle_new_user() trigger, and role /
-- request-status changes only happen inside the SECURITY DEFINER RPCs above,
-- which run as the function owner and bypass RLS for their own writes.

-- ---------------------------------------------------------------------------
-- 7. Grants (least privilege — this project has "expose new tables" off,
--    so nothing is reachable until explicitly granted here)
-- ---------------------------------------------------------------------------
grant select on public.profiles to authenticated;
grant update (full_name) on public.profiles to authenticated;

grant select on public.seller_upgrade_requests to authenticated;

grant execute on function public.request_seller_upgrade(text) to authenticated;
grant execute on function public.review_seller_request(uuid, boolean) to authenticated;
grant execute on function public.current_role() to authenticated;
grant execute on function public.is_admin() to authenticated;
