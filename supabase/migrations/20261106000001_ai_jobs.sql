-- AI image generation runs on the server, so it keeps going when the app is
-- closed and the person is told (a notification, so a push) when it is done.
--
-- The app adds a row to `ai_jobs`; a trigger hands it to the `run-ai-job`
-- Edge Function, which calls Gemini, stores the pictures and writes progress
-- back to the row (the app watches it live). The Gemini key lives only in the
-- function's secrets. A sweep every minute picks up a job whose function died.

create table public.ai_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('look', 'try_on', 'turn_around', 'makeover')),
  status text not null default 'queued' check (status in ('queued', 'running', 'succeeded', 'failed')),
  input jsonb not null,
  result jsonb not null default '{}'::jsonb,
  error text not null default '',
  attempts int not null default 0,
  heartbeat_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index ai_jobs_user on public.ai_jobs (user_id, created_at desc);
create index ai_jobs_open on public.ai_jobs (status, updated_at) where status in ('queued', 'running');
create trigger ai_jobs_touch before update on public.ai_jobs
  for each row execute function public.touch_updated_at();

alter table public.ai_jobs enable row level security;
create policy ai_jobs_owner_read on public.ai_jobs
  for select to authenticated using (user_id = auth.uid());
-- A person may only ask; only the server moves a job along.
create policy ai_jobs_owner_create on public.ai_jobs
  for insert to authenticated with check (
    user_id = auth.uid() and status = 'queued' and attempts = 0
    and result = '{}'::jsonb and error = '' and heartbeat_at is null);
create policy ai_jobs_owner_delete on public.ai_jobs
  for delete to authenticated using (user_id = auth.uid());

-- Every job costs money, so a person can have only a few at once and a fair
-- number per hour.
create or replace function private.limit_ai_jobs()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.ai_jobs
      where user_id = new.user_id and status in ('queued', 'running')) >= 4 then
    raise exception 'You already have looks being made. Wait for one to finish.'
      using errcode = 'P0001';
  end if;
  if (select count(*) from public.ai_jobs
      where user_id = new.user_id and created_at > now() - interval '1 hour') >= 40 then
    raise exception 'You have made a lot of looks this hour. Try again a little later.'
      using errcode = 'P0001';
  end if;
  return new;
end $$;
create trigger ai_jobs_limit before insert on public.ai_jobs
  for each row execute function private.limit_ai_jobs();

create or replace function private.start_ai_job()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform private.call_edge_function('run-ai-job', jsonb_build_object('jobId', new.id));
  return new;
end $$;
create trigger ai_jobs_start after insert on public.ai_jobs
  for each row execute function private.start_ai_job();

-- How long a running job may go without a sign of life before it is retried.
-- Longer than one Gemini call (two minutes) so a slow call is not doubled.
create or replace function private.ai_job_stale_after()
returns interval language sql immutable as $$ select interval '4 minutes' $$;

-- Takes a job for one run of the function. Only one run holds a job: a queued
-- one, or a running one that has gone quiet. Null when there is nothing to do.
create or replace function public.claim_ai_job(job uuid)
returns public.ai_jobs language plpgsql security definer set search_path = public as $$
declare claimed public.ai_jobs;
begin
  update public.ai_jobs
     set status = 'running', attempts = attempts + 1, heartbeat_at = now()
   where id = job
     and (status = 'queued'
          or (status = 'running' and heartbeat_at < now() - private.ai_job_stale_after()))
  returning * into claimed;
  return claimed;
end $$;
revoke all on function public.claim_ai_job(uuid) from public, anon, authenticated;
grant execute on function public.claim_ai_job(uuid) to service_role;

-- Retries jobs whose call was lost or whose function stopped, and gives up
-- (telling the person) after three tries.
create or replace function private.sweep_ai_jobs()
returns void language plpgsql security definer set search_path = public as $$
declare job record;
begin
  for job in
    update public.ai_jobs
       set status = 'failed',
           error = 'We could not finish this. Please try again.'
     where status in ('queued', 'running')
       and attempts >= 3
       and coalesce(heartbeat_at, updated_at) < now() - private.ai_job_stale_after()
    returning id, user_id, kind
  loop
    insert into public.notifications (user_id, type, title, body, extra_data)
    values (job.user_id, 'ai_job', 'Your look did not finish',
            'Something went wrong while making it. Open Banigoba to try again.',
            jsonb_build_object('jobId', job.id, 'kind', job.kind, 'status', 'failed'));
  end loop;

  for job in
    select id from public.ai_jobs
     where (status = 'queued' and updated_at < now() - interval '1 minute')
        or (status = 'running' and heartbeat_at < now() - private.ai_job_stale_after())
     limit 20
  loop
    perform private.call_edge_function('run-ai-job', jsonb_build_object('jobId', job.id));
  end loop;
end $$;
revoke all on function private.sweep_ai_jobs() from public, anon, authenticated;

select cron.schedule('sweep-ai-jobs', '* * * * *', $$select private.sweep_ai_jobs()$$);

alter publication supabase_realtime add table public.ai_jobs;
