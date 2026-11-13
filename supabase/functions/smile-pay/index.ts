// Online payment for an order through Smile&Pay. Called by the app with the
// buyer's token. POST { action, ... }:
//   initiate { orderId, method, mobile? } starts a try for the order's total
//   confirm  { paymentId, otp }           the SMS code for O'mari / SmileCash
//   status   { paymentId }                asks the gateway, records the answer
//   cancel   { paymentId }                gives up on an open try
// Each answers { payment } (see PaymentView). The amount always comes from
// the order row, never from the app.
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { serviceClient } from '../_shared/server.ts';
import {
  loadPayment,
  OPEN_STATUSES,
  type PaymentMethod,
  type PaymentRow,
  refreshPayment,
  returnUrl,
  type SmilePayClient,
  smilePayClient,
  updatePayment,
  view,
  webhookUrl,
} from '../_shared/payments.ts';
import {
  confirmBody,
  initiateBody,
  isMethod,
  makeOrderReference,
  messageOf,
  METHODS,
  normalizeMobile,
  outcomeOf,
} from '../_shared/smilePay.js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });

class Refusal extends Error {
  constructor(message: string, readonly status = 400) {
    super(message);
  }
}

// At most this many tries per order in the window, so a stuck app (or a
// person) cannot flood buyers' phones with USSD pushes.
const MAX_TRIES = 5;
const TRY_WINDOW_MS = 10 * 60 * 1000;

interface OrderRow {
  id: string;
  order_number: string;
  customer_id: string;
  status: string;
  payment_status: string;
  total: number;
  item_count: number;
  shop_name: string;
  customer_name: string;
  customer_email: string;
}

async function signedInUser(req: Request): Promise<string> {
  const asUser = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const { data } = await asUser.auth.getUser();
  const id = data?.user?.id;
  if (!id) throw new Refusal('Sign in to pay.', 401);
  return id;
}

async function ownPayment(db: SupabaseClient, userId: string, id: unknown): Promise<PaymentRow> {
  if (typeof id !== 'string' || !id) throw new Refusal('Which payment?');
  const payment = await loadPayment(db, id);
  if (!payment || payment.customer_id !== userId) throw new Refusal('Payment not found.', 404);
  return payment;
}

async function payableOrder(db: SupabaseClient, userId: string, orderId: unknown): Promise<OrderRow> {
  if (typeof orderId !== 'string' || !orderId) throw new Refusal('Which order?');
  const { data, error } = await db
    .from('orders')
    .select('id, order_number, customer_id, status, payment_status, total, item_count, shop_name, customer_name, customer_email')
    .eq('id', orderId)
    .maybeSingle();
  if (error) throw new Error(`orders ${orderId}: ${error.message}`);
  const order = data as OrderRow | null;
  if (!order || order.customer_id !== userId) throw new Refusal('Order not found.', 404);
  if (order.status === 'cancelled') throw new Refusal('This order was cancelled.', 409);
  if (order.payment_status !== 'unpaid') throw new Refusal('This order is already paid.', 409);
  if (!(Number(order.total) > 0)) throw new Refusal('This order has nothing to pay.', 409);
  return order;
}

/** Closes earlier open tries for the order so only one can be live. */
async function closeOpenTries(db: SupabaseClient, client: SmilePayClient, orderId: string) {
  const { data, error } = await db
    .from('payments')
    .select('*')
    .eq('order_id', orderId)
    .in('status', OPEN_STATUSES);
  if (error) throw new Error(`payments for ${orderId}: ${error.message}`);
  for (const open of (data ?? []) as PaymentRow[]) {
    // It may have gone through meanwhile; record that rather than lose it.
    const fresh = await refreshPayment(db, client, open);
    if (fresh.status === 'paid') throw new Refusal('This order is already paid.', 409);
    if (!OPEN_STATUSES.includes(fresh.status)) continue;
    await client.cancel(fresh.order_reference).catch((e) =>
      console.error('smile-pay: cancel failed', fresh.id, e)
    );
    await updatePayment(db, fresh.id, { status: 'cancelled', message: 'Replaced by a new try.' });
  }
}

async function initiate(db: SupabaseClient, client: SmilePayClient, userId: string, input: Record<string, unknown>) {
  const method = String(input.method ?? '');
  if (!isMethod(method)) throw new Refusal('Choose a way to pay.');
  const spec = METHODS[method as PaymentMethod];
  let mobile: string | null = null;
  if (spec.mobileField) {
    mobile = normalizeMobile(input.mobile);
    if (!mobile) throw new Refusal(`Enter the ${spec.label} mobile number, like 0771234567.`);
  }

  const order = await payableOrder(db, userId, input.orderId);
  const since = new Date(Date.now() - TRY_WINDOW_MS).toISOString();
  const { count, error: countError } = await db
    .from('payments')
    .select('id', { count: 'exact', head: true })
    .eq('order_id', order.id)
    .gte('created_at', since);
  if (countError) throw new Error(`payments count: ${countError.message}`);
  if ((count ?? 0) >= MAX_TRIES) throw new Refusal('Too many tries. Please wait a few minutes.', 429);

  await closeOpenTries(db, client, order.id);

  const orderReference = makeOrderReference(order.order_number);
  const { data: inserted, error } = await db
    .from('payments')
    .insert({
      order_id: order.id,
      customer_id: userId,
      method,
      order_reference: orderReference,
      amount: order.total,
      mobile,
    })
    .select('*')
    .single();
  if (error) throw new Error(`payments insert: ${error.message}`);
  const payment = inserted as PaymentRow;

  const [firstName, ...rest] = (order.customer_name || '').trim().split(/\s+/);
  const body = initiateBody({
    method,
    orderReference,
    amount: order.total,
    resultUrl: webhookUrl(),
    returnUrl: returnUrl(payment.id),
    mobile,
    itemName: `Banigoba order #${order.order_number}`,
    itemDescription: `${order.item_count} item${order.item_count === 1 ? '' : 's'} from ${order.shop_name || 'a Banigoba shop'}`,
    customer: { firstName, lastName: rest.join(' '), email: order.customer_email },
  });

  let answer;
  try {
    answer = await client.initiate(method, body);
  } catch (e) {
    console.error('smile-pay: initiate unreachable', payment.id, e);
    return await updatePayment(db, payment.id, {
      status: 'failed',
      message: 'We could not reach the payment service. Please try again.',
    });
  }

  const outcome = outcomeOf(answer.body?.responseCode);
  if (!answer.ok || (outcome !== 'accepted' && outcome !== 'pending')) {
    console.error('smile-pay: initiate refused', payment.id, answer.httpStatus, answer.body);
    return await updatePayment(db, payment.id, {
      status: outcome === 'cancelled' ? 'cancelled' : 'failed',
      message: messageOf(answer.body),
      gateway: { initiate: answer.body },
    });
  }

  return await updatePayment(db, payment.id, {
    status: spec.confirmPath ? 'awaiting_otp' : 'pending',
    transaction_reference: answer.body?.transactionReference ?? null,
    payment_url: answer.body?.paymentUrl ?? null,
    payment_code: answer.body?.innbucksPaymentCode != null ? String(answer.body.innbucksPaymentCode) : null,
    message: null,
    gateway: { initiate: answer.body },
  });
}

async function confirm(db: SupabaseClient, client: SmilePayClient, userId: string, input: Record<string, unknown>) {
  const payment = await ownPayment(db, userId, input.paymentId);
  if (payment.status !== 'awaiting_otp') return payment;
  const otp = String(input.otp ?? '').trim();
  if (!/^\d{4,8}$/.test(otp)) throw new Refusal('Enter the code from the SMS.');
  if (!payment.transaction_reference) throw new Error(`payment ${payment.id} has no transaction reference`);

  const answer = await client.confirm(
    payment.method,
    confirmBody({
      method: payment.method,
      transactionReference: payment.transaction_reference,
      otp,
      mobile: payment.mobile,
    }),
  );
  const outcome = outcomeOf(answer.body?.responseCode);
  if (answer.ok && outcome === 'invalid_otp') {
    return await updatePayment(db, payment.id, { message: 'That code is not right. Check the SMS and try again.' });
  }
  if (!answer.ok || (outcome !== 'accepted' && outcome !== 'pending')) {
    console.error('smile-pay: confirm refused', payment.id, answer.httpStatus, answer.body);
    return await updatePayment(db, payment.id, {
      status: outcome === 'cancelled' ? 'cancelled' : 'failed',
      message: messageOf(answer.body),
    });
  }
  // Accepted: now it is the gateway's word on the status that counts.
  const pending = await updatePayment(db, payment.id, { status: 'pending', message: null });
  return await refreshPayment(db, client, pending);
}

async function cancel(db: SupabaseClient, client: SmilePayClient, userId: string, input: Record<string, unknown>) {
  const payment = await ownPayment(db, userId, input.paymentId);
  const fresh = await refreshPayment(db, client, payment);
  if (!OPEN_STATUSES.includes(fresh.status)) return fresh;
  await client.cancel(fresh.order_reference).catch((e) => console.error('smile-pay: cancel failed', fresh.id, e));
  return await updatePayment(db, fresh.id, { status: 'cancelled', message: 'You cancelled the payment.' });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return reply({ error: 'Use POST.' }, 405);

  try {
    const userId = await signedInUser(req);
    const input = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    const db = serviceClient();
    const client = smilePayClient();

    let payment: PaymentRow;
    switch (input.action) {
      case 'initiate':
        payment = await initiate(db, client, userId, input);
        break;
      case 'confirm':
        payment = await confirm(db, client, userId, input);
        break;
      case 'status':
        payment = await refreshPayment(db, client, await ownPayment(db, userId, input.paymentId));
        break;
      case 'cancel':
        payment = await cancel(db, client, userId, input);
        break;
      default:
        throw new Refusal('Unknown action.');
    }
    return reply({ payment: view(payment) });
  } catch (e) {
    if (e instanceof Refusal) return reply({ error: e.message }, e.status);
    console.error('smile-pay: failed', e);
    return reply({ error: 'Payment is unavailable right now. Please try again.' }, 500);
  }
});
