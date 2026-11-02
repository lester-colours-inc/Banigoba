// Sends a push for each new notification. Called by the database (pg_net)
// when a row is added to `notifications`; the app never calls it.
import { loadServiceAccount, sendPush } from '../_shared/fcm.ts';
import { isServiceCaller, json, serviceClient } from '../_shared/server.ts';

Deno.serve(async (req) => {
  if (!isServiceCaller(req)) return json({ error: 'forbidden' }, 403);
  const { record } = await req.json();
  if (!record?.user_id) return json({ sent: 0 });

  const account = loadServiceAccount();
  if (!account) return json({ sent: 0, reason: 'FCM_SERVICE_ACCOUNT is not set' });

  const db = serviceClient();
  const { data: tokens } = await db.from('fcm_tokens').select('token').eq('user_id', record.user_id);
  if (!tokens?.length) return json({ sent: 0 });

  const title = typeof record.title === 'string' && record.title ? record.title : 'Banigoba';
  const body =
    typeof record.body === 'string' && record.body ? record.body : 'You have a new notification.';
  const data: Record<string, string> = {
    type: typeof record.type === 'string' ? record.type : 'general',
    notificationId: String(record.id ?? ''),
  };
  for (const [key, value] of Object.entries(record.extra_data ?? {})) {
    if (value === null || value === undefined) continue;
    data[key] = typeof value === 'string' ? value : JSON.stringify(value);
  }

  let sent = 0;
  for (const { token } of tokens) {
    if (typeof token !== 'string' || !token) continue;
    const result = await sendPush(account, token, title, body, data);
    if (result === 'sent') sent += 1;
    if (result === 'stale') {
      await db.from('fcm_tokens').delete().eq('user_id', record.user_id).eq('token', token);
    }
  }
  return json({ sent });
});
