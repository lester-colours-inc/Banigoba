// Searches the web for pictures of a look (called by the signed-in app from
// "Find a look you love" and the Style idol field). The image search key stays
// on the server; the app gets back only public HTTPS pictures it can show and
// the AI job can fetch.
//
// Needs the BRAVE_SEARCH_API_KEY secret (Brave Search API, image search).
import { createClient } from '@supabase/supabase-js';

import { cleanQuery, toWebLooks, WEB_LOOK_LIMITS } from '../_shared/webLooks.js';

const ENDPOINT = 'https://api.search.brave.com/res/v1/images/search';
const TIMEOUT_MS = 10_000;

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
  if (!user?.user) return reply({ error: 'Sign in to search the web.' }, 401);

  const apiKey = Deno.env.get('BRAVE_SEARCH_API_KEY');
  if (!apiKey) return reply({ error: 'Web search is not set up yet.' }, 503);

  const body = await req.json().catch(() => ({}));
  const query = cleanQuery(body.query);
  if (!query) return reply({ error: 'Type at least two letters to search.' }, 400);

  const url = new URL(ENDPOINT);
  url.searchParams.set('q', query);
  url.searchParams.set('count', String(WEB_LOOK_LIMITS.results * 2));
  url.searchParams.set('safesearch', 'strict');
  try {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { Accept: 'application/json', 'X-Subscription-Token': apiKey },
    });
    if (!response.ok) {
      console.error('search-looks: HTTP', response.status, (await response.text()).slice(0, 300));
      return reply({ error: 'Web search is not available right now.' }, 502);
    }
    return reply({ looks: toWebLooks(await response.json()) });
  } catch (error) {
    console.error('search-looks failed', error);
    return reply({ error: 'Web search is not available right now.' }, 502);
  }
});
