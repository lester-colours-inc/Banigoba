// Shared by the Edge Functions: the service-role client and the check that a
// request really comes from our own database (pg_net with the service key).
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

export function serviceClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );
}

/** True when the request carries the project's service-role key. */
export function isServiceCaller(req: Request): boolean {
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const header = req.headers.get('Authorization') ?? '';
  return !!key && header === `Bearer ${key}`;
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export const utcDay = (date = new Date()): string => date.toISOString().slice(0, 10);

/** Runs [tasks] in groups of [size], collecting the results as they settle. */
export async function inGroups<T, R>(
  items: T[],
  size: number,
  task: (item: T) => Promise<R>,
): Promise<PromiseSettledResult<R>[]> {
  const out: PromiseSettledResult<R>[] = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(...(await Promise.allSettled(items.slice(i, i + size).map(task))));
  }
  return out;
}
