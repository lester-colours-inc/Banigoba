# Service-provider mode: plan for approval

Covers checklist items S-1 to S-4. Nothing is built yet.

## What the meeting asked for

Any user can switch between **Customer** and **Service provider**, like
passenger and driver in InDrive. One person can be a customer *and* a shop, a
designer or a salon. Shops sign up as normal users; there is no separate
business sign-up.

## What exists today

| Role | How you become one today | What you get |
|---|---|---|
| Shop | Settings › "Seller Mode" switch | The **whole app turns into** the boutique dashboard (products, orders). Admin-verified. |
| Salon / hair agent | Agents page › register | Profile, verification, chat. No "mode". |
| Designer | Designers page › portfolio | Portfolio, verification, chat. No "mode". |

Problems: three different doors; Seller Mode *replaces* the customer app
instead of switching beside it; one person can't comfortably be both; nothing
tells a customer which providers exist as "my" shop.

## Proposal

1. **One door.** Settings gets **"Switch to provider mode"**. First time, a
   short form asks what you offer (tick any of: Shop, Designer, Hair salon),
   a business name, and a location. Pre-existing shops, designers and agents
   are carried over automatically; nobody re-registers.
2. **A visible switch, not a different app.** A "Customer ⇄ Provider" toggle
   at the top of the menu. Provider mode shows a provider home with a card per
   role you hold (My Shop, My Designs, My Salon), each opening the screen that
   already exists, plus **Orders** and **Messages** across all roles. The
   customer app stays one tap away; no sign-out.
3. **Verification stays.** Curators still verify each role; unverified
   providers can set up but don't appear in Send to or the directories.
4. **Data.** Keep the current `shop`, `designerProfile`, `agentProfile`
   sections on the user record (rules already protect their `verified`
   flags). Add one field, `providerRoles: ['shop','designer','salon']`, and
   `providerMode: true/false` for which side the user last used.

## Build steps (each shippable on its own)

1. Provider home screen + the Customer/Provider toggle; keep Seller Mode
   working underneath. (~1 day)
2. Unified "Become a provider" form that creates any of the three profiles
   and migrates existing ones. (~1 day)
3. Provider-wide Orders and Messages views. (~1 day)
4. Retire the old Seller Mode switch and the separate registration entry
   points. (~half day)

Tests: role-combination logic (unit), the toggle and provider home (widget),
rule tests for the new fields.

## Decisions I need from you

1. **Seller Mode today replaces the app.** Is the new "toggle that keeps the
   customer app available" what you want? (Recommended: yes.)
2. **Can unverified providers be seen at all?** Recommended: set up yes,
   listed publicly only after a curator verifies.
3. **Naming:** "Provider mode" vs "Business mode" vs "Seller mode" for
   shops, designers and salons together.
4. **Marketplace dependency:** build only steps 1-2 now (the switch and
   sign-up), leaving Orders for the marketplace work? (Recommended: yes.)
