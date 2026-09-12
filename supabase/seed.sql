-- SNIP development seed data
-- NOTE: Auth users must be created via Supabase Auth (Dashboard or signup).
-- After creating demo auth users, update the UUIDs below to match.
-- See docs/authentication.md for the recommended demo account setup.

-- Placeholder profile IDs — replace with real auth.users IDs after signup:
-- customer: 00000000-0000-4000-8000-000000000001
-- owner:    00000000-0000-4000-8000-000000000002
-- barber:   00000000-0000-4000-8000-000000000003
-- admin:    00000000-0000-4000-8000-000000000004

-- This seed assumes demo profiles already exist. It is safe to re-run for salon/service data
-- when using fixed salon IDs.

DO $$
DECLARE
  v_owner_id UUID := '00000000-0000-4000-8000-000000000002';
  v_customer_id UUID := '00000000-0000-4000-8000-000000000001';
  v_barber_profile_id UUID := '00000000-0000-4000-8000-000000000003';
  v_salon1 UUID := '10000000-0000-4000-8000-000000000001';
  v_salon2 UUID := '10000000-0000-4000-8000-000000000002';
  v_salon3 UUID := '10000000-0000-4000-8000-000000000003';
  v_service1 UUID := '20000000-0000-4000-8000-000000000001';
  v_service2 UUID := '20000000-0000-4000-8000-000000000002';
  v_service3 UUID := '20000000-0000-4000-8000-000000000003';
  v_service4 UUID := '20000000-0000-4000-8000-000000000004';
  v_service5 UUID := '20000000-0000-4000-8000-000000000005';
  v_service6 UUID := '20000000-0000-4000-8000-000000000006';
  v_barber1 UUID := '30000000-0000-4000-8000-000000000001';
  v_barber2 UUID := '30000000-0000-4000-8000-000000000002';
  v_barber3 UUID := '30000000-0000-4000-8000-000000000003';
  v_barber4 UUID := '30000000-0000-4000-8000-000000000004';
BEGIN
  -- Only seed when demo owner profile exists
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_owner_id) THEN
    RAISE NOTICE 'Demo profiles not found. Create auth users first, then update UUIDs in seed.sql.';
    RETURN;
  END IF;

  INSERT INTO public.salons (
    id, owner_id, name, slug, description, email, phone, address, city,
    latitude, longitude, verification_status, is_active, opening_hours
  ) VALUES
  (
    v_salon1, v_owner_id, 'The Hair Lounge', 'the-hair-lounge',
    'Premium cuts, colour, and styling in the heart of Baner.',
    'hello@thehairlounge.demo', '+91 98765 43210',
    'Baner Road, Near Balewadi High Street', 'Pune',
    18.5590, 73.7868, 'verified', TRUE,
    '{"monday":{"open":"09:00","close":"19:00"},"tuesday":{"open":"09:00","close":"19:00"},"wednesday":{"open":"09:00","close":"19:00"},"thursday":{"open":"09:00","close":"19:00"},"friday":{"open":"09:00","close":"20:00"},"saturday":{"open":"10:00","close":"20:00"},"sunday":{"open":"10:00","close":"17:00"}}'::JSONB
  ),
  (
    v_salon2, v_owner_id, 'Urban Scissors', 'urban-scissors',
    'Modern barbershop experience with classic and contemporary styles.',
    'book@urbanscissors.demo', '+91 98765 43211',
    'Koregaon Park, Lane 7', 'Pune',
    18.5362, 73.8939, 'verified', TRUE,
    '{"monday":{"open":"10:00","close":"20:00"},"tuesday":{"open":"10:00","close":"20:00"},"wednesday":{"open":"10:00","close":"20:00"},"thursday":{"open":"10:00","close":"20:00"},"friday":{"open":"10:00","close":"21:00"},"saturday":{"open":"10:00","close":"21:00"},"sunday":{"closed":true}}'::JSONB
  ),
  (
    v_salon3, v_owner_id, 'Glow & Grace Spa', 'glow-grace-spa',
    'Facials, nails, and wellness treatments for complete self-care.',
    'care@glowgrace.demo', '+91 98765 43212',
    'Viman Nagar, Phoenix Road', 'Pune',
    18.5679, 73.9143, 'pending_verification', TRUE,
    '{"monday":{"open":"10:00","close":"19:00"},"tuesday":{"open":"10:00","close":"19:00"},"wednesday":{"open":"10:00","close":"19:00"},"thursday":{"open":"10:00","close":"19:00"},"friday":{"open":"10:00","close":"19:00"},"saturday":{"open":"10:00","close":"18:00"},"sunday":{"closed":true}}'::JSONB
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.services (id, salon_id, name, description, category, price, duration_minutes, is_active) VALUES
  (v_service1, v_salon1, 'Signature Haircut', 'Consultation, wash, cut, and style.', 'hair', 799.00, 45, TRUE),
  (v_service2, v_salon1, 'Beard Trim', 'Precision beard shaping and trim.', 'beard', 299.00, 20, TRUE),
  (v_service3, v_salon1, 'Hair Colour', 'Single-process colour with finish.', 'color', 2499.00, 120, TRUE),
  (v_service4, v_salon2, 'Classic Cut', 'Clean classic haircut.', 'hair', 499.00, 30, TRUE),
  (v_service5, v_salon2, 'Hot Towel Shave', 'Traditional hot towel shave.', 'beard', 599.00, 40, TRUE),
  (v_service6, v_salon3, 'Glow Facial', 'Deep cleansing facial treatment.', 'facial', 1299.00, 60, TRUE)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.barbers (id, salon_id, profile_id, display_name, bio, specializations, is_active) VALUES
  (v_barber1, v_salon1, v_barber_profile_id, 'Aarav Mehta', 'Senior stylist specializing in modern fades and colour.', ARRAY['fades', 'colour'], TRUE),
  (v_barber2, v_salon1, NULL, 'Priya Shah', 'Colour and bridal specialist.', ARRAY['colour', 'bridal'], TRUE),
  (v_barber3, v_salon2, NULL, 'Rohan Kapoor', 'Classic cuts and beard artistry.', ARRAY['classic', 'beard'], TRUE),
  (v_barber4, v_salon3, NULL, 'Neha Joshi', 'Facial and spa therapist.', ARRAY['facial', 'spa'], TRUE)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.barber_services (barber_id, service_id) VALUES
  (v_barber1, v_service1),
  (v_barber1, v_service2),
  (v_barber2, v_service1),
  (v_barber2, v_service3),
  (v_barber3, v_service4),
  (v_barber3, v_service5),
  (v_barber4, v_service6)
  ON CONFLICT DO NOTHING;

  -- Mon-Sat schedules
  INSERT INTO public.barber_schedules (barber_id, day_of_week, start_time, end_time, is_working)
  SELECT b.id, d.day, '09:00'::TIME, '18:00'::TIME, TRUE
  FROM (VALUES (v_barber1), (v_barber2), (v_barber3), (v_barber4)) AS b(id)
  CROSS JOIN (
    VALUES
      ('monday'::public.day_of_week),
      ('tuesday'::public.day_of_week),
      ('wednesday'::public.day_of_week),
      ('thursday'::public.day_of_week),
      ('friday'::public.day_of_week),
      ('saturday'::public.day_of_week)
  ) AS d(day)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.barber_breaks (barber_id, day_of_week, start_time, end_time)
  SELECT b.id, d.day, '13:00'::TIME, '14:00'::TIME
  FROM (VALUES (v_barber1), (v_barber2), (v_barber3), (v_barber4)) AS b(id)
  CROSS JOIN (
    VALUES
      ('monday'::public.day_of_week),
      ('tuesday'::public.day_of_week),
      ('wednesday'::public.day_of_week),
      ('thursday'::public.day_of_week),
      ('friday'::public.day_of_week),
      ('saturday'::public.day_of_week)
  ) AS d(day)
  ON CONFLICT DO NOTHING;

  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_customer_id) THEN
    INSERT INTO public.bookings (
      customer_id, salon_id, service_id, barber_id,
      appointment_start, appointment_end, price, status, customer_notes
    )
    SELECT
      v_customer_id, v_salon1, v_service1, v_barber1,
      date_trunc('day', NOW() + INTERVAL '1 day') + INTERVAL '11 hours',
      date_trunc('day', NOW() + INTERVAL '1 day') + INTERVAL '11 hours 45 minutes',
      799.00, 'confirmed', 'Please keep the sides short.'
    WHERE NOT EXISTS (
      SELECT 1 FROM public.bookings
      WHERE customer_id = v_customer_id AND salon_id = v_salon1 AND service_id = v_service1
    );

    INSERT INTO public.favorites (user_id, salon_id)
    VALUES (v_customer_id, v_salon1), (v_customer_id, v_salon2)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.notifications (user_id, title, message, type, metadata)
    SELECT v_customer_id, 'Welcome to SNIP', 'Discover salons and book your next look.', 'system', '{}'::JSONB
    WHERE NOT EXISTS (
      SELECT 1 FROM public.notifications WHERE user_id = v_customer_id AND title = 'Welcome to SNIP'
    );
  END IF;

  INSERT INTO public.salon_verification_requests (salon_id, submitted_by, decision, notes)
  SELECT v_salon3, v_owner_id, 'submitted', 'Awaiting document review'
  WHERE NOT EXISTS (
    SELECT 1 FROM public.salon_verification_requests WHERE salon_id = v_salon3
  );
END $$;
