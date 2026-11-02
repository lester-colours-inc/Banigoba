-- Run once per Supabase project, in the SQL editor (Dashboard → SQL Editor).
-- Lets the database call the Edge Functions (pushes, feed cards, trending,
-- fashion content). The service-role key is under Project Settings → API Keys;
-- never commit it or put it in the app.
select vault.create_secret('https://dararqifsiuvrmfjleui.supabase.co', 'edge_base_url');
select vault.create_secret('PASTE-THE-SERVICE-ROLE-KEY-HERE', 'edge_service_key');
