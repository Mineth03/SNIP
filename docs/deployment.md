# SNIP Deployment

## Supabase (production)

1. Create a Supabase project.
2. Run migrations (`supabase db push` or SQL editor).
3. Configure Auth URL allow-list (Vercel domain + mobile deep links if any).
4. Enable email confirmations as required.
5. Create storage buckets if not created by migration.
6. Seed only non-production projects.

## Web (Vercel)

1. Import Git repository.
2. Root directory: `apps/web`.
3. Framework preset: Next.js.
4. Environment variables from `.env.example` (production values).
5. Deploy.

Post-deploy checklist:

- [ ] Login / register works  
- [ ] Role redirects correct  
- [ ] Explore lists verified salons  
- [ ] Booking create + conflict behavior  
- [ ] Admin verification emails (Resend domain verified)  

## Mobile

Build with production public keys only:

```bash
cd apps/mobile
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Distribute via Play Store / TestFlight. Camera permission required for QR.

## Edge Functions (optional)

`supabase/functions/send-email` can proxy Resend when you prefer emails closer to the database. Set secrets:

```bash
supabase secrets set RESEND_API_KEY=re_xxx RESEND_FROM_EMAIL="SNIP <bookings@domain.com>"
```

Primary MVP path uses Next.js `lib/email` + `/api/emails`.

## Security checklist

- [ ] Service role key only on server / CI secrets  
- [ ] RLS enabled on all public tables  
- [ ] No admin self-signup  
- [ ] Resend key server-only  
- [ ] Storage MIME/size limits active  
