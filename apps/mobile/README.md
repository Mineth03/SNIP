# SNIP Mobile (Flutter)

Role-aware Flutter app for **customers**, **salon owners**, and **barbers**.

## Setup

```bash
cd apps/mobile
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

## Architecture

See root [README](../../README.md) and [docs/architecture.md](../../docs/architecture.md).

Feature folders live under `lib/features/` with shared widgets in `lib/shared/widgets/` and theme tokens in `lib/theme/`.

## Roles

| Role | Entry |
|------|-------|
| customer | `/customer/home` |
| salon_owner | `/owner/dashboard` |
| barber | `/barber/dashboard` |

Admins should use the web admin panel.
