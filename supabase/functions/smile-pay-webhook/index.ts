// Smile&Pay's resultUrl and the card page's returnUrl. No user token, so
// verify_jwt is off for this function (config.toml).
//
// POST (the gateway's callback): the URL must carry our secret token. The
// payload is not signed, so it is only a nudge: we look up the try by its
// orderReference and ask the gateway for the real status before recording
// anything. Answers 200 once handled so the gateway stops retrying.
//
// GET ?done=<paymentId>: where the buyer lands after the card page. Plain
// text (Supabase serves function HTML as text); the app is polling the
// payment and updates on its own.
import { serviceClient } from '../_shared/server.ts';
import { refreshPayment, smilePayClient, type PaymentRow } from '../_shared/payments.ts';

const text = (body: string, status = 200) =>
  new Response(body, { status, headers: { 'Content-Type': 'text/plain; charset=utf-8' } });

/** Compares without leaking, through timing, how much of the token matched. */
function sameSecret(given: string, expected: string): boolean {
  const a = new TextEncoder().encode(given);
  const b = new TextEncoder().encode(expected);
  let diff = a.length ^ b.length;
  for (let i = 0; i < b.length; i++) diff |= (a[i] ?? 0) ^ b[i];
  return diff === 0;
}

/** The order reference from a gateway or eWallet (ISO 20022 style) callback. */
function referenceIn(body: Record<string, unknown>): string | null {
  const direct = body.orderReference;
  if (typeof direct === 'string' && direct) return direct;
  // deno-lint-ignore no-explicit-any
  const ewallet = (body as any)?.originalPaymentInfoAndStatusList?.[0]?.transactionInfoAndStatusList?.[0];
  const ref = ewallet?.originalEndToEndId ?? ewallet?.originalInstructionId;
  return typeof ref === 'string' && ref ? ref : null;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);

  if (req.method === 'GET') {
    return text('Thank you. You can go back to the Banigoba app to see your payment.');
  }
  if (req.method !== 'POST') return text('Method not allowed.', 405);

  const expected = Deno.env.get('SMILE_PAY_WEBHOOK_TOKEN') ?? '';
  if (!expected || !sameSecret(url.searchParams.get('token') ?? '', expected)) {
    return text('Unauthorized.', 401);
  }

  const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
  const reference = referenceIn(body);
  if (!reference) return text('No order reference; ignored.');

  try {
    const db = serviceClient();
    const { data, error } = await db
      .from('payments')
      .select('*')
      .eq('order_reference', reference)
      .maybeSingle();
    if (error) throw new Error(`payments ${reference}: ${error.message}`);
    if (!data) return text('Unknown reference; ignored.');

    const payment = await refreshPayment(db, smilePayClient(), data as PaymentRow, { evenIfClosed: true });
    return text(`Recorded: ${payment.status}.`);
  } catch (e) {
    // Not 200: let the gateway retry once we are healthy again.
    console.error('smile-pay-webhook: failed', reference, e);
    return text('Could not record the payment.', 500);
  }
});
