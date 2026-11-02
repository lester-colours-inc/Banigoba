-- Community events are reviewed by curators before everyone sees them.
alter table public.events
  add column status text not null default 'pending'
    check (status in ('pending', 'approved', 'disapproved')),
  add column location text not null default '',
  add column price text not null default '',
  add column phone_number text not null default '',
  add column whatsapp_number text not null default '',
  add column booking_link text not null default '',
  add column amenities text[] not null default '{}',
  add column submitted_by_name text not null default '',
  add column reviewed_by uuid references public.profiles (id) on delete set null,
  add column reviewed_at timestamptz,
  add column updated_at timestamptz not null default now();
create index events_status on public.events (status, starts_at);
create trigger events_touch before update on public.events
  for each row execute function public.touch_updated_at();
alter table public.events replica identity full;

-- Everyone sees approved events; people see their own; curators see all.
drop policy events_read on public.events;
create policy events_read on public.events for select to authenticated
  using (status = 'approved' or submitted_by = auth.uid() or public.is_admin());

-- New events always start pending; an edit by the owner sends it back for
-- review; only a curator can approve or disapprove.
create or replace function public.guard_event_review()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_server() or public.is_admin() then return new; end if;
  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.reviewed_by := null;
    new.reviewed_at := null;
  else
    new.status := 'pending';
    new.reviewed_by := old.reviewed_by;
    new.reviewed_at := old.reviewed_at;
    new.submitted_by := old.submitted_by;
  end if;
  return new;
end $$;
create trigger events_review_guard before insert or update on public.events
  for each row execute function public.guard_event_review();

create policy events_admin_update on public.events for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy events_admin_delete on public.events for delete to authenticated
  using (public.is_admin());
