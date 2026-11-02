begin;
select plan(24);

-- Helpers (rolled back with the test).
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
create function pg_temp.as_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  set local role anon;
end $$;
grant execute on all functions in schema pg_temp to public;

create temp table ids (name text primary key, id uuid);
grant all on ids to public;
insert into ids values ('ann', pg_temp.mkuser('ann')), ('bob', pg_temp.mkuser('bob')),
  ('cat', pg_temp.mkuser('cat')), ('dan', pg_temp.mkuser('dan'));
create function pg_temp.u(n text) returns uuid language sql as $$ select id from ids where name = n $$;
grant execute on function pg_temp.u(text) to public;

-- A new account gets a profile and a private record.
select is((select count(*) from public.profiles where id = pg_temp.u('ann'))::int, 1, 'signup creates a profile');
select is((select count(*) from public.private_account where id = pg_temp.u('ann'))::int, 1, 'signup creates a private account');

-- Profiles.
select pg_temp.as_user(pg_temp.u('ann'));
select lives_ok($$update public.profiles set username = 'ann_style', display_name = 'Ann' where id = pg_temp.u('ann')$$, 'owner edits own profile');
select throws_ok($$update public.profiles set is_admin = true where id = pg_temp.u('ann')$$, null, null, 'cannot make self admin');
select throws_ok($$update public.profiles set shop_verified = true where id = pg_temp.u('ann')$$, null, null, 'cannot self-verify');
select throws_ok($$update public.profiles set username = 'admin' where id = pg_temp.u('ann')$$, null, null, 'reserved username refused');
select is((select count(*) from public.profiles where id = pg_temp.u('bob'))::int, 1, 'signed-in users can read other profiles');
select is((select count(*) from public.private_account where id = pg_temp.u('bob'))::int, 0, 'private account of others is invisible');
select pg_temp.as_user(pg_temp.u('bob'));
select throws_ok($$update public.profiles set username = 'ann_style' where id = pg_temp.u('bob')$$, null, null, 'usernames are unique');
select is((select count(*) from public.profiles where id = pg_temp.u('ann') and display_name = 'Ann')::int, 1, 'bob sees ann profile');
update public.profiles set display_name = 'Hacked' where id = pg_temp.u('ann');
reset role;
select is((select display_name from public.profiles where id = pg_temp.u('ann')), 'Ann', 'bob cannot edit ann');

-- Follows: bob follows ann; cat does not.
select pg_temp.as_user(pg_temp.u('bob'));
insert into public.follows (follower_id, followee_id) values (pg_temp.u('bob'), pg_temp.u('ann'));
select throws_ok($$insert into public.follows (follower_id, followee_id) values (pg_temp.u('cat'), pg_temp.u('ann'))$$, null, null, 'cannot follow as someone else');

-- Posts by ann with each visibility.
select pg_temp.as_user(pg_temp.u('ann'));
insert into public.posts (id, author_id, visibility, caption) values
  ('00000000-0000-0000-0000-0000000000a1', pg_temp.u('ann'), 'public', 'pub'),
  ('00000000-0000-0000-0000-0000000000a2', pg_temp.u('ann'), 'followers', 'fol'),
  ('00000000-0000-0000-0000-0000000000a3', pg_temp.u('ann'), 'friends', 'fri'),
  ('00000000-0000-0000-0000-0000000000a4', pg_temp.u('ann'), 'private', 'pri');
select is((select count(*) from public.posts)::int, 4, 'author sees all her posts');
select throws_ok($$insert into public.posts (author_id) values (pg_temp.u('bob'))$$, null, null, 'cannot post as someone else');

select pg_temp.as_user(pg_temp.u('bob'));
select is((select count(*) from public.posts)::int, 2, 'follower sees public + followers posts (not friends/private)');
insert into public.follows (follower_id, followee_id) values (pg_temp.u('ann'), pg_temp.u('bob')) ;
select pg_temp.as_user(pg_temp.u('cat'));
select is((select count(*) from public.posts)::int, 1, 'stranger sees only public');
select pg_temp.as_anon();
select is((select count(*) from public.posts)::int, 0, 'signed-out sees no posts');

-- Comments are as private as the look.
select pg_temp.as_user(pg_temp.u('ann'));
insert into public.comments (target_type, target_id, author_id, text)
  values ('post', '00000000-0000-0000-0000-0000000000a4', pg_temp.u('ann'), 'note to self');
select pg_temp.as_user(pg_temp.u('bob'));
select is((select count(*) from public.comments)::int, 0, 'comments on a private look are hidden');

-- Affirmations.
select throws_ok($$insert into public.affirmations (id, sender_id, target_id, target_owner_id) values ('x1', pg_temp.u('bob'), 'p', pg_temp.u('bob'))$$, null, null, 'cannot affirm own look');
select lives_ok($$insert into public.affirmations (id, sender_id, target_id, target_owner_id) values ('x2', pg_temp.u('bob'), 'p', pg_temp.u('ann'))$$, 'can affirm another look');

-- Notifications: only the recipient reads.
insert into public.notifications (user_id, sender_id, title) values (pg_temp.u('ann'), pg_temp.u('bob'), 'hi');
select is((select count(*) from public.notifications)::int, 0, 'sender cannot read the notification they sent');

select * from finish();
rollback;
