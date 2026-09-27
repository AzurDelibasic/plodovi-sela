-- =============================================================================
-- Orders: let embedding work (orders.seller_id / buyer_id -> profiles), and
-- let the two people on an order see each other's name — a buyer and
-- seller with a real order between them is exactly the case where profile
-- visibility should extend beyond "own row only" or "public seller only".
-- =============================================================================

alter table public.orders
  add constraint orders_seller_profile_fkey
  foreign key (seller_id) references public.profiles (id);

alter table public.orders
  add constraint orders_buyer_profile_fkey
  foreign key (buyer_id) references public.profiles (id);

create policy "profiles_select_order_participant"
  on public.profiles for select
  using (
    exists (
      select 1 from public.orders o
      where (o.buyer_id = auth.uid() and o.seller_id = profiles.id)
         or (o.seller_id = auth.uid() and o.buyer_id = profiles.id)
    )
  );
