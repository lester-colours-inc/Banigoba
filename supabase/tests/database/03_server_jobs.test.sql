begin;
select plan(5);

create function pg_temp.mkuser(n text) returns uuid language plpgsql as $$
declare u uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, aud, role, instance_id)
  values (u, n || '@test.dev', 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
  return u;
end $$;
create temp table ids (name text primary key, id uuid);
insert into ids values ('shop', pg_temp.mkuser('shop')), ('fan', pg_temp.mkuser('fan')),
  ('friend', pg_temp.mkuser('friend')), ('stranger', pg_temp.mkuser('stranger'));
create function pg_temp.u(n text) returns uuid language sql as $$ select id from ids where name = n $$;

-- fan and friend follow the shop; the shop follows only friend back.
insert into public.follows (follower_id, followee_id) values
  (pg_temp.u('fan'), pg_temp.u('shop')),
  (pg_temp.u('friend'), pg_temp.u('shop')),
  (pg_temp.u('shop'), pg_temp.u('friend'));

insert into public.shop_links (owner_id, shop_name, title, scope, audience)
  values (pg_temp.u('shop'), 'Tari Boutique', 'New in', 'all', 'link');
select is((select count(*) from public.notifications where type = 'shop_link')::int, 0,
  'a just-the-link share tells nobody');

insert into public.shop_links (owner_id, shop_name, title, scope, audience)
  values (pg_temp.u('shop'), 'Tari Boutique', 'Friends sale', 'all', 'friends');
select is((select count(*) from public.notifications where type = 'shop_link')::int, 1,
  'a friends share tells only mutual follows');
select is((select user_id from public.notifications where type = 'shop_link' limit 1), pg_temp.u('friend'),
  'and that is the friend');

insert into public.shop_links (owner_id, shop_name, title, scope, audience)
  values (pg_temp.u('shop'), 'Tari Boutique', 'Sale', 'all', 'followers');
select is((select count(*) from public.notifications where type = 'shop_link')::int, 3,
  'a followers share tells every follower');

insert into public.shop_links (owner_id, shop_name, title, scope, audience, active)
  values (pg_temp.u('shop'), 'Tari Boutique', 'Paused', 'all', 'public', false);
select is((select count(*) from public.notifications where type = 'shop_link')::int, 3,
  'a switched-off link tells nobody');

select * from finish();
rollback;
