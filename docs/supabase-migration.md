# Banigoba on Supabase

The app now runs on Supabase (project `dararqifsiuvrmfjleui`). Firebase
(project `banigoba-bbfe8`) is kept for push notifications only.

## Layout

| What | Where |
|---|---|
| Database, security rules (RLS), checkout (`place_order`), storage buckets | `supabase/migrations/` |
| Database security tests (pgTAP) | `supabase/tests/database/` — `supabase test db` |
| Edge Functions | `supabase/functions/` |
| Matching/trending/content rules and their tests | `supabase/functions/_shared/` — `npm test` there |
| App settings | `dart_defines.json` (see `dart_defines.example.json`) |

Run the app with `--dart-define-from-file=dart_defines.json`.

## One-time setup per environment

1. **Server secrets** — run `supabase/scripts/set-server-secrets.sql` in the SQL
   editor so the database can call the Edge Functions.
2. **Push** — `supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"`
   with the Firebase service-account key for `banigoba-bbfe8`.
3. **Sign-in providers** — Dashboard → Authentication → Providers: enable
   Google (web client ID + secret) and Facebook (app ID + secret), and add
   `com.coloursinc.banigoba://login-callback` and the web URL to the redirect
   list.

## Server jobs

| Job | How it runs |
|---|---|
| Push for each notification | trigger on `notifications` → `send-push` |
| Daily feed cards for new stock | trigger on `products` → `match-new-stock` |
| Trending looks | pg_cron, 16:00 UTC → `notify-trending` |
| Fashion news and events | pg_cron, every 3 hours → `refresh-content` |
| Shared-stock announcements | SQL trigger on `shop_links` |
| AI makeover | `generate-makeover` (placeholder, called by the app) |
