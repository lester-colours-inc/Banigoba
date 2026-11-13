// Smile&Pay (ZB Bank payment gateway) client and the rules for reading its
// answers. Docs: https://smileandpay.zb.co.zw/documentation
//
// Every request carries the merchant key and secret as headers, so this runs
// only in Edge Functions. Plain JS (no Deno globals) so `node --test` covers it.

const BASE_URLS = {
  sandbox: 'https://zbnet.zb.co.zw/wallet_sandbox_api/payments-gateway',
  production: 'https://zbnet.zb.co.zw/wallet_gateway/payments-gateway',
};

const USD = '840';
const REQUEST_TIMEOUT_MS = 30_000;

/**
 * The ways to pay. Mobile-money methods use Express Checkout (a USSD push,
 * an InnBucks code, or an SMS OTP the buyer types into the app); cards use
 * the gateway's hosted page so card numbers never pass through our servers.
 *
 * @typedef {{ label: string, path: string, mobileField?: string,
 *   confirmPath?: string, hosted?: boolean, paymentMethod?: string }} MethodSpec
 * @type {Record<'ecocash'|'onemoney'|'innbucks'|'omari'|'smilecash'|'card', MethodSpec>}
 */
const METHODS = {
  ecocash: {
    label: 'EcoCash',
    path: '/payments/express-checkout/ecocash',
    mobileField: 'ecocashMobile',
  },
  onemoney: {
    label: 'OneMoney',
    path: '/payments/express-checkout/onemoney',
    mobileField: 'oneMoneyMobile',
  },
  innbucks: {
    label: 'InnBucks',
    path: '/payments/express-checkout/innbucks',
  },
  omari: {
    label: "O'mari",
    path: '/payments/express-checkout/omari',
    mobileField: 'omariMobile',
    confirmPath: '/payments/express-checkout/omari/confirmation',
  },
  smilecash: {
    label: 'SmileCash',
    path: '/payments/express-checkout/zb-payment',
    mobileField: 'zbWalletMobile',
    confirmPath: '/payments/express-checkout/zb-payment/confirmation',
  },
  card: {
    label: 'Visa/Mastercard',
    path: '/payments/initiate-transaction',
    hosted: true,
    paymentMethod: 'CARD',
  },
};

const isMethod = (method) => Object.prototype.hasOwnProperty.call(METHODS, method);

/**
 * A Zimbabwean mobile number as digits ('0771234567' or '263771234567'), or
 * null when it cannot be one. Spaces, dashes and a leading '+' are dropped.
 */
function normalizeMobile(raw) {
  const digits = String(raw ?? '').replace(/[\s\-()]/g, '').replace(/^\+/, '');
  if (!/^\d+$/.test(digits)) return null;
  if (/^2637\d{8}$/.test(digits)) return digits;
  if (/^07\d{8}$/.test(digits)) return digits;
  if (/^7\d{8}$/.test(digits)) return `0${digits}`;
  return null;
}

/**
 * A reference unique to one payment try. The gateway refuses a reference it
 * has seen (code 06), so retries of the same order each get a new one.
 */
function makeOrderReference(orderNumber, now = Date.now(), random = Math.random()) {
  const order = String(orderNumber || 'ORDER').replace(/[^A-Za-z0-9]/g, '').toUpperCase();
  const stamp = now.toString(36).toUpperCase();
  const salt = Math.floor(random * 36 ** 3).toString(36).toUpperCase().padStart(3, '0');
  return `BNG-${order}-${stamp}${salt}`;
}

/** The request body that starts a payment with [method]. */
function initiateBody({
  method,
  orderReference,
  amount,
  resultUrl,
  returnUrl,
  mobile,
  itemName,
  itemDescription,
  customer = {},
}) {
  const spec = METHODS[method];
  if (!spec) throw new Error(`Unknown payment method: ${method}`);
  const body = {
    orderReference,
    amount: Math.round(Number(amount) * 100) / 100,
    currencyCode: USD,
    resultUrl,
    itemName,
    itemDescription,
  };
  if (spec.mobileField) body[spec.mobileField] = mobile;
  if (spec.hosted) {
    Object.assign(body, {
      returnUrl,
      paymentMethod: spec.paymentMethod,
      ...(customer.firstName ? { firstName: customer.firstName } : {}),
      ...(customer.lastName ? { lastName: customer.lastName } : {}),
      ...(customer.email ? { email: customer.email } : {}),
      ...(mobile ? { mobilePhoneNumber: mobile } : {}),
    });
  }
  return body;
}

/** The body that confirms an O'mari or SmileCash payment with its OTP. */
function confirmBody({ method, transactionReference, otp, mobile }) {
  const spec = METHODS[method];
  if (!spec?.confirmPath) throw new Error(`${method} has no OTP step.`);
  const body = { transactionReference, otp: String(otp ?? '').trim() };
  if (method === 'omari') body.omariMobile = mobile;
  return body;
}

/**
 * What a responseCode on an initiate or confirm call means for the try.
 * See "Error Codes" in the docs.
 */
function outcomeOf(responseCode) {
  switch (String(responseCode ?? '')) {
    case '00':
      return 'accepted';
    case '01':
      return 'pending';
    case '08':
      return 'cancelled';
    case '09':
      return 'invalid_otp';
    default:
      return 'failed';
  }
}

const PAID = new Set(['PAID', 'SUCCESS', 'SUCCESSFUL', 'COMPLETED', 'COMPLETE', 'APPROVED', 'SETTLED']);
const FAILED = new Set(['FAILED', 'FAILURE', 'DECLINED', 'ERROR', 'EXPIRED', 'TIMEOUT', 'TIMED_OUT', 'REVERSED', 'REJECTED']);
const CANCELLED = new Set(['CANCELED', 'CANCELLED']);

/**
 * Reads a status check (or callback) answer: 'paid', 'failed', 'cancelled'
 * or 'pending'. Only an explicit status counts; a responseCode of '00' on a
 * status check means the query worked, not that the buyer paid.
 */
function statusOf(body) {
  const raw =
    body?.status ??
    body?.transactionStatus ??
    body?.paymentStatus ??
    body?.data?.status ??
    body?.data?.transactionStatus ??
    '';
  const status = String(raw).trim().toUpperCase().replace(/\s+/g, '_');
  if (PAID.has(status)) return 'paid';
  if (CANCELLED.has(status)) return 'cancelled';
  if (FAILED.has(status)) return 'failed';
  return 'pending';
}

/** The amount in a gateway answer, or null when it gives none. */
function amountOf(body) {
  const raw = body?.amount ?? body?.data?.amount;
  const value = Number(raw);
  return raw === undefined || raw === null || raw === '' || Number.isNaN(value) ? null : value;
}

/** True unless the gateway names an amount different from ours. */
function amountMatches(body, expected) {
  const amount = amountOf(body);
  return amount === null || Math.abs(amount - Number(expected)) < 0.005;
}

/** The buyer-facing words for a failed try. */
function messageOf(body, fallback = 'The payment did not go through.') {
  const text = String(body?.responseMessage ?? body?.message ?? '').trim();
  return text || fallback;
}

/**
 * A client for one environment. [fetchImpl] is injectable for tests.
 * Each call resolves to { ok, httpStatus, body } and never throws for an
 * HTTP error; network failures and timeouts do throw.
 */
function createSmilePayClient({ apiKey, apiSecret, env = 'sandbox', fetchImpl = fetch }) {
  if (!apiKey || !apiSecret) throw new Error('Smile&Pay credentials are not configured.');
  const base = BASE_URLS[env];
  if (!base) throw new Error(`Unknown Smile&Pay environment: ${env}`);

  async function call(path, { method = 'POST', body } = {}) {
    const response = await fetchImpl(`${base}${path}`, {
      method,
      headers: {
        'x-api-key': apiKey,
        'x-api-secret': apiSecret,
        ...(body ? { 'Content-Type': 'application/json' } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
    const text = await response.text();
    let parsed;
    try {
      parsed = text ? JSON.parse(text) : {};
    } catch {
      parsed = { raw: text };
    }
    return { ok: response.ok, httpStatus: response.status, body: parsed };
  }

  const ref = (value) => encodeURIComponent(value);

  return {
    initiate: (method, body) => call(METHODS[method].path, { body }),
    confirm: (method, body) => call(METHODS[method].confirmPath, { body }),
    status: (orderReference) =>
      call(`/payments/transaction/${ref(orderReference)}/status/check`, { method: 'GET' }),
    cancel: (orderReference) => call(`/payments/cancel/${ref(orderReference)}`),
  };
}

export {
  BASE_URLS,
  METHODS,
  amountMatches,
  amountOf,
  confirmBody,
  createSmilePayClient,
  initiateBody,
  isMethod,
  makeOrderReference,
  messageOf,
  normalizeMobile,
  outcomeOf,
  statusOf,
};
