-- Keeping comments kind (C-3), the server's half. The app refuses unkind text
-- before it is sent; here the database holds the limits whatever sends it, lets
-- the owner of a look remove comments on it, and lets anyone report a comment.
-- Three different people reporting a comment hides it from everyone but its
-- author, the look's owner and curators until a curator looks.

alter table public.comments
  add constraint comments_text_length check (char_length(text) between 1 and 500),
  add column hidden boolean not null default false;
alter table public.affirmations
  add constraint affirmations_note_length check (char_length(personal_message) <= 140);

-- Who can see a comment: as before, plus not hidden unless it is yours, it is
-- on your look, or you are a curator.
create or replace function public.comment_target_owner(kind text, target text)
returns uuid language sql stable security definer set search_path = public as $$
  select case kind
    when 'post' then (select author_id from public.posts where id::text = target)
    when 'hairLook' then (select user_id from public.hair_looks where id::text = target)
  end
$$;
revoke execute on function public.comment_target_owner(text, text) from public, anon;

drop policy comments_read on public.comments;
create policy comments_read on public.comments for select to authenticated using (
  public.can_read_comment_target(target_type, target_id)
  and (
    not hidden
    or author_id = auth.uid()
    or public.comment_target_owner(target_type, target_id) = auth.uid()
    or public.is_admin()
  )
);

-- The owner of a look can remove comments on it.
create policy comments_delete_by_look_owner on public.comments
  for delete to authenticated
  using (public.comment_target_owner(target_type, target_id) = auth.uid());

create table public.comment_reports (
  comment_id uuid not null references public.comments (id) on delete cascade,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null default '' check (char_length(reason) <= 200),
  created_at timestamptz not null default now(),
  primary key (comment_id, reporter_id)
);
alter table public.comment_reports enable row level security;
create policy comment_reports_create on public.comment_reports
  for insert to authenticated with check (reporter_id = auth.uid());
create policy comment_reports_read on public.comment_reports
  for select to authenticated using (reporter_id = auth.uid() or public.is_admin());

create or replace function private.hide_reported_comment()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.comment_reports where comment_id = new.comment_id) >= 3 then
    update public.comments set hidden = true where id = new.comment_id;
  end if;
  return new;
end $$;
create trigger comment_reports_hide after insert on public.comment_reports
  for each row execute function private.hide_reported_comment();

-- A curator can clear or remove a reported comment.
create policy comments_admin_update on public.comments
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy comments_admin_delete on public.comments
  for delete to authenticated using (public.is_admin());
