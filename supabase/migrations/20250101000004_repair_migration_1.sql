-- =============================================================================
-- Repair: the first migration's script appears to have stopped partway
-- through (confirmed: profiles has RLS *enabled* but zero policies and no
-- grants; is_admin/current_role/request_seller_upgrade/review_seller_request
-- never got created). Nothing broke visibly because every read/write so far
-- went through SECURITY DEFINER RPCs, which bypass RLS entirely.
--
-- Everything below is written to be safe to run regardless of exactly how
-- much of migration 1 actually landed — CREATE OR REPLACE / IF NOT EXISTS /
-- DROP POLICY IF EXISTS + CREATE POLICY throughout, so re-running this is
-- harmless even if some pieces already exist.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- seller_upgrade_requests (in case it never got created)
-- ---------------------------------------------------------------------------
create table if not exists public.seller_upgrade_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  message text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references auth.users (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists seller_upgrade_requests_user_id_idx
  on public.seller_upgrade_requests (user_id);

create unique index if not exists seller_upgrade_requests_one_pending_per_user
  on public.seller_upgrade_requests (user_id)
  where status = 'pending';

-- ---------------------------------------------------------------------------
-- Helper functions
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
-- RLS (drop-then-create so this is safe to re-run)
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.seller_upgrade_requests enable row level security;

drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
  on public.profiles for select
  using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "seller_requests_select_own_or_admin" on public.seller_upgrade_requests;
create policy "seller_requests_select_own_or_admin"
  on public.seller_upgrade_requests for select
  using (user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- Grants (re-granting an existing privilege is a harmless no-op)
-- ---------------------------------------------------------------------------
grant select on public.profiles to authenticated;
grant update (full_name) on public.profiles to authenticated;

grant select on public.seller_upgrade_requests to authenticated;

grant execute on function public.request_seller_upgrade(text) to authenticated;
grant execute on function public.review_seller_request(uuid, boolean) to authenticated;
grant execute on function public.current_role() to authenticated;
grant execute on function public.is_admin() to authenticated;

-- has_password / ensure_profile from migrations 2 & 3 reference profiles —
-- re-apply those grants too in case they were skipped for the same reason.
grant execute on function public.mark_password_set() to authenticated;
grant execute on function public.ensure_profile() to authenticated;
