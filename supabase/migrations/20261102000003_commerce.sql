-- Banigoba on Supabase, part 3: shops, stock, bags, orders, chats, requests,
-- events, shared stock links, and the feed's server-written tables.

-- ── products: a shop's window, open to anyone (shared stock links work
--    for people without an account) ──────────────────────────────────────────

create table public.products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null default '',
  description text not null default '',
  category text not null default '',
  subcategory text not null default '',
  price numeric(12, 2) not null default 0 check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  size_inventory jsonb not null default '{}'::jsonb,
  colours text[] not null default '{}',
  gender text not null default 'unisex',
  image_url text not null default '',
  raw_image_url text not null default '',
  extra_image_urls text[] not null default '{}',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index products_seller on public.products (user_id, created_at desc);
create index products_category on public.products (category);
create trigger products_touch before update on public.products
  for each row execute function public.touch_updated_at();

alter table public.products enable row level security;
create policy products_read on public.products for select using (true);
create policy products_create on public.products
  for insert to authenticated with check (user_id = auth.uid());
create policy products_update on public.products
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy products_delete on public.products
  for delete to authenticated using (user_id = auth.uid());

-- Stock only moves down at checkout (place_order, security definer), so a
-- buyer never needs write access to another seller's product.

create table public.product_insights (
  product_id uuid primary key references public.products (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  reach integer not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.product_insights enable row level security;
create policy product_insights_seller on public.product_insights
  for select to authenticated using (seller_id = auth.uid());

-- ── bag ────────────────────────────────────────────────────────────────────

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  quantity integer not null default 1 check (quantity > 0),
  selected_size text not null default '',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, product_id, selected_size)
);
alter table public.cart_items enable row level security;
create policy cart_items_owner on public.cart_items
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── chats ──────────────────────────────────────────────────────────────────

create table public.shop_chats (
  id uuid primary key default gen_random_uuid(),
  kind text not null default 'shop' check (kind in ('shop', 'designer', 'salon')),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  customer_id uuid not null references public.profiles (id) on delete cascade,
  designer_id uuid references public.profiles (id) on delete cascade,
  shop_name text not null default '',
  customer_name text not null default '',
  customer_image_url text not null default '',
  last_message text not null default '',
  unread_for_seller boolean not null default false,
  unread_for_customer boolean not null default false,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (kind, seller_id, customer_id)
);
alter table public.shop_chats enable row level security;

create or replace function public.is_chat_participant(chat public.shop_chats)
returns boolean language sql stable as $$
  select auth.uid() is not null and auth.uid() in (
    chat.seller_id, chat.customer_id, coalesce(chat.designer_id, chat.seller_id)
  )
$$;

create policy shop_chats_read on public.shop_chats
  for select to authenticated using (public.is_chat_participant(shop_chats));
create policy shop_chats_create on public.shop_chats
  for insert to authenticated with check (public.is_chat_participant(shop_chats));
create policy shop_chats_update on public.shop_chats
  for update to authenticated
  using (public.is_chat_participant(shop_chats))
  with check (public.is_chat_participant(shop_chats));

create table public.shop_chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.shop_chats (id) on delete cascade,
  sender_id uuid references public.profiles (id) on delete set null,
  text text not null default '',
  image_url text not null default '',
  is_system boolean not null default false,
  order_id uuid,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index shop_chat_messages_chat on public.shop_chat_messages (chat_id, created_at);
alter table public.shop_chat_messages enable row level security;

create or replace function public.in_chat(target uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.shop_chats c
    where c.id = target and public.is_chat_participant(c)
  )
$$;
create policy shop_chat_messages_read on public.shop_chat_messages
  for select to authenticated using (public.in_chat(chat_id));
create policy shop_chat_messages_create on public.shop_chat_messages
  for insert to authenticated
  with check (public.in_chat(chat_id) and sender_id = auth.uid() and not is_system);
-- Messages are never edited or removed.

-- Find or open the conversation between a customer and a shop, designer or
-- salon. Replaces the three ensure*Conversation helpers.
create or replace function public.ensure_chat(
  p_kind text, p_provider uuid, p_provider_name text default ''
) returns uuid language plpgsql security definer set search_path = public as $$
declare cid uuid; me public.profiles;
begin
  if auth.uid() is null then raise exception 'Sign in first.'; end if;
  select * into me from public.profiles where id = auth.uid();
  insert into public.shop_chats
    (kind, seller_id, customer_id, designer_id, shop_name, customer_name, customer_image_url)
  values (p_kind, p_provider, auth.uid(),
          case when p_kind = 'designer' then p_provider end,
          p_provider_name, coalesce(me.display_name, ''), coalesce(me.profile_image_url, ''))
  on conflict (kind, seller_id, customer_id) do update set updated_at = now()
  returning id into cid;
  return cid;
end $$;

-- ── orders ─────────────────────────────────────────────────────────────────

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null,
  seller_id uuid not null references public.profiles (id) on delete restrict,
  customer_id uuid not null references public.profiles (id) on delete restrict,
  shop_name text not null default '',
  customer_name text not null default '',
  customer_email text not null default '',
  customer_address jsonb not null default '{}'::jsonb,
  items jsonb not null default '[]'::jsonb,
  item_count integer not null default 0,
  items_total numeric(12, 2) not null default 0,
  delivery_fee numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  fulfilment text not null default 'collect' check (fulfilment in ('collect', 'delivery')),
  delivery_area text,
  payment_method text not null default 'pay_upon_collection',
  payment_label text not null default 'Pay upon collection',
  status text not null default 'submitted',
  status_label text not null default 'Submitted',
  status_history jsonb not null default '[]'::jsonb,
  chat_id uuid references public.shop_chats (id) on delete set null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index orders_seller on public.orders (seller_id, created_at desc);
create index orders_customer on public.orders (customer_id, created_at desc);
alter table public.orders enable row level security;

create policy orders_read on public.orders
  for select to authenticated using (auth.uid() in (seller_id, customer_id));
-- Orders are created only by place_order. Either party may move the status
-- (the app limits who does what), but nothing about who or how much changes.
create policy orders_update on public.orders
  for update to authenticated
  using (auth.uid() in (seller_id, customer_id))
  with check (auth.uid() in (seller_id, customer_id));

create or replace function public.guard_order_update()
returns trigger language plpgsql as $$
begin
  if public.is_server() then return new; end if;
  if new.seller_id <> old.seller_id or new.customer_id <> old.customer_id
     or new.items is distinct from old.items or new.total <> old.total
     or new.items_total <> old.items_total or new.delivery_fee <> old.delivery_fee
     or new.order_number <> old.order_number then
    raise exception 'An order''s parties and amounts cannot be changed.';
  end if;
  new.updated_at := now();
  return new;
end $$;
create trigger orders_guard before update on public.orders
  for each row execute function public.guard_order_update();

-- Turns the bag into an order in one transaction: stock goes down (per size
-- where the piece has sizes), the fee is worked out here from the shop's own
-- settings, the bag empties, the chat gets a confirmation and the seller a
-- notification. Returns the order id.
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
    if not coalesce((d->>'enabled')::boolean, true) and d = '{}'::jsonb then
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
  insert into public.shop_chat_messages (chat_id, sender_id, text, is_system, order_id)
  values (chat, null, msg, true, oid);
  update public.shop_chats set last_message = msg, unread_for_seller = true,
    unread_for_customer = true, updated_at = now() where id = chat;

  insert into public.notifications (user_id, sender_id, type, title, body, extra_data)
  values (seller, uid, 'order_update', 'New order', 'placed order #' || num || '.',
    jsonb_build_object('orderId', oid, 'chatId', chat, 'fromName', me.display_name,
      'shopName', shop_nm, 'sellerId', seller, 'customerId', uid));
  return oid;
end $$;
revoke all on function public.place_order(text, text) from public, anon;
grant execute on function public.place_order(text, text) to authenticated;

-- ── design & salon requests ────────────────────────────────────────────────

create table public.design_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles (id) on delete cascade,
  designer_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.agent_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles (id) on delete cascade,
  agent_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
declare t text; provider text;
begin
  foreach t in array array['design_requests', 'agent_requests'] loop
    provider := case t when 'design_requests' then 'designer_id' else 'agent_id' end;
    execute format('alter table public.%I enable row level security', t);
    execute format('create trigger %I before update on public.%I for each row execute function public.touch_updated_at()', t || '_touch', t);
    execute format('create policy %I on public.%I for select to authenticated using (auth.uid() in (customer_id, %I))', t || '_read', t, provider);
    execute format('create policy %I on public.%I for insert to authenticated with check (customer_id = auth.uid())', t || '_create', t);
    -- Either side may update, but a request is never handed to someone else.
    execute format('create policy %I on public.%I for update to authenticated using (auth.uid() in (customer_id, %I)) with check (auth.uid() in (customer_id, %I))', t || '_update', t, provider, provider);
    execute format('create policy %I on public.%I for delete to authenticated using (customer_id = auth.uid())', t || '_delete', t);
  end loop;
end $$;

create or replace function public.guard_request_update()
returns trigger language plpgsql as $$
begin
  if new.customer_id <> old.customer_id then
    raise exception 'A request cannot change hands.';
  end if;
  if tg_table_name = 'design_requests' and new.designer_id <> old.designer_id then
    raise exception 'A request cannot change hands.';
  end if;
  if tg_table_name = 'agent_requests' and new.agent_id <> old.agent_id then
    raise exception 'A request cannot change hands.';
  end if;
  return new;
end $$;
create trigger design_requests_guard before update on public.design_requests
  for each row execute function public.guard_request_update();
create trigger agent_requests_guard before update on public.agent_requests
  for each row execute function public.guard_request_update();

-- ── events ─────────────────────────────────────────────────────────────────

create table public.events (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid not null references public.profiles (id) on delete cascade,
  title text not null default '',
  description text not null default '',
  image_url text not null default '',
  city text not null default '',
  starts_at timestamptz,
  ends_at timestamptz,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.events enable row level security;
create policy events_read on public.events for select to authenticated using (true);
create policy events_create on public.events
  for insert to authenticated with check (submitted_by = auth.uid());
create policy events_update on public.events
  for update to authenticated using (submitted_by = auth.uid()) with check (submitted_by = auth.uid());
create policy events_delete on public.events
  for delete to authenticated using (submitted_by = auth.uid());

-- ── shared stock links (K-9) ───────────────────────────────────────────────

create table public.shop_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 80),
  note text not null default '' check (char_length(note) <= 300),
  scope text not null check (scope in ('all', 'category', 'items')),
  category text not null default '',
  product_ids uuid[] not null default '{}' check (cardinality(product_ids) <= 60),
  audience text not null check (audience in ('link', 'friends', 'followers', 'public')),
  active boolean not null default true,
  announced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index shop_links_owner on public.shop_links (owner_id, created_at desc);
create trigger shop_links_touch before update on public.shop_links
  for each row execute function public.touch_updated_at();
alter table public.shop_links enable row level security;
-- Listing: only public links, and your own. A just-the-link share cannot be
-- found by browsing; it opens through get_shop_link below.
create policy shop_links_list on public.shop_links
  for select using (audience = 'public' or owner_id = auth.uid());
create policy shop_links_create on public.shop_links
  for insert to authenticated with check (owner_id = auth.uid());
create policy shop_links_update on public.shop_links
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy shop_links_delete on public.shop_links
  for delete to authenticated using (owner_id = auth.uid());

create or replace function public.get_shop_link(p_id uuid)
returns public.shop_links language sql stable security definer set search_path = public as $$
  select * from public.shop_links where id = p_id
$$;
grant execute on function public.get_shop_link(uuid) to anon, authenticated;

-- ── feed cards (written by the server; readers see their own) ──────────────

create table public.feed_cards (
  id text primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null default '',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);
create index feed_cards_user on public.feed_cards (user_id, created_at desc);
alter table public.feed_cards enable row level security;
create policy feed_cards_read on public.feed_cards
  for select to authenticated using (user_id = auth.uid());
create policy feed_cards_delete on public.feed_cards
  for delete to authenticated using (user_id = auth.uid());

create table public.feed_dismissed (
  user_id uuid not null references public.profiles (id) on delete cascade,
  card_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, card_id)
);
alter table public.feed_dismissed enable row level security;
create policy feed_dismissed_owner on public.feed_dismissed
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
