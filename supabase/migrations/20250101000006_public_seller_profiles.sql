-- =============================================================================
-- Public seller ("farm") profiles — browsing farms means seeing OTHER
-- people's profiles, which the current RLS (own row or admin only) blocks
-- entirely. This adds a narrow, explicit carve-out: anyone signed in can
-- read a *prodavac*'s public info. Buyer (kupac) profiles remain private —
-- this policy only matches role = 'prodavac' rows.
-- =============================================================================

alter table public.profiles add column avatar_url text;
alter table public.profiles add column bio text;
alter table public.profiles add column city_id bigint references public.cities (id);

create policy "profiles_select_public_sellers"
  on public.profiles for select
  using (role = 'prodavac');

-- Sellers can update their own storefront fields too (already covered by
-- the existing profiles_update_own policy — just widen the column grant).
grant update (full_name, avatar_url, bio, city_id) on public.profiles to authenticated;

-- Aggregated, public view for the "Farme" directory: one row per seller
-- with their average rating and review count. Runs as the view owner
-- (bypasses RLS internally) but its own WHERE clause is the real filter —
-- only prodavac rows and only these specific, already-public columns are
-- ever exposed through it. Reviewer identities are deliberately not
-- included anywhere (kept anonymous).
create or replace view public.seller_public_profiles as
select
  p.id,
  p.full_name,
  p.avatar_url,
  p.bio,
  c.name as city_name,
  coalesce(round(avg(r.rating), 2), 0)::numeric as avg_rating,
  count(r.id) as review_count
from public.profiles p
left join public.cities c on c.id = p.city_id
left join public.seller_reviews r on r.seller_id = p.id
where p.role = 'prodavac'
group by p.id, p.full_name, p.avatar_url, p.bio, c.name;

grant select on public.seller_public_profiles to authenticated;
