-- Public buckets serve files by public URL without any policy, but listing a
-- folder and downloading through the storage API go through RLS, and no
-- select policy existed. So the app could never list a person's own files:
-- getLatestFullBodyImageUrl always came back empty, Avatar Try-On kept asking
-- for an avatar, and the saved photo never loaded on the upload page.
--
-- Read is limited to the signed-in user's own folder, so nobody can list
-- other people's photos (the paths stay unguessable).
do $$
declare b text;
begin
  foreach b in array array['product-images', 'events', 'user-images', 'ai-makeovers'] loop
    execute format('drop policy if exists %I on storage.objects', b || '_select_own');
    execute format($f$create policy %I on storage.objects for select to authenticated
      using (bucket_id = %L and (storage.foldername(name))[1] = auth.uid()::text)$f$,
      b || '_select_own', b);
  end loop;
end $$;
