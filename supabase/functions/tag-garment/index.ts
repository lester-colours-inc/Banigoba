// Suggests tags for a photo of one piece of clothing (called by the signed-in
// app while it fills in an item). Quick and answered straight away, unlike the
// image jobs, but it lives here so the Gemini key never ships in the app.
//
// The app sends the photo and the question it wants asked (the question names
// the app's own vocabulary, which only the app knows); the answer is returned
// as Gemini gave it and cut down to that vocabulary by the app.
import { createClient } from '@supabase/supabase-js';

const MODEL = Deno.env.get('GEMINI_TAG_MODEL') || 'gemini-flash-latest';
const TIMEOUT_MS = 25_000;
const MAX_BYTES = 6 * 1024 * 1024;
const MAX_PROMPT_CHARS = 6000;
const MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic']);

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
  if (!user?.user) return reply({ error: 'Sign in to get suggestions.' }, 401);

  const apiKey = Deno.env.get('GEMINI_API_KEY');
  if (!apiKey) return reply({ error: 'Suggestions are not set up.' }, 503);

  const body = await req.json().catch(() => ({}));
  const image = typeof body.image === 'string' ? body.image : '';
  const prompt = typeof body.prompt === 'string' ? body.prompt.trim() : '';
  const mimeType = typeof body.mimeType === 'string' && MIME_TYPES.has(body.mimeType) ? body.mimeType : 'image/jpeg';
  const schema = body.schema && typeof body.schema === 'object' ? body.schema : undefined;
  // Base64 is a third larger than the photo.
  if (!image || image.length > (MAX_BYTES * 4) / 3 + 4) return reply({ error: 'The photo is missing or too large.' }, 400);
  if (!prompt || prompt.length > MAX_PROMPT_CHARS) return reply({ error: 'The question is missing or too long.' }, 400);

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: 'POST',
        signal: AbortSignal.timeout(TIMEOUT_MS),
        headers: { 'x-goog-api-key': apiKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }, { inline_data: { mime_type: mimeType, data: image } }] }],
          generationConfig: {
            responseMimeType: 'application/json',
            ...(schema ? { responseSchema: schema } : {}),
            temperature: 0.2,
          },
        }),
      },
    );
    if (!response.ok) {
      console.error('tag-garment: Gemini HTTP', response.status, (await response.text()).slice(0, 300));
      return reply({ error: 'No suggestion this time.' }, 502);
    }
    const decoded = await response.json();
    const text = decoded?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== 'string') return reply({ tags: null });
    try {
      const tags = JSON.parse(text);
      return reply({ tags: tags && typeof tags === 'object' && !Array.isArray(tags) ? tags : null });
    } catch {
      return reply({ tags: null });
    }
  } catch (error) {
    console.error('tag-garment failed', error);
    return reply({ error: 'No suggestion this time.' }, 502);
  }
});
