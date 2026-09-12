# SNIP Authentication

## Provider

Supabase Auth (email/password). Architecture leaves room for Google/Apple OAuth later without changing profile/role model.

## Profile bootstrap

Trigger `on_auth_user_created` → `handle_new_user()`:

1. Reads `raw_user_meta_data.role` (optional).
2. Allows only `customer` or `salon_owner` from public signup.
3. Inserts into `profiles` with name/email/phone.

## Default roles

| Flow | Role |
|------|------|
| Customer register | `customer` |
| “List your salon” / owner register | `salon_owner` |
| Staff invite acceptance | `barber` |
| Platform operator | `admin` (SQL only) |

**Never** create admin via public UI.

## Creating a demo admin

```sql
-- After the user has signed up once as customer/owner:
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'admin@yourdomain.com';
```

## Session handling

### Web
- Cookie session via `@supabase/ssr`
- `proxy.ts` refreshes session and redirects unauthenticated users away from protected trees
- Layouts call `requireRole(...)` / profile helpers for server-side enforcement

### Mobile
- `supabase_flutter` persists session
- GoRouter redirect reads auth + profile role
- Secure storage available for sensitive local needs

## Barber invitation (MVP pattern)

1. Owner creates barber row (+ optional `salon_members` invite email/token).
2. Email sent via Resend with setup link.
3. Invitee signs up / logs in; owner or server links `barbers.profile_id` and sets role to `barber`.

## Password flows

Supported: email verification (Supabase setting), forgot password, reset password. Redirect URLs must include local and production app origins.

## Demo accounts (seed)

1. Sign up four users in Auth.
2. Copy their UUIDs into `supabase/seed.sql` placeholders.
3. Set one profile to `admin` manually.
4. Run seed for salons/services/bookings.
