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

/**
 * True when the request carries a service-role token. The gateway has already
 * verified the token's signature (verify_jwt is on), so the role claim can be
 * trusted; this keeps signed-in users' tokens out.
 */
export function isServiceCaller(req: Request): boolean {
  const header = req.headers.get('Authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (key && token === key) return true;
  try {
    const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
    return payload.role === 'service_role';
  } catch {
    return false;
  }
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
