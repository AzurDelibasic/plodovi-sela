-- =============================================================================
-- A farm's own photo gallery — separate from `profiles.avatar_url` (the
-- user's personal profile picture) and from `listing_images` (per-product
-- photos). Shown as the banner on the Farme directory cards and on the
-- farm detail screen.
-- =============================================================================

create table public.farm_images (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users (id) on delete cascade,
  storage_path text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create index farm_images_seller_idx on public.farm_images (seller_id);

alter table public.farm_images enable row level security;

create policy "farm_images_select_all"
  on public.farm_images for select
  using (true);

create policy "farm_images_manage_own"
  on public.farm_images for all
  using (seller_id = auth.uid() or public.is_admin())
  with check (seller_id = auth.uid() or public.is_admin());

grant select, insert, update, delete on public.farm_images to authenticated;

-- Storage: public-read bucket, writes scoped to the owner's own folder —
-- same pattern as `avatars` / `listing-images`.
insert into storage.buckets (id, name, public)
values ('farm-images', 'farm-images', true)
on conflict (id) do nothing;

create policy "farm_images_bucket_public_read"
  on storage.objects for select
  using (bucket_id = 'farm-images');

create policy "farm_images_bucket_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'farm-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "farm_images_bucket_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'farm-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'farm-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "farm_images_bucket_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'farm-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
