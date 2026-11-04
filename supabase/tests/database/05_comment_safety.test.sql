begin;
select plan(9);

create function pg_temp.mkuser(n text) returns uuid language plpgsql as $$
declare u uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, aud, role, instance_id)
  values (u, n || '@test.dev', 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');
  return u;
end $$;
create function pg_temp.as_user(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  set local role authenticated;
end $$;
grant execute on all functions in schema pg_temp to public;
create temp table ids (name text primary key, id uuid);
grant all on ids to public;
insert into ids values ('owner', pg_temp.mkuser('owner')), ('a', pg_temp.mkuser('a')),
  ('b', pg_temp.mkuser('b')), ('c', pg_temp.mkuser('c')), ('d', pg_temp.mkuser('d'));
create function pg_temp.u(n text) returns uuid language sql as $$ select id from ids where name = n $$;
grant execute on function pg_temp.u(text) to public;

insert into public.posts (id, author_id, visibility) values
  ('00000000-0000-0000-0000-0000000000e1', pg_temp.u('owner'), 'public');
insert into public.comments (id, target_type, target_id, author_id, text) values
  ('00000000-0000-0000-0000-0000000000f1', 'post', '00000000-0000-0000-0000-0000000000e1', pg_temp.u('a'), 'Lovely look');

-- Limits hold whatever sends the text.
select pg_temp.as_user(pg_temp.u('b'));
select throws_ok($$insert into public.comments (target_type, target_id, author_id, text) values ('post', '00000000-0000-0000-0000-0000000000e1', pg_temp.u('b'), repeat('x', 501))$$, null, null, 'a very long comment is refused');
select throws_ok($$insert into public.comments (target_type, target_id, author_id, text) values ('post', '00000000-0000-0000-0000-0000000000e1', pg_temp.u('b'), '')$$, null, null, 'an empty comment is refused');

-- Reports: three different people hide it from others.
insert into public.comment_reports (comment_id, reporter_id) values ('00000000-0000-0000-0000-0000000000f1', pg_temp.u('b'));
select pg_temp.as_user(pg_temp.u('c'));
insert into public.comment_reports (comment_id, reporter_id) values ('00000000-0000-0000-0000-0000000000f1', pg_temp.u('c'));
select is((select count(*) from public.comments)::int, 1, 'two reports do not hide a comment');
select pg_temp.as_user(pg_temp.u('d'));
insert into public.comment_reports (comment_id, reporter_id) values ('00000000-0000-0000-0000-0000000000f1', pg_temp.u('d'));
select is((select count(*) from public.comments)::int, 0, 'three reports hide it from other people');
select throws_ok($$insert into public.comment_reports (comment_id, reporter_id) values ('00000000-0000-0000-0000-0000000000f1', pg_temp.u('a'))$$, null, null, 'nobody can report as someone else');

-- Still visible to its author and the look's owner.
select pg_temp.as_user(pg_temp.u('a'));
select is((select count(*) from public.comments)::int, 1, 'the author still sees it');
select pg_temp.as_user(pg_temp.u('owner'));
select is((select count(*) from public.comments)::int, 1, 'the look''s owner still sees it');

-- The look's owner can remove it; a stranger cannot.
select pg_temp.as_user(pg_temp.u('b'));
delete from public.comments where id = '00000000-0000-0000-0000-0000000000f1';
reset role;
select is((select count(*) from public.comments)::int, 1, 'a stranger cannot remove a comment');
select pg_temp.as_user(pg_temp.u('owner'));
delete from public.comments where id = '00000000-0000-0000-0000-0000000000f1';
reset role;
select is((select count(*) from public.comments)::int, 0, 'the look''s owner can remove it');

select * from finish();
rollback;
