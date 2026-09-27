-- =============================================================================
-- Separate the farm's public display name from the user's own registered
-- name. Until now editing a seller's "farm name" silently overwrote
-- `profiles.full_name` — the same field used for the account's own name
-- (shown as "Zdravo, <ime>" etc.) — which was never the intent.
--
-- `farm_name` is optional: when unset (or blank), the storefront falls back
-- to `full_name`, so nothing changes for sellers who never rename it.
-- =============================================================================

alter table public.profiles add column farm_name text;

grant update (farm_name) on public.profiles to authenticated;

create or replace view public.seller_public_profiles as
select
  p.id,
  coalesce(nullif(trim(p.farm_name), ''), p.full_name) as full_name,
  p.avatar_url,
  p.bio,
  c.name as city_name,
  coalesce(round(avg(r.rating), 2), 0)::numeric as avg_rating,
  count(r.id) as review_count
from public.profiles p
left join public.cities c on c.id = p.city_id
left join public.seller_reviews r on r.seller_id = p.id
where p.role = 'prodavac'
group by p.id, p.farm_name, p.full_name, p.avatar_url, p.bio, c.name;
