# SNIP Database

## Enums

| Enum | Values |
|------|--------|
| `user_role` | customer, salon_owner, barber, admin |
| `salon_verification_status` | draft, pending_verification, verified, rejected, suspended |
| `booking_status` | pending, confirmed, checked_in, in_progress, completed, cancelled, no_show |
| `service_category` | hair, beard, nails, facial, massage, color, other |
| `notification_type` | booking_*, salon_*, staff_invitation, system, … |
| `verification_decision` | submitted, approved, rejected, changes_requested |
| `day_of_week` | monday … sunday |

## Core tables

### profiles
Extends `auth.users` (`id` PK = auth user). Role, name, email, phone, avatar, `is_active`.

### salons
Owned by `owner_id`. Unique `slug`, geo fields, images, `verification_status`, `opening_hours` JSONB.

### salon_members
Future-ready multi-salon membership (owner/barber) with invitation fields.

### services
Salon services: category, price, `duration_minutes`, active flag.

### barbers
Staff profiles linked optionally to `profiles`. Specializations array.

### barber_services
Many-to-many barber ↔ service.

### barber_schedules / barber_breaks / barber_time_off
Relational working hours, recurring breaks, absences.

### bookings
Customer appointment with start/end, price, status, `qr_token`, walk-in flag.  
**Exclusion constraint** prevents overlapping active bookings per barber.

### booking_status_history
Audit trail of status changes.

### salon_gallery / barber_portfolio
Media assets.

### favorites / notifications / salon_verification_requests
Customer favorites, in-app notifications, verification audit.

## Relationships (simplified)

```
profiles 1──* salons (owner)
salons 1──* services
salons 1──* barbers
barbers *──* services (barber_services)
profiles 1──* bookings (customer)
salons / services / barbers ──→ bookings
```

## Indexes

Indexed on common filters: `bookings(customer_id|salon_id|barber_id|appointment_start|status)`, `services(salon_id)`, `barbers(salon_id)`, `salons(city|verification_status)`, `notifications(user_id, is_read)`, etc.

## RLS summary

| Role | Capabilities |
|------|----------------|
| Customer | Read verified public data; manage own profile, bookings, favorites |
| Salon owner | Full CRUD on own salon, services, staff, schedules; manage own bookings |
| Barber | Read assigned bookings; allowed status transitions; own portfolio |
| Admin | Broad read/manage via `is_admin()`; prefer server-side for sensitive ops |

Helper functions: `current_user_role()`, `is_admin()`, `owns_salon()`, `is_salon_staff()`, `is_barber_of_booking()`.

## Key RPCs

| Function | Purpose |
|----------|---------|
| `search_salons` | Paginated salon search |
| `get_available_slots` | Slot generation |
| `create_booking` | Atomic booking create |
| `transition_booking_status` | Validated status changes |
| `check_in_with_qr` | QR check-in |

## Storage

Buckets: `avatars`, `salon-images`, `service-images`, `barber-portfolios` with MIME/size limits and policies.

## Migrations

Single initial migration:

`supabase/migrations/20260312000001_initial_schema.sql`

Seed: `supabase/seed.sql` (requires real auth user UUIDs).
