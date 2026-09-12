# SNIP Web (Next.js)

Public website + customer / owner / barber / admin dashboards.

## Setup

```bash
cd apps/web
cp ../../.env.example .env.local
# fill Supabase + Resend values
npm install
npm run dev
```

## Scripts

| Command | Purpose |
|---------|---------|
| `npm run dev` | Local development |
| `npm run build` | Production build |
| `npm run typecheck` | TypeScript |
| `npm run lint` | ESLint |
| `npm run test` | Unit tests |

See root [README](../../README.md) for full setup.
