# SNIP

**Smart Salon Booking & Management System**  
Tagline: **BOOK • MANAGE • GROW**

SNIP connects customers, salon owners, barbers/stylists, and platform admins in one cohesive ecosystem — replacing phone/WhatsApp bookings, paper appointment books, and manual staff assignment with a secure, conflict-aware booking engine and QR check-in.

---

## Tech stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter + Riverpod + GoRouter + Supabase Flutter |
| Web | Next.js (App Router) + TypeScript + Tailwind CSS |
| Backend | Supabase (PostgreSQL, Auth, Storage, RLS, Realtime, Edge Functions) |
| Email | Resend (server-side only) |
| Hosting (web) | Vercel |

There are **exactly two** user-facing apps:

- `apps/mobile` — Flutter (customer, salon owner, barber)
- `apps/web` — Next.js (public site + customer/owner/barber/admin)

---

## Repository structure

```
SNIP
├── apps
│   ├── mobile       → Flutter
│   └── web          → Next.js
├── supabase
│   ├── migrations
│   ├── functions
│   ├── config.toml
│   └── seed.sql
├── docs
├── README.md
├── .env.example
└── .gitignore
```

---

## Requirements

- Node.js 20+ and npm
- Flutter 3.22+ / Dart 3.4+
- Supabase CLI (optional for local stack)
- A Supabase project
- A Resend account (for transactional email)

---

## Environment configuration

1. Copy the example env file:

```bash
cp .env.example apps/web/.env.local
```

2. Fill in values from your Supabase project settings:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
RESEND_API_KEY=re_xxxxxxxx
RESEND_FROM_EMAIL=SNIP <bookings@yourdomain.com>
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

**Never commit secrets.** Never expose `SUPABASE_SERVICE_ROLE_KEY` or `RESEND_API_KEY` to Flutter or client-side Next.js.

Flutter uses public Supabase config via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

---

## Supabase setup

### Apply migrations

From the repo root (with [Supabase CLI](https://supabase.com/docs/guides/cli) linked to your project):

```bash
supabase db push
# or locally:
supabase start
supabase db reset   # applies migrations + seed.sql
```

You can also paste `supabase/migrations/20260312000001_initial_schema.sql` into the SQL editor for a fresh project.

### Seed data

`supabase/seed.sql` creates demo salons, services, barbers, and schedules **after** demo auth users/profiles exist.

1. Create Auth users in the dashboard (or via signup) for customer, owner, barber, and (manually) admin.
2. Update the UUID placeholders in `seed.sql` to match `auth.users` / `profiles.id`.
3. Promote an admin by updating `profiles.role = 'admin'` in SQL (never via public signup).
4. Run `supabase db reset` or execute `seed.sql`.

See [docs/authentication.md](docs/authentication.md).

### Storage buckets

Migration creates:

- `avatars`
- `salon-images`
- `service-images`
- `barber-portfolios`

---

## Next.js (web)

```bash
cd apps/web
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

Useful scripts:

```bash
npm run lint
npm run typecheck
npm run build
```

### Key routes

| Path | Audience |
|------|----------|
| `/` | Public landing |
| `/explore` | Salon discovery |
| `/salons/[slug]` | Salon details |
| `/login`, `/register` | Auth |
| `/customer/*` | Customer |
| `/owner/*` | Salon owner |
| `/barber/*` | Barber |
| `/admin/*` | Platform admin |

Role redirects after login: customer → `/customer`, salon_owner → `/owner`, barber → `/barber`, admin → `/admin`.

---

## Flutter (mobile)

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

After login, the app loads `profiles.role` and routes to:

- `customer` → Customer Home
- `salon_owner` → Owner Dashboard
- `barber` → Barber Dashboard

Admin users should use the web admin panel.

### Mobile build

```bash
# Android
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# iOS (macOS)
flutter build ios --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Camera permission is required for QR scanning.

---

## Resend setup

1. Create an API key in Resend.
2. Set `RESEND_API_KEY` and `RESEND_FROM_EMAIL` in `apps/web/.env.local`.
3. Emails are sent from Next.js API routes / server code (and optionally Supabase Edge Functions under `supabase/functions`).

Templates include welcome, booking confirmation/cancellation, salon verification outcomes, and staff invitations.

---

## Vercel deployment

1. Import the monorepo into Vercel.
2. Set **Root Directory** to `apps/web`.
3. Add the same environment variables as `.env.example`.
4. Deploy.

Production Supabase: point env vars at your production project and ensure Auth redirect URLs include your Vercel domain.

---

## Documentation

- [Architecture](docs/architecture.md)
- [Database](docs/database.md)
- [Authentication](docs/authentication.md)
- [Booking engine](docs/booking-engine.md)
- [Deployment](docs/deployment.md)

---

## Security principles

- Role checks in UI **and** Next.js server **and** Postgres RLS
- Booking conflicts enforced with `EXCLUDE` constraints + RPC validation
- Service role and Resend keys stay server-only
- Admin accounts are never creatable via public signup

---

## License

Private / proprietary unless otherwise stated.
