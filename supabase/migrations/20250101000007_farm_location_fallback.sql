-- Farm location: prefer the seller's own profile city (once a "edit
-- storefront" screen exists to set it), otherwise fall back to the city of
-- their most recent active listing — so a location shows up in the "Farme"
-- directory right away, without requiring a separate profile-edit step.
create or replace view public.seller_public_profiles as
select
  p.id,
  p.full_name,
  p.avatar_url,
  p.bio,
  coalesce(pc.name, lc.name) as city_name,
  coalesce(round(avg(r.rating), 2), 0)::numeric as avg_rating,
  count(distinct r.id) as review_count
from public.profiles p
left join public.cities pc on pc.id = p.city_id
left join lateral (
  select c.name
  from public.listings l
  join public.cities c on c.id = l.city_id
  where l.seller_id = p.id and l.status = 'active'
  order by l.created_at desc
  limit 1
) lc on true
left join public.seller_reviews r on r.seller_id = p.id
where p.role = 'prodavac'
group by p.id, p.full_name, p.avatar_url, p.bio, pc.name, lc.name;
