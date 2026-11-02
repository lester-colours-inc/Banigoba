-- Sign-up also registers the account for "find someone by their full email":
-- a SHA-256 of the lower-cased address, never the address itself.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''))
  on conflict (id) do nothing;
  insert into public.private_account (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do nothing;
  if coalesce(new.email, '') <> '' then
    insert into public.email_lookup (hash, user_id)
    values (encode(sha256(convert_to(lower(trim(new.email)), 'utf8')), 'hex'), new.id)
    on conflict (hash) do nothing;
  end if;
  return new;
end $$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
