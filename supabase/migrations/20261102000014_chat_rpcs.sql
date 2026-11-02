-- Chats: unread counters, message kinds, and server-side writes. Messages and
-- counters change only through these functions, so a sender cannot spoof a
-- system message or someone else's read state.

alter table public.shop_chats
  drop column unread_for_seller,
  drop column unread_for_customer,
  add column unread_by_seller integer not null default 0,
  add column unread_by_customer integer not null default 0,
  add column last_message_at timestamptz,
  add column designer_name text not null default '';
alter table public.shop_chat_messages add column sender_type text not null default 'text';
alter table public.shop_chats replica identity full;
alter table public.shop_chat_messages replica identity full;

drop policy shop_chat_messages_create on public.shop_chat_messages;
drop policy shop_chats_create on public.shop_chats;
drop policy shop_chats_update on public.shop_chats;

-- Open (or find) the conversation with a shop, designer or salon.
create or replace function public.ensure_chat(
  p_kind text, p_provider uuid, p_provider_name text default '', p_context jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path = public as $$
declare cid uuid; me public.profiles;
begin
  if auth.uid() is null then raise exception 'Sign in first.'; end if;
  if p_kind not in ('shop', 'designer', 'salon') then raise exception 'Unknown chat kind.'; end if;
  select * into me from public.profiles where id = auth.uid();
  insert into public.shop_chats
    (kind, seller_id, customer_id, designer_id, shop_name, designer_name,
     customer_name, customer_image_url, data)
  values (p_kind, p_provider, auth.uid(),
          case when p_kind = 'designer' then p_provider end,
          p_provider_name, case when p_kind = 'designer' then p_provider_name else '' end,
          coalesce(me.display_name, ''), coalesce(me.profile_image_url, ''), p_context)
  on conflict (kind, seller_id, customer_id) do update set
    updated_at = now(),
    shop_name = case when excluded.shop_name <> '' then excluded.shop_name else public.shop_chats.shop_name end,
    customer_name = excluded.customer_name,
    customer_image_url = excluded.customer_image_url,
    data = public.shop_chats.data || excluded.data
  returning id into cid;
  return cid;
end $$;

-- Send a message as the caller; the other side's unread count goes up.
create or replace function public.send_chat_message(
  p_chat uuid, p_text text, p_sender_type text default 'text',
  p_data jsonb default '{}'::jsonb, p_chat_context jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path = public as $$
declare c public.shop_chats; mid uuid;
begin
  select * into c from public.shop_chats where id = p_chat;
  if not found or not public.is_chat_participant(c) then
    raise exception 'You do not have access to this conversation.';
  end if;
  if p_sender_type not in ('text', 'look_reference', 'product_reference', 'design_request_reference') then
    raise exception 'Unknown message kind.';
  end if;
  insert into public.shop_chat_messages (chat_id, sender_id, text, sender_type, data)
  values (p_chat, auth.uid(), trim(p_text), p_sender_type, p_data)
  returning id into mid;
  update public.shop_chats set
    last_message = trim(p_text),
    last_message_at = now(),
    updated_at = now(),
    data = data || p_chat_context,
    unread_by_customer = unread_by_customer + (case when auth.uid() = seller_id then 1 else 0 end),
    unread_by_seller = unread_by_seller + (case when auth.uid() = seller_id then 0 else 1 end)
  where id = p_chat;
  return mid;
end $$;

-- A message from the system (order confirmations and status changes).
create or replace function public.post_system_message(
  p_chat uuid, p_text text, p_order uuid default null,
  p_unread_seller boolean default false, p_unread_customer boolean default false
) returns void language plpgsql security definer set search_path = public as $$
declare c public.shop_chats;
begin
  select * into c from public.shop_chats where id = p_chat;
  if not found or not public.is_chat_participant(c) then
    raise exception 'You do not have access to this conversation.';
  end if;
  insert into public.shop_chat_messages (chat_id, sender_id, text, sender_type, is_system, order_id)
  values (p_chat, null, trim(p_text), 'system', true, p_order);
  update public.shop_chats set
    last_message = trim(p_text), last_message_at = now(), updated_at = now(),
    unread_by_seller = unread_by_seller + (case when p_unread_seller then 1 else 0 end),
    unread_by_customer = unread_by_customer + (case when p_unread_customer then 1 else 0 end)
  where id = p_chat;
end $$;

create or replace function public.mark_chat_read(p_chat uuid, p_as_seller boolean)
returns void language plpgsql security definer set search_path = public as $$
declare c public.shop_chats;
begin
  select * into c from public.shop_chats where id = p_chat;
  if not found or not public.is_chat_participant(c) then return; end if;
  update public.shop_chats set
    unread_by_seller = case when p_as_seller then 0 else unread_by_seller end,
    unread_by_customer = case when p_as_seller then unread_by_customer else 0 end
  where id = p_chat;
end $$;

revoke all on function public.ensure_chat(text, uuid, text, jsonb) from public, anon;
revoke all on function public.send_chat_message(uuid, text, text, jsonb, jsonb) from public, anon;
revoke all on function public.post_system_message(uuid, text, uuid, boolean, boolean) from public, anon;
revoke all on function public.mark_chat_read(uuid, boolean) from public, anon;
grant execute on function public.ensure_chat(text, uuid, text, jsonb) to authenticated;
grant execute on function public.send_chat_message(uuid, text, text, jsonb, jsonb) to authenticated;
grant execute on function public.post_system_message(uuid, text, uuid, boolean, boolean) to authenticated;
grant execute on function public.mark_chat_read(uuid, boolean) to authenticated;
drop function if exists public.ensure_chat(text, uuid, text);

-- place_order used the old boolean counters and a direct message insert.
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
    select c.id cart_id, c.quantity, c.selected_size, c.product_id
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

  insert into public.shop_chats
    (kind, seller_id, customer_id, shop_name, customer_name, customer_image_url)
  values ('shop', seller, uid, shop_nm, coalesce(me.display_name, ''), coalesce(me.profile_image_url, ''))
  on conflict (kind, seller_id, customer_id) do update set updated_at = now()
  returning id into chat;
  num := upper(substr(oid::text, 1, 6));

  insert into public.orders (
    id, order_number, seller_id, customer_id, shop_name, customer_name, customer_email,
    customer_address, items, item_count, items_total, delivery_fee, total, fulfilment,
    delivery_area, payment_method, payment_label, status, status_label, status_history, chat_id
  ) values (
    oid, num, seller, uid, shop_nm,
    coalesce(nullif(me.display_name, ''), 'Customer'), coalesce(priv.email, ''),
    coalesce(priv.address, '{}'::jsonb), items, qty_sum, items_sum, fee, items_sum + fee,
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
        to_char(fee, 'FM999999990.00'), to_char(items_sum + fee, 'FM999999990.00'))
    else
      format('Order #%s confirmed for %s. Payment method: pay upon collection. Total: $%s.',
        num, shop_nm, to_char(items_sum, 'FM999999990.00'))
    end;
  insert into public.shop_chat_messages (chat_id, sender_id, text, sender_type, is_system, order_id)
  values (chat, null, msg, 'system', true, oid);
  update public.shop_chats set last_message = msg, last_message_at = now(),
    unread_by_seller = unread_by_seller + 1, unread_by_customer = unread_by_customer + 1,
    updated_at = now() where id = chat;

  insert into public.notifications (user_id, sender_id, type, title, body, extra_data)
  values (seller, uid, 'order_update', 'New order', 'placed order #' || num || '.',
    jsonb_build_object('orderId', oid, 'chatId', chat, 'fromName', me.display_name,
      'shopName', shop_nm, 'sellerId', seller, 'customerId', uid));
  return oid;
end $$;
revoke all on function public.place_order(text, text) from public, anon;
grant execute on function public.place_order(text, text) to authenticated;
