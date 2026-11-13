// Payment tries as the smile-pay Edge Functions keep them: reading a try back
// from the gateway, and the shape the app sees.
import type { SupabaseClient } from '@supabase/supabase-js';
import { amountMatches, createSmilePayClient, statusOf } from './smilePay.js';

export type PaymentStatus = 'pending' | 'awaiting_otp' | 'paid' | 'failed' | 'cancelled';
export type PaymentMethod = 'ecocash' | 'onemoney' | 'innbucks' | 'omari' | 'smilecash' | 'card';

export interface PaymentRow {
  id: string;
  order_id: string;
  customer_id: string;
  method: PaymentMethod;
  order_reference: string;
  transaction_reference: string | null;
  amount: number;
  status: PaymentStatus;
  mobile: string | null;
  payment_url: string | null;
  payment_code: string | null;
  message: string | null;
  created_at: string;
}

export interface PaymentView {
  id: string;
  orderId: string;
  method: PaymentMethod;
  status: PaymentStatus;
  amount: number;
  paymentUrl: string | null;
  paymentCode: string | null;
  message: string | null;
}

export type SmilePayClient = ReturnType<typeof createSmilePayClient>;

export const OPEN_STATUSES: PaymentStatus[] = ['pending', 'awaiting_otp'];

export function smilePayClient(): SmilePayClient {
  return createSmilePayClient({
    apiKey: Deno.env.get('SMILE_PAY_API_KEY') ?? '',
    apiSecret: Deno.env.get('SMILE_PAY_API_SECRET') ?? '',
    env: Deno.env.get('SMILE_PAY_ENV') ?? 'sandbox',
  });
}

/** Where Smile&Pay posts results, carrying our shared secret. */
export function webhookUrl(): string {
  const token = Deno.env.get('SMILE_PAY_WEBHOOK_TOKEN');
  if (!token) throw new Error('SMILE_PAY_WEBHOOK_TOKEN is not configured.');
  return `${Deno.env.get('SUPABASE_URL')}/functions/v1/smile-pay-webhook?token=${encodeURIComponent(token)}`;
}

/** Where the card page sends the buyer when they finish. */
export function returnUrl(paymentId: string): string {
  return `${Deno.env.get('SUPABASE_URL')}/functions/v1/smile-pay-webhook?done=${encodeURIComponent(paymentId)}`;
}

export function view(row: PaymentRow): PaymentView {
  return {
    id: row.id,
    orderId: row.order_id,
    method: row.method,
    status: row.status,
    amount: Number(row.amount),
    paymentUrl: row.payment_url,
    paymentCode: row.payment_code,
    message: row.message,
  };
}

export async function loadPayment(db: SupabaseClient, id: string): Promise<PaymentRow | null> {
  const { data, error } = await db.from('payments').select('*').eq('id', id).maybeSingle();
  if (error) throw new Error(`payments ${id}: ${error.message}`);
  return data as PaymentRow | null;
}

export async function updatePayment(
  db: SupabaseClient,
  id: string,
  changes: Record<string, unknown>,
): Promise<PaymentRow> {
  const { data, error } = await db.from('payments').update(changes).eq('id', id).select('*').single();
  if (error) throw new Error(`payments ${id}: ${error.message}`);
  return data as PaymentRow;
}

/**
 * Asks the gateway how [payment] stands and records the answer. Open tries
 * only, unless [evenIfClosed] (the webhook: a try we gave up on may still
 * have been paid, and that money must be recorded). Paid tries go through
 * settle_payment, which marks the order paid exactly once.
 */
export async function refreshPayment(
  db: SupabaseClient,
  client: SmilePayClient,
  payment: PaymentRow,
  { evenIfClosed = false } = {},
): Promise<PaymentRow> {
  if (payment.status === 'paid') return payment;
  if (!evenIfClosed && !OPEN_STATUSES.includes(payment.status)) return payment;

  const answer = await client.status(payment.order_reference);
  if (!answer.ok) {
    console.error('smile-pay: status check failed', payment.id, answer.httpStatus, answer.body);
    return payment;
  }
  const status = statusOf(answer.body);
  const gateway = { lastStatusCheck: answer.body };

  if (status === 'paid') {
    if (!amountMatches(answer.body, payment.amount)) {
      console.error('smile-pay: amount mismatch, not settling', payment.id, payment.amount, answer.body);
      return await updatePayment(db, payment.id, {
        message: 'The amount paid does not match the order. Our team will look into it.',
        gateway_status: String(answer.body?.status ?? ''),
      });
    }
    const fee = Number(answer.body?.clientFee);
    const { error } = await db.rpc('settle_payment', {
      p_payment_id: payment.id,
      p_transaction_reference: answer.body?.reference ?? answer.body?.transactionReference ?? null,
      p_provider_fee: Number.isFinite(fee) ? fee : null,
      p_gateway: gateway,
    });
    if (error) throw new Error(`settle_payment ${payment.id}: ${error.message}`);
    return (await loadPayment(db, payment.id)) ?? payment;
  }

  if ((status === 'failed' || status === 'cancelled') && OPEN_STATUSES.includes(payment.status)) {
    return await updatePayment(db, payment.id, {
      status,
      gateway_status: String(answer.body?.status ?? ''),
      message: status === 'cancelled' ? 'The payment was cancelled.' : 'The payment did not go through.',
      gateway,
    });
  }
  return payment;
}
