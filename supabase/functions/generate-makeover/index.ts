// Placeholder for the protected AI makeover call (called by the signed-in
// app). Replace the stand-in below with the provider call; the app already
// expects `generatedImageUrls`.
import { createClient } from '@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const client = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const { data: user } = await client.auth.getUser();
  if (!user?.user) return reply({ error: 'You must be signed in to generate a makeover.' }, 401);

  const body = await req.json().catch(() => ({}));
  const style = typeof body.style === 'string' ? body.style.trim() : '';
  const imageUrl = typeof body.imageUrl === 'string' ? body.imageUrl.trim() : '';
  if (!style || !imageUrl) return reply({ error: 'style and imageUrl are required.' }, 400);

  let parsed: URL;
  try {
    parsed = new URL(imageUrl);
  } catch {
    return reply({ error: 'imageUrl must be a valid URL.' }, 400);
  }
  if (parsed.protocol !== 'https:') return reply({ error: 'imageUrl must use HTTPS.' }, 400);

  // Replace this placeholder with the protected AI provider call.
  return reply({ generatedImageUrls: [imageUrl, imageUrl, imageUrl] });
});
