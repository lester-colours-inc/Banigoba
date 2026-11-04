-- Platform commission (K-5), influencer share (K-6) and the money ledger (K-7).
--
-- Decided 22 Oct: the commission is 20% added on top of the seller's price (a
-- $1.00 piece costs the buyer $1.20 and the seller keeps the full $1.00); the
-- influencer whose post or link brought the sale gets 25% of the commission.
-- Buyers pay the shop directly (collection or delivery), so the shop owes the
-- platform the commission, and the platform owes the influencer their share.
-- The rates live in one settings row so curators can change them.

create table public.platform_settings (
  id boolean primary key default true check (id),
  commission_rate numeric(5, 4) not null default 0.20 check (commission_rate between 0 and 1),
  influencer_share numeric(5, 4) not null default 0.25 check (influencer_share between 0 and 1),
  updated_at timestamptz not null default now()
);
insert into public.platform_settings (id) values (true);
alter table public.platform_settings enable row level security;
create policy platform_settings_read on public.platform_settings for select using (true);
create policy platform_settings_admin on public.platform_settings
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

alter table public.orders
  add column commission numeric(12, 2) not null default 0,
  add column referrer_id uuid references public.profiles (id) on delete set null,
  add column influencer_share numeric(12, 2) not null default 0;

create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  party_id uuid not null references public.profiles (id) on delete restrict,
  kind text not null check (kind in ('seller_commission_owed', 'influencer_share')),
  amount numeric(12, 2) not null check (amount >= 0),
  -- pending: order not finished; due: order completed; settled: paid; void: cancelled
  status text not null default 'pending' check (status in ('pending', 'due', 'settled', 'void')),
  created_at timestamptz not null default now(),
  settled_at timestamptz
);
create index ledger_party on public.ledger_entries (party_id, created_at desc);
create index ledger_order on public.ledger_entries (order_id);
alter table public.ledger_entries enable row level security;
-- You see your own entries; curators see everything and mark them settled.
create policy ledger_read on public.ledger_entries
  for select to authenticated using (party_id = auth.uid() or public.is_admin());
create policy ledger_admin_update on public.ledger_entries
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
alter table public.ledger_entries replica identity full;

-- When an order finishes its entries fall due; when it is cancelled they void.
create or replace function private.sync_ledger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is not distinct from old.status then return new; end if;
  if new.status in ('collected', 'delivered') then
    update public.ledger_entries set status = 'due' where order_id = new.id and status = 'pending';
  elsif new.status = 'cancelled' then
    update public.ledger_entries set status = 'void' where order_id = new.id and status in ('pending', 'due');
  end if;
  return new;
end $$;
create trigger orders_ledger after update of status on public.orders
  for each row execute function private.sync_ledger();

-- Orders' amounts are fixed once placed.
create or replace function public.guard_order_update()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_server() then return new; end if;
  if new.seller_id <> old.seller_id or new.customer_id <> old.customer_id
     or new.items is distinct from old.items or new.total <> old.total
     or new.items_total <> old.items_total or new.delivery_fee <> old.delivery_fee
     or new.commission <> old.commission or new.influencer_share <> old.influencer_share
     or new.referrer_id is distinct from old.referrer_id
     or new.order_number <> old.order_number then
    raise exception 'An order''s parties and amounts cannot be changed.';
  end if;
  new.updated_at := now();
  return new;
end $$;

-- What a person is owed or owes, for the earnings screen.
create or replace function public.my_ledger_summary()
returns table (kind text, status text, entries bigint, amount numeric)
language sql stable security invoker set search_path = public as $$
  select kind, status, count(*), coalesce(sum(amount), 0)
  from public.ledger_entries where party_id = auth.uid()
  group by kind, status
$$;
grant execute on function public.my_ledger_summary() to authenticated;

create or replace function public.place_order(
  p_fulfilment text default 'collect', p_delivery_area text default ''
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  seller uuid; shop jsonb; shop_nm text;
  me public.profiles; priv public.private_account;
  line record; prod public.products;
  items jsonb := '[]'::jsonb; items_sum numeric := 0; qty_sum integer := 0;
  size_stock integer; fee numeric := 0; deliver boolean := p_fulfilment = 'delivery';
  d jsonb; chat uuid; oid uuid := gen_random_uuid(); num text; msg text;
  line_price numeric; sizes jsonb; new_total integer;
  rate numeric; share numeric; commission numeric; influencer uuid; inf_share numeric := 0;
  referrer text;
begin
  if uid is null then raise exception 'Sign in first.'; end if;
  if p_fulfilment not in ('collect', 'delivery') then raise exception 'Unknown fulfilment.'; end if;

  select p.user_id into seller
  from public.cart_items c join public.products p on p.id = c.product_id
  where c.user_id = uid order by c.created_at limit 1;
  if seller is null then raise exception 'Your bag is empty.'; end if;

  select * into me from public.profiles where id = uid;
  select * into priv from public.private_account where id = uid;
  select coalesce(pr.shop, '{}'::jsonb) into shop from public.profiles pr where pr.id = seller;
  shop_nm := coalesce(nullif(shop->>'name', ''), '');

  if deliver then
    if coalesce(priv.address->>'street', '') = '' then
      raise exception 'Add your delivery address first.';
    end if;
  end if;

  for line in
    select c.id cart_id, c.quantity, c.selected_size, c.product_id, c.data->>'referrerId' as referrer
    from public.cart_items c where c.user_id = uid order by c.created_at
  loop
    select * into prod from public.products where id = line.product_id for update;
    if not found then continue; end if;
    if prod.user_id <> seller then
      raise exception 'Your bag has pieces from more than one shop.';
    end if;
    line_price := prod.price;
    sizes := prod.size_inventory;
    if line.selected_size <> '' and sizes <> '{}'::jsonb then
      size_stock := coalesce((sizes->>line.selected_size)::integer, 0);
      if size_stock < line.quantity then
        raise exception '% only has % left in size %.', prod.name, size_stock, line.selected_size;
      end if;
      sizes := jsonb_set(sizes, array[line.selected_size], to_jsonb(size_stock - line.quantity));
      select coalesce(sum(value::integer), 0) into new_total from jsonb_each_text(sizes);
      update public.products set size_inventory = sizes, stock = new_total where id = prod.id;
    else
      if prod.stock < line.quantity then
        raise exception '% only has % in stock.', prod.name, prod.stock;
      end if;
      update public.products set stock = stock - line.quantity where id = prod.id;
    end if;
    items := items || jsonb_build_array(jsonb_strip_nulls(jsonb_build_object(
      'productId', prod.id, 'name', prod.name, 'quantity', line.quantity,
      'selectedSize', nullif(line.selected_size, ''), 'price', line_price,
      'lineTotal', line_price * line.quantity,
      'imageUrl', coalesce(nullif(prod.raw_image_url, ''), prod.image_url))));
    items_sum := items_sum + line_price * line.quantity;
    qty_sum := qty_sum + line.quantity;
    if influencer is null and line.referrer is not null and line.referrer ~* '^[0-9a-f-]{36}$' then
      referrer := line.referrer;
    end if;
    delete from public.cart_items where id = line.cart_id;
  end loop;

  if deliver then
    d := coalesce(shop->'delivery', '{}'::jsonb);
    if d = '{}'::jsonb then
      raise exception 'This shop does not deliver.';
    end if;
    fee := coalesce((d->>'fee')::numeric, 0);
    if jsonb_array_length(coalesce(d->'areas', '[]'::jsonb)) > 0
       and not (d->'areas') @> to_jsonb(trim(p_delivery_area)) then
      raise exception 'This shop does not deliver to that area.';
    end if;
  end if;

  select commission_rate, influencer_share into rate, share from public.platform_settings where id = true;
  commission := round(items_sum * coalesce(rate, 0.20), 2);
  -- A referral counts when the referrer is a real person other than the buyer and the shop.
  if referrer is not null then
    select p.id into influencer from public.profiles p
    where p.id = referrer::uuid and p.id <> uid and p.id <> seller;
    if influencer is not null then
      inf_share := round(commission * coalesce(share, 0.25), 2);
    end if;
  end if;

  insert into public.shop_chats
    (kind, seller_id, customer_id, shop_name, customer_name, customer_image_url)
  values ('shop', seller, uid, shop_nm, coalesce(me.display_name, ''), coalesce(me.profile_image_url, ''))
  on conflict (kind, seller_id, customer_id) do update set updated_at = now()
  returning id into chat;
  num := upper(substr(oid::text, 1, 6));

  insert into public.orders (
    id, order_number, seller_id, customer_id, shop_name, customer_name, customer_email,
    customer_address, items, item_count, items_total, commission, referrer_id, influencer_share,
    delivery_fee, total, fulfilment,
    delivery_area, payment_method, payment_label, status, status_label, status_history, chat_id
  ) values (
    oid, num, seller, uid, shop_nm,
    coalesce(nullif(me.display_name, ''), 'Customer'), coalesce(priv.email, ''),
    coalesce(priv.address, '{}'::jsonb), items, qty_sum, items_sum, commission, influencer, inf_share,
    fee, items_sum + commission + fee,
    p_fulfilment, case when deliver then trim(p_delivery_area) end,
    case when deliver then 'pay_upon_delivery' else 'pay_upon_collection' end,
    case when deliver then 'Pay on delivery' else 'Pay upon collection' end,
    'submitted', 'Submitted',
    jsonb_build_array(jsonb_build_object('status', 'submitted', 'label', 'Submitted',
      'updatedBy', uid, 'updatedAt', now())),
    chat
  );

  msg := case when deliver then
      format('Order #%s confirmed for %s. Delivery%s (fee $%s). Payment method: pay on delivery. Total: $%s.',
        num, shop_nm, case when trim(p_delivery_area) = '' then '' else ' to ' || trim(p_delivery_area) end,
        to_char(fee, 'FM999999990.00'), to_char(items_sum + commission + fee, 'FM999999990.00'))
    else
      format('Order #%s confirmed for %s. Payment method: pay upon collection. Total: $%s.',
        num, shop_nm, to_char(items_sum + commission, 'FM999999990.00'))
    end;
  insert into public.shop_chat_messages (chat_id, sender_id, text, sender_type, is_system, order_id)
  values (chat, null, msg, 'system', true, oid);
  update public.shop_chats set last_message = msg, last_message_at = now(),
    unread_by_seller = unread_by_seller + 1, unread_by_customer = unread_by_customer + 1,
    updated_at = now() where id = chat;

  -- The ledger: the seller keeps their full price and owes the platform the
  -- commission (buyers pay the shop directly); the influencer, if any, is owed
  -- a share of that commission by the platform.
  insert into public.ledger_entries (order_id, party_id, kind, amount)
  values (oid, seller, 'seller_commission_owed', commission);
  if influencer is not null then
    insert into public.ledger_entries (order_id, party_id, kind, amount)
    values (oid, influencer, 'influencer_share', inf_share);
  end if;

  insert into public.notifications (user_id, sender_id, type, title, body, extra_data)
  values (seller, uid, 'order_update', 'New order', 'placed order #' || num || '.',
    jsonb_build_object('orderId', oid, 'chatId', chat, 'fromName', me.display_name,
      'shopName', shop_nm, 'sellerId', seller, 'customerId', uid));
  return oid;
end $$;
revoke all on function public.place_order(text, text) from public, anon;
grant execute on function public.place_order(text, text) to authenticated;
