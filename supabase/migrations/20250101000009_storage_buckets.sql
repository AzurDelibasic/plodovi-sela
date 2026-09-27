-- =============================================================================
-- Storage buckets for listing photos and seller (farm) avatars.
--
-- Both buckets are public-read (product/profile photos are meant to be seen
-- by anyone browsing, logged in or not) but writes are restricted by path:
-- every object must live under a folder named after its owner's auth uid, so
-- "insert/update/delete only in your own folder" is enough to stop anyone
-- from touching someone else's files — no extra join needed in the policy.
-- =============================================================================

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

create policy "avatars_public_read"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "listing_images_public_read"
  on storage.objects for select
  using (bucket_id = 'listing-images');

create policy "listing_images_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "listing_images_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "listing_images_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
