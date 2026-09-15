# SNIP Authentication

## Provider

Supabase Auth (email/password). Architecture leaves room for Google/Apple OAuth later without changing the capability model.

## Profile bootstrap

Trigger `on_auth_user_created` → `handle_new_user()`:

1. Always creates a **customer** profile (`role` + `active_role = customer`).
2. Reads name/email/phone from `raw_user_meta_data`.
3. Public signup never chooses owner or barber.

## Capabilities vs active role

Authorization is **membership-based**, not a single exclusive `profiles.role`:

| Capability | Source of truth |
|------------|-----------------|
| Customer | Always for authenticated users |
| Owner | `salons.owner_id = auth.uid()` |
| Barber | One or more active `barbers` rows with `profile_id = auth.uid()` (+ `salon_members`) |
| Admin | `profiles.role = admin` (SQL only) |

UI shell preference:

- `profiles.active_role` — which app shell to open (customer / owner / barber)
- `profiles.active_barber_salon_id` — which salon the barber shell is scoped to

Helpers / RPCs: `user_capabilities()`, `set_active_role()`, `set_active_barber_salon()`, `become_salon_owner()`, `invite_barber_to_salon()`, `accept_barber_invite()`, `resign_from_salon()`, `remove_barber_from_salon()`.

## Default flows

| Flow | Result |
|------|--------|
| Register (web/mobile) | Always customer → customer home |
| Profile → “Become a salon owner” | Creates salon, unlocks owner hat, sets `active_role = salon_owner` |
| Owner invites barber by email | Pending `salon_members` + staff row; accept via `/invite/barber?token=…` |
| Accept invite | Links `barbers.profile_id`, sets `active_role = barber`, may set `active_barber_salon_id` |
| Barber resign / owner remove | Deactivates that salon’s membership only; other hats/salons stay |
| Profile role switcher | Switches `active_role` among available capabilities |

**Never** create admin via public UI.

## Creating a demo admin

```sql
-- After the user has signed up once as customer:
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'admin@yourdomain.com';
```

## Session handling

### Web
- Cookie session via `@supabase/ssr`
- Middleware refreshes session and enforces capability-aware path access
- Layouts call `requireRole(...)` / capability helpers for server-side enforcement
- Login / reset password redirect using `active_role` when still valid

### Mobile
- `supabase_flutter` persists session
- GoRouter redirect uses capabilities + `effectiveActiveRole`
- Invite deep link: `/invite/barber?token=…`

## Barber invitation

1. Owner calls `invite_barber_to_salon(salon_id, email, display_name?)`.
2. Share `/invite/barber?token=…` (email via Resend on web when configured).
3. Invitee signs up/logs in as customer if needed, then accepts → multi-salon memberships allowed.

Barbers can hold multiple salon jobs, switch active salon, resign from one, and accept another invite later.

## Password flows

Supported: email verification (Supabase setting), forgot password, reset password. Redirect URLs must include local and production app origins.

## Demo accounts (seed)

1. Sign up users in Auth (all as customers).
2. Copy UUIDs into `supabase/seed.sql` placeholders.
3. Seed salons/services/bookings; link barbers via `profile_id` / memberships.
4. Set one profile to `admin` manually if needed.
5. Apply migration `20260314000001_multi_role_barbers.sql` for multi-role columns and RPCs.
