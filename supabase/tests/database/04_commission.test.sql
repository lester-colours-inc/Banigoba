begin;
select plan(11);

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
grant execute on all functions in schema pg_temp to public;
create temp table ids (name text primary key, id uuid);
grant all on ids to public;
insert into ids values ('shop', pg_temp.mkuser('shop')), ('buyer', pg_temp.mkuser('buyer')),
  ('fan', pg_temp.mkuser('fan')), ('curator', pg_temp.mkuser('curator'));
create function pg_temp.u(n text) returns uuid language sql as $$ select id from ids where name = n $$;
grant execute on function pg_temp.u(text) to public;

update public.profiles set shop = '{"name":"Tari"}'::jsonb where id = pg_temp.u('shop');
update public.profiles set is_admin = true where id = pg_temp.u('curator');
insert into public.products (id, user_id, name, price, stock) values
  ('00000000-0000-0000-0000-00000000d001', pg_temp.u('shop'), 'Scarf', 10, 10);

-- A plain sale: $10 piece, buyer pays $12, shop owes $2, nobody else is paid.
select pg_temp.as_user(pg_temp.u('buyer'));
insert into public.cart_items (user_id, product_id, quantity) values (pg_temp.u('buyer'), '00000000-0000-0000-0000-00000000d001', 1);
select public.place_order('collect', '');
select is((select total from public.orders), 12.00, 'the buyer pays the price plus 20%');
select is((select commission from public.orders), 2.00, 'the commission is 20% of the seller''s price');
select is((select items_total from public.orders), 10.00, 'the seller''s own price is untouched');
reset role;
select is((select count(*) from public.ledger_entries)::int, 1, 'a sale with no referral has one ledger entry');
select pg_temp.as_user(pg_temp.u('buyer'));

-- A referred sale: the fan's post brought it, so the fan gets 25% of $2 = $0.50.
insert into public.cart_items (user_id, product_id, quantity, data)
  values (pg_temp.u('buyer'), '00000000-0000-0000-0000-00000000d001', 1, jsonb_build_object('referrerId', pg_temp.u('fan')::text));
select public.place_order('collect', '');
select is((select influencer_share from public.orders where referrer_id is not null), 0.50, 'the influencer gets 25% of the commission');

-- Nobody can refer themselves into a share.
insert into public.cart_items (user_id, product_id, quantity, data)
  values (pg_temp.u('buyer'), '00000000-0000-0000-0000-00000000d001', 1, jsonb_build_object('referrerId', pg_temp.u('buyer')::text));
select public.place_order('collect', '');
select is((select count(*) from public.orders where referrer_id is not null)::int, 1, 'a buyer cannot refer themselves');

-- Who sees the ledger.
select pg_temp.as_user(pg_temp.u('fan'));
select is((select count(*) from public.ledger_entries)::int, 1, 'the influencer sees only their own share');
select pg_temp.as_user(pg_temp.u('shop'));
select is((select count(*) from public.ledger_entries)::int, 3, 'the shop sees the commission it owes on each sale');
select throws_ok($$update public.orders set commission = 0$$, null, null, 'amounts cannot be edited');

-- Completing an order makes its entries due; cancelling voids them.
update public.orders set status = 'collected' where total = 12.00 and referrer_id is null and id = (select id from public.orders order by created_at limit 1);
select is((select count(*) from public.ledger_entries where status = 'due')::int, 1, 'a collected order''s entry falls due');
select pg_temp.as_user(pg_temp.u('buyer'));
update public.ledger_entries set status = 'settled';
reset role;
select is((select count(*) from public.ledger_entries where status = 'settled')::int, 0, 'only a curator can settle');

select * from finish();
rollback;
