begin;
select plan(22);

create function pg_temp.mkuser(n text) returns uuid language plpgsql as $$
declare u uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, aud, role, instance_id)
  values (u, n || '@test.dev', 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
  return u;
end $$;
create function pg_temp.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  set local role authenticated;
end $$;
create function pg_temp.as_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  set local role anon;
end $$;
grant execute on all functions in schema pg_temp to public;

create temp table ids (name text primary key, id uuid);
grant all on ids to public;
insert into ids values ('shop', pg_temp.mkuser('shop')), ('buyer', pg_temp.mkuser('buyer')),
  ('other', pg_temp.mkuser('other')), ('curator', pg_temp.mkuser('curator'));
create function pg_temp.u(n text) returns uuid language sql as $$ select id from ids where name = n $$;
grant execute on function pg_temp.u(text) to public;

-- Set up (as the database owner): a shop that delivers, a curator, and stock.
update public.profiles set display_name = 'Shop', shop = '{"name":"Tari Boutique","delivery":{"fee":5,"areas":["Avondale"]}}'::jsonb
  where id = pg_temp.u('shop');
update public.profiles set is_admin = true where id = pg_temp.u('curator');
update public.private_account set address = '{"street":"1 Main St"}'::jsonb where id = pg_temp.u('buyer');
insert into public.products (id, user_id, name, price, stock, size_inventory) values
  ('00000000-0000-0000-0000-00000000b001', pg_temp.u('shop'), 'Dress', 40, 5, '{"M":2,"L":3}'),
  ('00000000-0000-0000-0000-00000000b002', pg_temp.u('shop'), 'Scarf', 10, 1, '{}');

-- Products are open to read, even signed out.
select pg_temp.as_anon();
select is((select count(*) from public.products)::int, 2, 'anyone can see a shop''s pieces');
update public.products set stock = 99;
reset role;
select is((select count(*) from public.products where stock = 99)::int, 0, 'signed-out people cannot change stock');

-- A buyer cannot edit someone else's product.
select pg_temp.as_user(pg_temp.u('buyer'));
update public.products set price = 1 where id = '00000000-0000-0000-0000-00000000b001';
reset role;
select is((select price from public.products where id = '00000000-0000-0000-0000-00000000b001'), 40.00, 'a buyer cannot change a shop''s price');

-- Checkout.
select pg_temp.as_user(pg_temp.u('buyer'));
insert into public.cart_items (user_id, product_id, quantity, selected_size)
  values (pg_temp.u('buyer'), '00000000-0000-0000-0000-00000000b001', 2, 'M');
select lives_ok($$select public.place_order('delivery', 'Avondale')$$, 'a buyer can place a delivery order');
select is((select count(*) from public.cart_items)::int, 0, 'the bag is emptied');
select is((select total from public.orders), 101.00, 'total is items plus the service fee plus the shop''s own delivery fee');
select is((select delivery_fee from public.orders), 5.00, 'the fee comes from the shop settings');

reset role;
select is((select stock from public.products where id = '00000000-0000-0000-0000-00000000b001'), 3, 'stock went down by what was bought');
select is((select (size_inventory->>'M')::int from public.products where id = '00000000-0000-0000-0000-00000000b001'), 0, 'the chosen size bucket went down');

-- Over-selling is refused.
select pg_temp.as_user(pg_temp.u('buyer'));
insert into public.cart_items (user_id, product_id, quantity, selected_size)
  values (pg_temp.u('buyer'), '00000000-0000-0000-0000-00000000b001', 1, 'M');
select throws_ok($$select public.place_order('collect', '')$$, null, null, 'cannot buy a size with none left');
delete from public.cart_items;

-- A delivery area the shop does not serve is refused.
insert into public.cart_items (user_id, product_id, quantity, selected_size)
  values (pg_temp.u('buyer'), '00000000-0000-0000-0000-00000000b002', 1, '');
select throws_ok($$select public.place_order('delivery', 'Mars')$$, null, null, 'delivery outside the shop''s areas is refused');
delete from public.cart_items;

-- Who sees the order.
select is((select count(*) from public.orders)::int, 1, 'the buyer sees their order');
select pg_temp.as_user(pg_temp.u('shop'));
select is((select count(*) from public.orders)::int, 1, 'the seller sees it too');
select throws_ok($$update public.orders set total = 1$$, null, null, 'amounts on an order cannot change');
select lives_ok($$update public.orders set status = 'confirmed', status_label = 'Confirmed'$$, 'the seller can move the status');
select pg_temp.as_user(pg_temp.u('other'));
select is((select count(*) from public.orders)::int, 0, 'a stranger sees no orders');

-- Chats: the order opened one; messages go through functions.
select pg_temp.as_user(pg_temp.u('buyer'));
select is((select count(*) from public.shop_chats)::int, 1, 'the order opened a chat');
select throws_ok($$insert into public.shop_chat_messages (chat_id, sender_id, text, is_system) select id, null, 'fake', true from public.shop_chats$$, null, null, 'a buyer cannot write a system message directly');
select lives_ok($$select public.send_chat_message((select id from public.shop_chats limit 1), 'Is it still there?')$$, 'a participant can send a message');
select pg_temp.as_user(pg_temp.u('other'));
select is((select count(*) from public.shop_chat_messages)::int, 0, 'a stranger cannot read a chat');

-- Shared stock links.
select pg_temp.as_user(pg_temp.u('shop'));
insert into public.shop_links (id, owner_id, title, scope, audience)
  values ('00000000-0000-0000-0000-00000000c001', pg_temp.u('shop'), 'New in', 'all', 'link'),
         ('00000000-0000-0000-0000-00000000c002', pg_temp.u('shop'), 'Public', 'all', 'public');
select pg_temp.as_anon();
select is((select count(*) from public.shop_links)::int, 1, 'signed-out people can only list public links');
select is((public.get_shop_link('00000000-0000-0000-0000-00000000c001')).title, 'New in', 'but anyone holding the link can open it');

select * from finish();
rollback;
