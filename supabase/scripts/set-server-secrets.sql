-- Run once per Supabase project, in the SQL editor (Dashboard → SQL Editor).
-- Lets the database call the Edge Functions (pushes, feed cards, trending,
-- fashion content). The service-role key is under Project Settings → API Keys;
-- never commit it or put it in the app.
select vault.create_secret('https://dararqifsiuvrmfjleui.supabase.co', 'edge_base_url');
select vault.create_secret('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhcmFycWlmc2l1dnJtZmpsZXVpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzU5NDE4OSwiZXhwIjoyMTA5MTcwMTg5fQ.Wx0ml3uaC78HXJh2V4aVSnhjcxtxLsRudCIeeIh-_W4', 'edge_service_key');
