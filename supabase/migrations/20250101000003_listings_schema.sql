-- =============================================================================
-- Plodovi sela — listings, cart & orders
--
-- Same security posture as the roles migration: RLS on every table, no
-- direct client-side writes for anything with a business rule attached
-- (placing an order, changing order status) — those go through SECURITY
-- DEFINER RPCs that re-check permissions server-side.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Reference data: cities & categories
-- ---------------------------------------------------------------------------
create table public.cities (
  id bigint generated always as identity primary key,
  name text not null unique
);

create table public.categories (
  id bigint generated always as identity primary key,
  name text not null unique,
  icon text not null default 'category',
  sort_order int not null default 0
);

insert into public.cities (name) values
  ('Sarajevo'), ('Banja Luka'), ('Tuzla'), ('Zenica'), ('Mostar'),
  ('Bijeljina'), ('Brčko'), ('Prijedor'), ('Trebinje'), ('Doboj'),
  ('Cazin'), ('Živinice'), ('Bihać'), ('Gradačac'), ('Visoko');

insert into public.categories (name, icon, sort_order) values
  ('Mlijeko i mliječni proizvodi', 'egg_outlined', 1),
  ('Pileće meso', 'set_meal_outlined', 2),
  ('Goveđe i teleće meso', 'set_meal_outlined', 3),
  ('Svinjsko meso', 'set_meal_outlined', 4),
  ('Jaja', 'egg_outlined', 5),
  ('Voće', 'eco_outlined', 6),
  ('Povrće', 'eco_outlined', 7),
  ('Med i pčelinji proizvodi', 'hive_outlined', 8),
  ('Žitarice i brašno', 'grass_outlined', 9),
  ('Domaća pekara', 'bakery_dining_outlined', 10),
  ('Zimnica i konzerve', 'kitchen_outlined', 11),
  ('Ostalo', 'more_horiz', 99);

-- ---------------------------------------------------------------------------
-- 2. Listings
-- ---------------------------------------------------------------------------
create table public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users (id) on delete cascade,
  category_id bigint not null references public.categories (id),
  city_id bigint not null references public.cities (id),
  title text not null check (char_length(title) between 3 and 120),
  description text,
  price numeric(10, 2) not null check (price >= 0),
  unit text not null default 'kom'
    check (unit in ('kom', 'kg', 'g', 'l', 'ml', 'gajba', 'vreća')),
  quantity_available numeric(10, 2)
    check (quantity_available is null or quantity_available >= 0),
  is_organic boolean not null default false,
  pickup_available boolean not null default true,
  delivery_available boolean not null default false,
  status text not null default 'active'
    check (status in ('active', 'sold_out', 'paused', 'deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint listings_at_least_one_fulfillment
    check (pickup_available or delivery_available)
);

create trigger set_listings_updated_at
  before update on public.listings
  for each row execute function public.set_updated_at();

create index listings_category_idx on public.listings (category_id);
create index listings_city_idx on public.listings (city_id);
create index listings_seller_idx on public.listings (seller_id);
create index listings_status_idx on public.listings (status);

create table public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  storage_path text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create index listing_images_listing_idx on public.listing_images (listing_id);

-- ---------------------------------------------------------------------------
-- 3. Favorites
-- ---------------------------------------------------------------------------
create table public.favorites (
  user_id uuid not null references auth.users (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

-- ---------------------------------------------------------------------------
-- 4. Seller reviews
-- ---------------------------------------------------------------------------
create table public.seller_reviews (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users (id) on delete cascade,
  reviewer_id uuid not null references auth.users (id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (seller_id, reviewer_id),
  constraint seller_reviews_no_self_review check (seller_id <> reviewer_id)
);

create index seller_reviews_seller_idx on public.seller_reviews (seller_id);

-- ---------------------------------------------------------------------------
-- 5. Cart
-- ---------------------------------------------------------------------------
create table public.cart_items (
  user_id uuid not null references auth.users (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  quantity numeric(10, 2) not null check (quantity > 0),
  added_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

-- ---------------------------------------------------------------------------
-- 6. Orders (one order per seller — a cart spanning multiple sellers becomes
--    multiple orders at checkout, so each seller only ever sees and manages
--    their own).
-- ---------------------------------------------------------------------------
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references auth.users (id) on delete cascade,
  seller_id uuid not null references auth.users (id) on delete cascade,
  fulfillment_type text not null check (fulfillment_type in ('pickup', 'delivery')),
  delivery_address text,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'ready', 'completed', 'cancelled')),
  total_amount numeric(10, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_delivery_needs_address
    check (fulfillment_type <> 'delivery' or delivery_address is not null)
);

create trigger set_orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

create index orders_buyer_idx on public.orders (buyer_id);
create index orders_seller_idx on public.orders (seller_id);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  listing_id uuid references public.listings (id) on delete set null,
  title_at_order text not null,
  unit_price numeric(10, 2) not null,
  quantity numeric(10, 2) not null,
  subtotal numeric(10, 2) not null
);

create index order_items_order_idx on public.order_items (order_id);

-- ---------------------------------------------------------------------------
-- 7. Business-rule RPCs
-- ---------------------------------------------------------------------------

-- Converts the caller's cart into one order per seller, atomically, then
-- empties the cart. Rejects an empty cart, a seller trying to buy their own
-- listing, or a fulfillment type a listing doesn't actually offer.
create or replace function public.checkout(
  p_fulfillment_type text,
  p_delivery_address text default null
)
returns setof uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_order_id uuid;
begin
  if p_fulfillment_type not in ('pickup', 'delivery') then
    raise exception 'Nepoznat način preuzimanja.';
  end if;
  if p_fulfillment_type = 'delivery' and coalesce(trim(p_delivery_address), '') = '' then
    raise exception 'Unesite adresu za dostavu.';
  end if;

  if not exists (select 1 from public.cart_items where user_id = auth.uid()) then
    raise exception 'Korpa je prazna.';
  end if;

  if exists (
    select 1 from public.cart_items c
    join public.listings l on l.id = c.listing_id
    where c.user_id = auth.uid() and l.seller_id = auth.uid()
  ) then
    raise exception 'Ne možete naručiti sopstveni oglas.';
  end if;

  if exists (
    select 1 from public.cart_items c
    join public.listings l on l.id = c.listing_id
    where c.user_id = auth.uid()
      and (
        (p_fulfillment_type = 'delivery' and not l.delivery_available) or
        (p_fulfillment_type = 'pickup' and not l.pickup_available)
      )
  ) then
    raise exception 'Neki od artikala u korpi ne podržavaju izabran način preuzimanja.';
  end if;

  for v_seller in
    select distinct l.seller_id
    from public.cart_items c
    join public.listings l on l.id = c.listing_id
    where c.user_id = auth.uid()
  loop
    insert into public.orders (buyer_id, seller_id, fulfillment_type, delivery_address)
    values (auth.uid(), v_seller, p_fulfillment_type, p_delivery_address)
    returning id into v_order_id;

    insert into public.order_items (order_id, listing_id, title_at_order, unit_price, quantity, subtotal)
    select
      v_order_id,
      l.id,
      l.title,
      l.price,
      c.quantity,
      l.price * c.quantity
    from public.cart_items c
    join public.listings l on l.id = c.listing_id
    where c.user_id = auth.uid() and l.seller_id = v_seller;

    update public.orders
      set total_amount = (
        select coalesce(sum(subtotal), 0) from public.order_items where order_id = v_order_id
      )
      where id = v_order_id;

    return next v_order_id;
  end loop;

  delete from public.cart_items where user_id = auth.uid();
end;
$$;

-- Status transitions, enforced server-side:
--   buyer:  pending -> cancelled
--   seller: pending -> confirmed -> ready -> completed, or -> cancelled
create or replace function public.update_order_status(
  p_order_id uuid,
  p_new_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order record;
  v_is_buyer boolean;
  v_is_seller boolean;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if v_order is null then
    raise exception 'Narudžba ne postoji.';
  end if;

  v_is_buyer := v_order.buyer_id = auth.uid();
  v_is_seller := v_order.seller_id = auth.uid();

  if not (v_is_buyer or v_is_seller or public.is_admin()) then
    raise exception 'Nemate pristup ovoj narudžbi.';
  end if;

  if p_new_status = 'cancelled' then
    if v_order.status <> 'pending' then
      raise exception 'Narudžba se više ne može otkazati.';
    end if;
    if not (v_is_buyer or v_is_seller or public.is_admin()) then
      raise exception 'Nemate pristup ovoj narudžbi.';
    end if;
  elsif p_new_status in ('confirmed', 'ready', 'completed') then
    if not (v_is_seller or public.is_admin()) then
      raise exception 'Samo prodavac može ažurirati status narudžbe.';
    end if;
    if (p_new_status = 'confirmed' and v_order.status <> 'pending') or
       (p_new_status = 'ready' and v_order.status <> 'confirmed') or
       (p_new_status = 'completed' and v_order.status <> 'ready') then
      raise exception 'Nedozvoljena promjena statusa.';
    end if;
  else
    raise exception 'Nepoznat status.';
  end if;

  update public.orders set status = p_new_status where id = p_order_id;
end;
$$;

grant execute on function public.checkout(text, text) to authenticated;
grant execute on function public.update_order_status(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. Row Level Security
-- ---------------------------------------------------------------------------
alter table public.cities enable row level security;
alter table public.categories enable row level security;
alter table public.listings enable row level security;
alter table public.listing_images enable row level security;
alter table public.favorites enable row level security;
alter table public.seller_reviews enable row level security;
alter table public.cart_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Reference data: readable by anyone signed in, never writable by clients.
create policy "cities_select_all" on public.cities for select using (true);
create policy "categories_select_all" on public.categories for select using (true);

-- Listings: everyone can browse active ones; a seller manages only their
-- own (and must actually hold the 'prodavac' role to create one).
create policy "listings_select_active_or_own"
  on public.listings for select
  using (status = 'active' or seller_id = auth.uid() or public.is_admin());

create policy "listings_insert_own_as_seller"
  on public.listings for insert
  with check (seller_id = auth.uid() and public.current_role() = 'prodavac');

create policy "listings_update_own"
  on public.listings for update
  using (seller_id = auth.uid() or public.is_admin())
  with check (seller_id = auth.uid() or public.is_admin());

create policy "listings_delete_own"
  on public.listings for delete
  using (seller_id = auth.uid() or public.is_admin());

create policy "listing_images_select_all"
  on public.listing_images for select
  using (true);

create policy "listing_images_manage_own_listing"
  on public.listing_images for all
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and (l.seller_id = auth.uid() or public.is_admin())
  ))
  with check (exists (
    select 1 from public.listings l
    where l.id = listing_id and (l.seller_id = auth.uid() or public.is_admin())
  ));

-- Favorites: fully private to the owner.
create policy "favorites_owner_all"
  on public.favorites for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Reviews: anyone can read; a user can only write/edit their own review,
-- and never review themselves (also enforced by the table constraint).
create policy "seller_reviews_select_all"
  on public.seller_reviews for select
  using (true);

create policy "seller_reviews_insert_own"
  on public.seller_reviews for insert
  with check (reviewer_id = auth.uid());

create policy "seller_reviews_update_own"
  on public.seller_reviews for update
  using (reviewer_id = auth.uid())
  with check (reviewer_id = auth.uid());

create policy "seller_reviews_delete_own"
  on public.seller_reviews for delete
  using (reviewer_id = auth.uid() or public.is_admin());

-- Cart: fully private to the owner.
create policy "cart_items_owner_all"
  on public.cart_items for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Orders / order_items: buyer and seller can each see their side; nobody
-- gets a direct INSERT/UPDATE policy — checkout() and update_order_status()
-- are the only ways rows are created or change status.
create policy "orders_select_participant"
  on public.orders for select
  using (buyer_id = auth.uid() or seller_id = auth.uid() or public.is_admin());

create policy "order_items_select_participant"
  on public.order_items for select
  using (exists (
    select 1 from public.orders o
    where o.id = order_id
      and (o.buyer_id = auth.uid() or o.seller_id = auth.uid() or public.is_admin())
  ));

-- ---------------------------------------------------------------------------
-- 9. Grants
-- ---------------------------------------------------------------------------
grant select on public.cities to authenticated;
grant select on public.categories to authenticated;

grant select, insert, update, delete on public.listings to authenticated;
grant select, insert, update, delete on public.listing_images to authenticated;

grant select, insert, delete on public.favorites to authenticated;

grant select, insert, update, delete on public.seller_reviews to authenticated;

grant select, insert, update, delete on public.cart_items to authenticated;

grant select on public.orders to authenticated;
grant select on public.order_items to authenticated;
