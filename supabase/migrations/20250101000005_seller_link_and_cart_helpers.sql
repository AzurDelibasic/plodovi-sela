-- =============================================================================
-- 1. A second FK on listings.seller_id, pointing at public.profiles instead
--    of auth.users, purely so PostgREST can embed the seller's profile
--    (full_name) in a listings query. Harmless: both tables' primary key is
--    the same auth.users.id, so any value valid for one is valid for the
--    other — this doesn't change what data is accepted, just what can be
--    joined via the REST API.
-- =============================================================================
alter table public.listings
  add constraint listings_seller_profile_fkey
  foreign key (seller_id) references public.profiles (id);

-- ---------------------------------------------------------------------------
-- 2. Cart: atomic "add or increment" so two rapid taps of "+" can't race
--    each other into overwriting instead of summing the quantity.
-- ---------------------------------------------------------------------------
create or replace function public.add_to_cart(
  p_listing_id uuid,
  p_quantity numeric default 1
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_quantity <= 0 then
    raise exception 'Količina mora biti veća od nule.';
  end if;

  if not exists (select 1 from public.listings where id = p_listing_id and status = 'active') then
    raise exception 'Oglas više nije dostupan.';
  end if;

  insert into public.cart_items (user_id, listing_id, quantity)
  values (auth.uid(), p_listing_id, p_quantity)
  on conflict (user_id, listing_id)
    do update set quantity = public.cart_items.quantity + excluded.quantity;
end;
$$;

grant execute on function public.add_to_cart(uuid, numeric) to authenticated;
