import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import {
  amountMatches,
  confirmBody,
  createSmilePayClient,
  initiateBody,
  makeOrderReference,
  normalizeMobile,
  outcomeOf,
  statusOf,
} from '../smilePay.js';

describe('smilePay', () => {
  test('normalizeMobile accepts local and international Zimbabwean numbers', () => {
    assert.equal(normalizeMobile('0771 234 567'), '0771234567');
    assert.equal(normalizeMobile('+263 77-123-4567'), '263771234567');
    assert.equal(normalizeMobile('771234567'), '0771234567');
  });

  test('normalizeMobile rejects what cannot be a mobile number', () => {
    assert.equal(normalizeMobile(''), null);
    assert.equal(normalizeMobile('12345'), null);
    assert.equal(normalizeMobile('0241234567'), null);
    assert.equal(normalizeMobile('07712345ab'), null);
  });

  test('makeOrderReference is unique per try and safe for a URL path', () => {
    const a = makeOrderReference('ab12cd', 1_700_000_000_000, 0.1);
    const b = makeOrderReference('ab12cd', 1_700_000_000_001, 0.1);
    assert.match(a, /^BNG-AB12CD-[0-9A-Z]+$/);
    assert.notEqual(a, b);
  });

  test('initiateBody puts the mobile number in the method-specific field', () => {
    const body = initiateBody({
      method: 'ecocash',
      orderReference: 'R1',
      amount: 12.345,
      resultUrl: 'https://x/webhook',
      mobile: '0771234567',
      itemName: 'Order #1',
      itemDescription: '2 pieces',
    });
    assert.deepEqual(body, {
      orderReference: 'R1',
      amount: 12.35,
      currencyCode: '840',
      resultUrl: 'https://x/webhook',
      itemName: 'Order #1',
      itemDescription: '2 pieces',
      ecocashMobile: '0771234567',
    });
  });

  test('initiateBody sends cards to the hosted page without card details', () => {
    const body = initiateBody({
      method: 'card',
      orderReference: 'R2',
      amount: 5,
      resultUrl: 'https://x/webhook',
      returnUrl: 'https://x/return',
      itemName: 'Order',
      itemDescription: 'd',
      customer: { firstName: 'Tari', email: 't@example.com' },
    });
    assert.equal(body.paymentMethod, 'CARD');
    assert.equal(body.returnUrl, 'https://x/return');
    assert.equal(body.firstName, 'Tari');
    assert.equal(body.pan, undefined);
  });

  test('initiateBody refuses unknown methods', () => {
    assert.throws(() => initiateBody({ method: 'paypal' }), /Unknown payment method/);
  });

  test('confirmBody adds the mobile only for omari', () => {
    assert.deepEqual(
      confirmBody({ method: 'omari', transactionReference: 'T', otp: ' 000000 ', mobile: '0731234567' }),
      { transactionReference: 'T', otp: '000000', omariMobile: '0731234567' },
    );
    assert.deepEqual(confirmBody({ method: 'smilecash', transactionReference: 'T', otp: '1' }), {
      transactionReference: 'T',
      otp: '1',
    });
    assert.throws(() => confirmBody({ method: 'ecocash' }), /no OTP step/);
  });

  test('outcomeOf maps gateway response codes', () => {
    assert.equal(outcomeOf('00'), 'accepted');
    assert.equal(outcomeOf('01'), 'pending');
    assert.equal(outcomeOf('08'), 'cancelled');
    assert.equal(outcomeOf('09'), 'invalid_otp');
    assert.equal(outcomeOf('03'), 'failed');
    assert.equal(outcomeOf(undefined), 'failed');
  });

  test('statusOf only reports paid on an explicit status', () => {
    assert.equal(statusOf({ status: 'PAID' }), 'paid');
    assert.equal(statusOf({ data: { transactionStatus: 'successful' } }), 'paid');
    assert.equal(statusOf({ status: 'Canceled' }), 'cancelled');
    assert.equal(statusOf({ status: 'DECLINED' }), 'failed');
    assert.equal(statusOf({ responseCode: '00' }), 'pending');
    assert.equal(statusOf(null), 'pending');
  });

  test('amountMatches tolerates a missing amount but not a different one', () => {
    assert.equal(amountMatches({}, 10), true);
    assert.equal(amountMatches({ amount: '10.00' }, 10), true);
    assert.equal(amountMatches({ amount: 9.99 }, 10), false);
  });

  test('client sends both credential headers and reads JSON', async () => {
    const calls = [];
    const client = createSmilePayClient({
      apiKey: 'k',
      apiSecret: 's',
      fetchImpl: async (url, init) => {
        calls.push({ url, init });
        return new Response(JSON.stringify({ status: 'PAID' }), { status: 200 });
      },
    });
    const result = await client.status('BNG-1/2');
    assert.equal(result.body.status, 'PAID');
    assert.equal(
      calls[0].url,
      'https://zbnet.zb.co.zw/wallet_sandbox_api/payments-gateway/payments/transaction/BNG-1%2F2/status/check',
    );
    assert.equal(calls[0].init.method, 'GET');
    assert.equal(calls[0].init.headers['x-api-key'], 'k');
    assert.equal(calls[0].init.headers['x-api-secret'], 's');
  });

  test('client keeps non-JSON error bodies instead of throwing', async () => {
    const client = createSmilePayClient({
      apiKey: 'k',
      apiSecret: 's',
      env: 'production',
      fetchImpl: async () => new Response('Bad gateway', { status: 502 }),
    });
    const result = await client.cancel('R');
    assert.equal(result.ok, false);
    assert.equal(result.httpStatus, 502);
    assert.deepEqual(result.body, { raw: 'Bad gateway' });
  });

  test('client refuses to start without credentials', () => {
    assert.throws(() => createSmilePayClient({ apiKey: '', apiSecret: 's' }), /not configured/);
  });
});
