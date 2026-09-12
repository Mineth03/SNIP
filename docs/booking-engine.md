# SNIP Booking Engine

## Goals

- Generate only bookable slots
- Prevent double-booking even under concurrent requests
- Drive a strict status lifecycle
- Issue opaque QR tickets for check-in

## Availability inputs

`get_available_slots(salon_id, service_id, barber_id?, date, interval, buffer)` considers:

1. Service duration and salon ownership of the service  
2. Active barbers (optionally filtered; “any barber” = `barber_id` null)  
3. Barber ↔ service assignment (if any assignments exist)  
4. Working schedule for that weekday  
5. Breaks overlapping the candidate slot  
6. Time-off ranges  
7. Existing bookings in `pending|confirmed|checked_in|in_progress`  
8. Optional buffer minutes  
9. Slots must start in the future  

Returns `(barber_id, barber_name, slot_start, slot_end)`.

## Creating a booking

`create_booking(...)`:

1. Resolves customer (self, or walk-in by staff)  
2. Validates salon/service availability  
3. Re-queries available slots for the exact start time  
4. Picks specific barber or first available (“any”)  
5. Inserts booking with computed end + service price  
6. Creates customer notification  

On exclusion violation (concurrent book), raises a friendly conflict error.

## Race-condition protection

Active bookings for a barber cannot overlap:

```sql
EXCLUDE USING gist (
  barber_id WITH =,
  tstzrange(appointment_start, appointment_end, '[)') WITH &&
) WHERE (status IN ('pending','confirmed','checked_in','in_progress'))
```

Frontend validation is UX only; the database is the source of truth.

## Status lifecycle

Allowed transitions (`is_valid_booking_transition`):

```
pending     → confirmed | cancelled
confirmed   → checked_in | cancelled | no_show
checked_in  → in_progress | cancelled | no_show
in_progress → completed | cancelled
```

`transition_booking_status` enforces transition rules + permissions and writes history + notification.

## QR lifecycle

| Step | Status | Actor |
|------|--------|-------|
| Book | `confirmed` + `qr_token` | Customer / walk-in |
| Show ticket | QR encodes token only | Customer |
| Scan | `check_in_with_qr` → `checked_in` | Owner / assigned barber |
| Start | `in_progress` | Owner / barber |
| Finish | `completed` | Owner / barber |

Errors: invalid token, already processed, cancelled, wrong status, unauthorized scanner.

## Client integration

- Web: `/api/bookings/slots`, `/api/bookings/create`, `/api/bookings/check-in`
- Mobile: repository RPCs `get_available_slots`, `create_booking`, `check_in_with_qr`, `transition_booking_status`

Always show service, duration, price, date, time, and barber on the review step before confirm.
