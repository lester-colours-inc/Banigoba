-- Online payment for orders through Smile&Pay (ZB Bank's gateway):
-- EcoCash, OneMoney, InnBucks, O'mari, SmileCash and Visa/Mastercard.
--
-- An order is placed first (place_order reserves the stock) and the buyer may
-- then pay it online. Each try is one `payments` row with its own gateway
-- reference. Only the smile-pay Edge Functions (service role) write payments;
-- an order counts as paid only after the server has asked Smile&Pay itself,
-- never on the strength of the app or an unsigned webhook.
--
-- Money: when the buyer pays online the platform holds the money, so the
-- seller no longer owes the commission (it was taken at payment: the entry is
-- settled) and the platform owes the seller their price plus delivery fee
-- (a seller_payout entry that falls due when the order is collected or
-- delivered, like the other entries).

alter table public.orders
  add column payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'paid', 'refund_due', 'refunded')),
  add column paid_at timestamptz;

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  customer_id uuid not null references public.profiles (id) on delete restrict,
  provider text not null default 'smile_pay' check (provider = 'smile_pay'),
  method text not null
    check (method in ('ecocash', 'onemoney', 'innbucks', 'omari', 'smilecash', 'card')),
  -- Ours, sent to the gateway; unique per try because the gateway rejects reuse.
  order_reference text not null unique,
  -- The gateway's; needed for the OTP leg of O'mari and SmileCash.
  transaction_reference text,
  amount numeric(12, 2) not null check (amount > 0),
  currency_code text not null default '840' check (currency_code in ('840', '924')),
  status text not null default 'pending'
    check (status in ('pending', 'awaiting_otp', 'paid', 'failed', 'cancelled')),
  mobile text,
  payment_url text,
  payment_code text,
  message text,
  gateway_status text,
  provider_fee numeric(12, 2),
  gateway jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  paid_at timestamptz
);
create index payments_order on public.payments (order_id, created_at desc);
create index payments_customer on public.payments (customer_id, created_at desc);
-- An order is paid at most once.
create unique index payments_one_paid_per_order on public.payments (order_id)
  where status = 'paid';
alter table public.payments enable row level security;
-- The buyer sees their own tries (the app polls them); curators see all.
-- No insert/update policies: only the Edge Functions write here.
create policy payments_read on public.payments
  for select to authenticated using (customer_id = auth.uid() or public.is_admin());

create or replace function private.touch_payment()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;
create trigger payments_touch before update on public.payments
  for each row execute function private.touch_payment();

alter table public.ledger_entries drop constraint ledger_entries_kind_check;
alter table public.ledger_entries add constraint ledger_entries_kind_check
  check (kind in ('seller_commission_owed', 'influencer_share', 'seller_payout'));

-- The app cannot mark an order paid or change how it was paid.
create or replace function public.guard_order_update()
returns trigger language plpgsql set search_path = public as $$
begin
  -- Whoever cancels a paid order, the buyer is owed their money back.
  if new.status = 'cancelled' and old.status <> 'cancelled' and old.payment_status = 'paid' then
    new.payment_status := 'refund_due';
  end if;
  if public.is_server() then return new; end if;
  if new.seller_id <> old.seller_id or new.customer_id <> old.customer_id
     or new.items is distinct from old.items or new.total <> old.total
     or new.items_total <> old.items_total or new.delivery_fee <> old.delivery_fee
     or new.commission <> old.commission or new.influencer_share <> old.influencer_share
     or new.referrer_id is distinct from old.referrer_id
     or new.order_number <> old.order_number
     or new.payment_status <> old.payment_status
     or new.paid_at is distinct from old.paid_at
     or new.payment_method <> old.payment_method
     or new.payment_label <> old.payment_label then
    raise exception 'An order''s parties, amounts and payment cannot be changed.';
  end if;
  new.updated_at := now();
  return new;
end $$;

-- As before, plus: cancelling a paid order also voids the commission that was
-- taken at payment (the buyer is owed a refund instead).
create or replace function private.sync_ledger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is not distinct from old.status then return new; end if;
  if new.status in ('collected', 'delivered') then
    update public.ledger_entries set status = 'due' where order_id = new.id and status = 'pending';
  elsif new.status = 'cancelled' then
    update public.ledger_entries set status = 'void'
    where order_id = new.id
      and (status in ('pending', 'due')
           or (new.payment_status = 'refund_due' and kind = 'seller_commission_owed'));
  end if;
  return new;
end $$;

-- Records a payment Smile&Pay has confirmed. Called by the Edge Functions
-- (service role) after they have checked the status with the gateway. Safe to
-- call twice: a payment already paid is left alone. Returns the order's
-- payment_status afterwards.
create or replace function public.settle_payment(
  p_payment_id uuid,
  p_transaction_reference text default null,
  p_provider_fee numeric default null,
  p_gateway jsonb default '{}'::jsonb
) returns text language plpgsql security definer set search_path = public as $$
declare
  pay public.payments;
  ord public.orders;
  label text;
  msg text;
  payout_status text;
begin
  select * into pay from public.payments where id = p_payment_id for update;
  if not found then raise exception 'Unknown payment %.', p_payment_id; end if;
  select * into ord from public.orders where id = pay.order_id for update;
  if pay.status = 'paid' then return ord.payment_status; end if;

  update public.payments set
    status = 'paid', paid_at = now(), message = null,
    transaction_reference = coalesce(p_transaction_reference, transaction_reference),
    provider_fee = coalesce(p_provider_fee, provider_fee),
    gateway = gateway || coalesce(p_gateway, '{}'::jsonb)
  where id = pay.id;

  -- A second try that also went through: the order is already paid.
  if ord.payment_status <> 'unpaid' then
    update public.payments set message = 'Duplicate payment: refund due.' where id = pay.id;
    return ord.payment_status;
  end if;

  label := case pay.method
    when 'ecocash' then 'EcoCash' when 'onemoney' then 'OneMoney'
    when 'innbucks' then 'InnBucks' when 'omari' then 'O''mari'
    when 'smilecash' then 'SmileCash' else 'card' end;

  -- Paid for an order that was cancelled meanwhile: keep the money on record
  -- as owed back to the buyer.
  if ord.status = 'cancelled' then
    update public.orders set payment_status = 'refund_due', paid_at = now(),
      payment_method = 'smile_pay_' || pay.method, payment_label = 'Paid with ' || label
    where id = ord.id;
    return 'refund_due';
  end if;

  update public.orders set payment_status = 'paid', paid_at = now(),
    payment_method = 'smile_pay_' || pay.method, payment_label = 'Paid with ' || label
  where id = ord.id;

  -- The platform took the commission with the payment and owes the seller.
  update public.ledger_entries set status = 'settled', settled_at = now()
  where order_id = ord.id and kind = 'seller_commission_owed' and status in ('pending', 'due');
  payout_status := case when ord.status in ('collected', 'delivered') then 'due' else 'pending' end;
  insert into public.ledger_entries (order_id, party_id, kind, amount, status)
  values (ord.id, ord.seller_id, 'seller_payout', ord.items_total + ord.delivery_fee, payout_status);

  msg := format('Order #%s is paid: $%s with %s.', ord.order_number,
    to_char(pay.amount, 'FM999999990.00'), label);
  if ord.chat_id is not null then
    insert into public.shop_chat_messages (chat_id, sender_id, text, sender_type, is_system, order_id)
    values (ord.chat_id, null, msg, 'system', true, ord.id);
    update public.shop_chats set last_message = msg, last_message_at = now(),
      unread_by_seller = unread_by_seller + 1, unread_by_customer = unread_by_customer + 1,
      updated_at = now() where id = ord.chat_id;
  end if;

  insert into public.notifications (user_id, sender_id, type, title, body, extra_data)
  values (ord.seller_id, ord.customer_id, 'order_update', 'Order paid',
    'paid order #' || ord.order_number || ' with ' || label || '.',
    jsonb_build_object('orderId', ord.id, 'chatId', ord.chat_id, 'fromName', ord.customer_name,
      'shopName', ord.shop_name, 'sellerId', ord.seller_id, 'customerId', ord.customer_id));
  return 'paid';
end $$;
revoke all on function public.settle_payment(uuid, text, numeric, jsonb) from public, anon, authenticated;
grant execute on function public.settle_payment(uuid, text, numeric, jsonb) to service_role;

alter table public.payments replica identity full;
alter publication supabase_realtime add table public.payments;
