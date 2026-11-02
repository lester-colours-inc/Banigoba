-- Banigoba on Supabase, part 4: storage buckets. Every bucket is public to
-- read (the paths are unguessable and the app shows these pictures to people
-- who are not signed in on shared stock links); writes are limited to the
-- first path segment being the signed-in user's id, as the Firebase rules did.

insert into storage.buckets (id, name, public) values
  ('product-images', 'product-images', true),
  ('events', 'events', true),
  ('user-images', 'user-images', true),
  ('ai-makeovers', 'ai-makeovers', true),
  ('hairstyles', 'hairstyles', true)
on conflict (id) do nothing;

do $$
declare b text;
begin
  foreach b in array array['product-images', 'events', 'user-images', 'ai-makeovers'] loop
    execute format($f$create policy %I on storage.objects for insert to authenticated
      with check (bucket_id = %L and (storage.foldername(name))[1] = auth.uid()::text)$f$,
      b || '_insert', b);
    execute format($f$create policy %I on storage.objects for update to authenticated
      using (bucket_id = %L and (storage.foldername(name))[1] = auth.uid()::text)$f$,
      b || '_update', b);
    execute format($f$create policy %I on storage.objects for delete to authenticated
      using (bucket_id = %L and (storage.foldername(name))[1] = auth.uid()::text)$f$,
      b || '_delete', b);
  end loop;
end $$;

-- The hairstyle catalogue is admin-written.
create policy hairstyles_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'hairstyles' and public.is_admin());
create policy hairstyles_update on storage.objects for update to authenticated
  using (bucket_id = 'hairstyles' and public.is_admin());
create policy hairstyles_delete on storage.objects for delete to authenticated
  using (bucket_id = 'hairstyles' and public.is_admin());
