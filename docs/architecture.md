# SNIP Architecture

## Overview

SNIP is a monorepo with two clients sharing one Supabase backend.

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter Mobile │     │  Next.js Web    │
│  customer/owner │     │  public + all   │
│  /barber        │     │  roles + admin  │
└────────┬────────┘     └────────┬────────┘
         │  anon key             │  anon + server
         └──────────┬────────────┘
                    ▼
         ┌────────────────────┐
         │      Supabase      │
         │ Auth · Postgres    │
         │ RLS · Storage      │
         │ RPCs · Edge Fn     │
         └─────────┬──────────┘
                   ▼
              Resend email
              (server only)
```

## Flutter architecture

Feature-based modules under `apps/mobile/lib`:

| Layer | Responsibility |
|-------|----------------|
| `features/*` | Screens + Riverpod providers |
| `repositories/*` | Supabase data access |
| `models/*` | Typed domain models |
| `shared/widgets` | Design-system widgets |
| `theme/*` | Colors, typography, spacing |
| `routing/*` | GoRouter + auth/role guards |

State: **Riverpod**. Navigation: **GoRouter**. After session restore, profile role selects the shell (customer / owner / barber).

## Next.js architecture

App Router with route groups:

- `(public)` — landing, explore, salon pages
- `(auth)` — login/register/password
- `customer`, `owner`, `barber`, `admin` — role dashboards
- `api/*` — bookings, emails, admin verification

Supabase clients are separated:

| File | Use |
|------|-----|
| `lib/supabase/client.ts` | Browser |
| `lib/supabase/server.ts` | Server Components / Route Handlers |
| `lib/supabase/admin.ts` | Service-role (server-only) |

Session refresh and coarse route protection live in `proxy.ts` (Next.js 16). Fine-grained authorization is re-checked in layouts/pages and via RLS.

## Authentication & roles

Roles (`user_role` enum): `customer`, `salon_owner`, `barber`, `admin`.

- Signup metadata may set `customer` or `salon_owner` only (`handle_new_user` trigger).
- Barber accounts are created via owner invitation / staff linking.
- Admin is assigned manually in the database.

See [authentication.md](authentication.md).

## Booking engine

Availability and creation run in Postgres:

- `get_available_slots(...)` — schedules, breaks, time off, existing bookings
- `create_booking(...)` — re-validates slot, inserts booking, notifies
- `bookings_no_barber_overlap` — GiST exclusion constraint (race-safe)
- `transition_booking_status` / `check_in_with_qr` — controlled lifecycle

See [booking-engine.md](booking-engine.md).

## QR flow

1. Confirmed booking gets opaque `qr_token` (UUID).
2. Customer displays QR containing only the token.
3. Owner/barber scans → `check_in_with_qr` → `confirmed` → `checked_in`.
4. Further transitions: `in_progress` → `completed` (or cancel / no-show rules).

## Email (Resend)

Sent from Next.js server routes / `lib/email` (and optional Edge Functions). API key never ships to clients. Branding: SNIP · BOOK • MANAGE • GROW with teal/charcoal/white.

## Design system

Shared visual language from the SNIP brand kit:

- Primary teal `#1488A6` / `#14B8A6`
- Charcoal `#0F172A`
- Surfaces `#F8FAFC` / `#F3F4F6` / white
- Inter typography, 8px grid, 12–16px radii, soft shadows

Web: CSS variables in `globals.css` + shared components.  
Mobile: `SnipColors` / `SnipTheme` + shared widgets.

## Deployment

- Web → Vercel (`apps/web`)
- Mobile → APK/IPA with dart-defines
- Database → Supabase migrations

See [deployment.md](deployment.md).
