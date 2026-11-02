// Sends push messages through Firebase Cloud Messaging (HTTP v1) with the
// Firebase project's service account. Firebase is used for push only.

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

let cached: { token: string; expires: number } | null = null;

const b64url = (input: ArrayBuffer | string): string => {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : new Uint8Array(input);
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

async function signJwt(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = b64url(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const pem = account.private_key.replace(/-----[A-Z ]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`));
  return `${header}.${claims}.${b64url(signature)}`;
}

export function loadServiceAccount(): ServiceAccount | null {
  const raw = Deno.env.get('FCM_SERVICE_ACCOUNT');
  if (!raw) return null;
  try {
    return JSON.parse(raw) as ServiceAccount;
  } catch {
    return null;
  }
}

async function accessToken(account: ServiceAccount): Promise<string> {
  if (cached && cached.expires > Date.now() + 60_000) return cached.token;
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: await signJwt(account),
    }),
  });
  if (!response.ok) throw new Error(`FCM auth failed: ${response.status}`);
  const body = await response.json();
  cached = { token: body.access_token, expires: Date.now() + body.expires_in * 1000 };
  return cached.token;
}

export type PushResult = 'sent' | 'stale' | 'failed';

/** Sends one message to one device token. */
export async function sendPush(
  account: ServiceAccount,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<PushResult> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${await accessToken(account)}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: {
            priority: 'HIGH',
            notification: { sound: 'default', click_action: 'FLUTTER_NOTIFICATION_CLICK' },
          },
          apns: {
            headers: { 'apns-priority': '10', 'apns-push-type': 'alert' },
            payload: { aps: { alert: { title, body }, sound: 'default' } },
          },
        },
      }),
    },
  );
  if (response.ok) return 'sent';
  if (response.status === 404 || response.status === 400) {
    const error = await response.json().catch(() => ({}));
    const code = error?.error?.details?.[0]?.errorCode ?? error?.error?.status;
    if (code === 'UNREGISTERED' || code === 'INVALID_ARGUMENT' || response.status === 404) return 'stale';
  }
  return 'failed';
}
