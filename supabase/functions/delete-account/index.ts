// Deletes the signed-in person's account (App Store guideline 5.1.1(v)).
// Called by the app from Settings after the person confirms. Removes their
// stored pictures, then the auth user; every table holding their data
// references the user with "on delete cascade", so the rows go with it.
import { createClient } from '@supabase/supabase-js';
import { serviceClient } from '../_shared/server.ts';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });

// Buckets whose files sit under a folder named after their owner's id.
const USER_BUCKETS = ['product-images', 'events', 'user-images', 'ai-makeovers'];
const PAGE = 1000;

/** Every file path under [prefix] in [bucket], walking sub-folders. */
async function listAll(
  db: ReturnType<typeof serviceClient>,
  bucket: string,
  prefix: string,
): Promise<string[]> {
  const paths: string[] = [];
  for (let offset = 0; ; offset += PAGE) {
    const { data, error } = await db.storage.from(bucket).list(prefix, { limit: PAGE, offset });
    if (error) throw new Error(`${bucket}/${prefix}: ${error.message}`);
    if (!data?.length) break;
    for (const entry of data) {
      const path = `${prefix}/${entry.name}`;
      // Folders have no id; files do.
      if (entry.id) paths.push(path);
      else paths.push(...(await listAll(db, bucket, path)));
    }
    if (data.length < PAGE) break;
  }
  return paths;
}

async function removeUserFiles(db: ReturnType<typeof serviceClient>, userId: string) {
  for (const bucket of USER_BUCKETS) {
    const paths = await listAll(db, bucket, userId);
    for (let i = 0; i < paths.length; i += PAGE) {
      const { error } = await db.storage.from(bucket).remove(paths.slice(i, i + PAGE));
      if (error) throw new Error(`${bucket}: ${error.message}`);
    }
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return reply({ error: 'Use POST.' }, 405);

  const asUser = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const { data } = await asUser.auth.getUser();
  const userId = data?.user?.id;
  if (!userId) return reply({ error: 'You must be signed in to delete your account.' }, 401);

  const db = serviceClient();
  try {
    await removeUserFiles(db, userId);
  } catch (error) {
    console.error('delete-account: removing files failed', userId, error);
    return reply({ error: 'We could not remove your pictures. Please try again.' }, 500);
  }

  const { error } = await db.auth.admin.deleteUser(userId);
  if (error) {
    console.error('delete-account: deleting the user failed', userId, error);
    return reply({ error: 'We could not delete your account. Please try again.' }, 500);
  }
  return reply({ deleted: true });
});
