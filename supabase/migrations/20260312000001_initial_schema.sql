-- SNIP initial schema
-- Enums, tables, indexes, triggers, booking engine, RLS, storage

-- =============================================================================
-- EXTENSIONS
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- =============================================================================
-- ENUMS
-- =============================================================================
CREATE TYPE public.user_role AS ENUM (
  'customer',
  'salon_owner',
  'barber',
  'admin'
);

CREATE TYPE public.salon_verification_status AS ENUM (
  'draft',
  'pending_verification',
  'verified',
  'rejected',
  'suspended'
);

CREATE TYPE public.booking_status AS ENUM (
  'pending',
  'confirmed',
  'checked_in',
  'in_progress',
  'completed',
  'cancelled',
  'no_show'
);

CREATE TYPE public.service_category AS ENUM (
  'hair',
  'beard',
  'nails',
  'facial',
  'massage',
  'color',
  'other'
);

CREATE TYPE public.notification_type AS ENUM (
  'booking_created',
  'booking_confirmed',
  'booking_cancelled',
  'booking_reminder',
  'booking_status',
  'salon_submitted',
  'salon_approved',
  'salon_rejected',
  'salon_changes_requested',
  'staff_invitation',
  'system'
);

CREATE TYPE public.verification_decision AS ENUM (
  'submitted',
  'approved',
  'rejected',
  'changes_requested'
);

CREATE TYPE public.day_of_week AS ENUM (
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday'
);

-- =============================================================================
-- HELPERS
-- =============================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.slugify(input TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT TRIM(BOTH '-' FROM REGEXP_REPLACE(LOWER(unaccent(COALESCE(input, ''))), '[^a-z0-9]+', '-', 'g'));
$$;

-- =============================================================================
-- PROFILES
-- =============================================================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.user_role NOT NULL DEFAULT 'customer',
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  city TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT profiles_email_unique UNIQUE (email)
);

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_is_active ON public.profiles(is_active);

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_role public.user_role;
BEGIN
  selected_role := COALESCE(
    (NEW.raw_user_meta_data->>'role')::public.user_role,
    'customer'::public.user_role
  );

  -- Public signup may only create customer or salon_owner
  IF selected_role NOT IN ('customer', 'salon_owner') THEN
    selected_role := 'customer';
  END IF;

  INSERT INTO public.profiles (id, role, full_name, email, phone)
  VALUES (
    NEW.id,
    selected_role,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.email,
    NEW.raw_user_meta_data->>'phone'
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- SALONS
-- =============================================================================
CREATE TABLE public.salons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  logo_url TEXT,
  cover_url TEXT,
  verification_status public.salon_verification_status NOT NULL DEFAULT 'draft',
  rejection_reason TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  opening_hours JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT salons_slug_unique UNIQUE (slug),
  CONSTRAINT salons_name_not_empty CHECK (char_length(trim(name)) > 0)
);

CREATE INDEX idx_salons_owner_id ON public.salons(owner_id);
CREATE INDEX idx_salons_city ON public.salons(city);
CREATE INDEX idx_salons_verification_status ON public.salons(verification_status);
CREATE INDEX idx_salons_is_active ON public.salons(is_active);
CREATE INDEX idx_salons_name_trgm ON public.salons USING gin (to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(city, '') || ' ' || coalesce(description, '')));

CREATE TRIGGER trg_salons_updated_at
BEFORE UPDATE ON public.salons
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.ensure_salon_slug()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  base_slug TEXT;
  candidate TEXT;
  counter INTEGER := 1;
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    base_slug := public.slugify(NEW.name);
  ELSE
    base_slug := public.slugify(NEW.slug);
  END IF;

  IF base_slug IS NULL OR base_slug = '' THEN
    base_slug := 'salon';
  END IF;

  candidate := base_slug;
  WHILE EXISTS (
    SELECT 1 FROM public.salons s
    WHERE s.slug = candidate AND (TG_OP = 'INSERT' OR s.id <> NEW.id)
  ) LOOP
    counter := counter + 1;
    candidate := base_slug || '-' || counter::TEXT;
  END LOOP;

  NEW.slug := candidate;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_salons_slug
BEFORE INSERT OR UPDATE OF name, slug ON public.salons
FOR EACH ROW EXECUTE FUNCTION public.ensure_salon_slug();

-- =============================================================================
-- SALON MEMBERS (multi-salon ready)
-- =============================================================================
CREATE TABLE public.salon_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  member_role public.user_role NOT NULL CHECK (member_role IN ('salon_owner', 'barber')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  invited_email TEXT,
  invitation_token TEXT UNIQUE,
  invitation_accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT salon_members_unique UNIQUE (salon_id, profile_id)
);

CREATE INDEX idx_salon_members_salon_id ON public.salon_members(salon_id);
CREATE INDEX idx_salon_members_profile_id ON public.salon_members(profile_id);

CREATE TRIGGER trg_salon_members_updated_at
BEFORE UPDATE ON public.salon_members
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- SERVICES
-- =============================================================================
CREATE TABLE public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category public.service_category NOT NULL DEFAULT 'other',
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0 AND duration_minutes <= 480),
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_services_salon_id ON public.services(salon_id);
CREATE INDEX idx_services_category ON public.services(category);
CREATE INDEX idx_services_is_active ON public.services(is_active);

CREATE TRIGGER trg_services_updated_at
BEFORE UPDATE ON public.services
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- BARBERS
-- =============================================================================
CREATE TABLE public.barbers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  display_name TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  specializations TEXT[] NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_barbers_salon_id ON public.barbers(salon_id);
CREATE INDEX idx_barbers_profile_id ON public.barbers(profile_id);
CREATE INDEX idx_barbers_is_active ON public.barbers(is_active);

CREATE TRIGGER trg_barbers_updated_at
BEFORE UPDATE ON public.barbers
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.barber_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barber_id UUID NOT NULL REFERENCES public.barbers(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT barber_services_unique UNIQUE (barber_id, service_id)
);

CREATE INDEX idx_barber_services_barber_id ON public.barber_services(barber_id);
CREATE INDEX idx_barber_services_service_id ON public.barber_services(service_id);

CREATE TABLE public.barber_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barber_id UUID NOT NULL REFERENCES public.barbers(id) ON DELETE CASCADE,
  day_of_week public.day_of_week NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_working BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT barber_schedules_valid_range CHECK (end_time > start_time),
  CONSTRAINT barber_schedules_unique UNIQUE (barber_id, day_of_week)
);

CREATE TRIGGER trg_barber_schedules_updated_at
BEFORE UPDATE ON public.barber_schedules
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.barber_breaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barber_id UUID NOT NULL REFERENCES public.barbers(id) ON DELETE CASCADE,
  day_of_week public.day_of_week NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT barber_breaks_valid_range CHECK (end_time > start_time)
);

CREATE INDEX idx_barber_breaks_barber_id ON public.barber_breaks(barber_id);

CREATE TABLE public.barber_time_off (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barber_id UUID NOT NULL REFERENCES public.barbers(id) ON DELETE CASCADE,
  start_datetime TIMESTAMPTZ NOT NULL,
  end_datetime TIMESTAMPTZ NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT barber_time_off_valid_range CHECK (end_datetime > start_datetime)
);

CREATE INDEX idx_barber_time_off_barber_id ON public.barber_time_off(barber_id);
CREATE INDEX idx_barber_time_off_range ON public.barber_time_off(start_datetime, end_datetime);

CREATE TABLE public.barber_portfolio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barber_id UUID NOT NULL REFERENCES public.barbers(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_barber_portfolio_barber_id ON public.barber_portfolio(barber_id);

-- =============================================================================
-- SALON GALLERY
-- =============================================================================
CREATE TABLE public.salon_gallery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_salon_gallery_salon_id ON public.salon_gallery(salon_id);

-- =============================================================================
-- BOOKINGS
-- =============================================================================
CREATE TABLE public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE RESTRICT,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  barber_id UUID NOT NULL REFERENCES public.barbers(id) ON DELETE RESTRICT,
  appointment_start TIMESTAMPTZ NOT NULL,
  appointment_end TIMESTAMPTZ NOT NULL,
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  status public.booking_status NOT NULL DEFAULT 'confirmed',
  customer_notes TEXT,
  qr_token UUID NOT NULL DEFAULT gen_random_uuid(),
  is_walk_in BOOLEAN NOT NULL DEFAULT FALSE,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT bookings_valid_range CHECK (appointment_end > appointment_start),
  CONSTRAINT bookings_qr_token_unique UNIQUE (qr_token)
);

CREATE INDEX idx_bookings_customer_id ON public.bookings(customer_id);
CREATE INDEX idx_bookings_salon_id ON public.bookings(salon_id);
CREATE INDEX idx_bookings_barber_id ON public.bookings(barber_id);
CREATE INDEX idx_bookings_service_id ON public.bookings(service_id);
CREATE INDEX idx_bookings_appointment_start ON public.bookings(appointment_start);
CREATE INDEX idx_bookings_status ON public.bookings(status);
CREATE INDEX idx_bookings_qr_token ON public.bookings(qr_token);
CREATE INDEX idx_bookings_salon_start ON public.bookings(salon_id, appointment_start);

-- Prevent overlapping active bookings for the same barber (race-safe)
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE public.bookings
  ADD CONSTRAINT bookings_no_barber_overlap
  EXCLUDE USING gist (
    barber_id WITH =,
    tstzrange(appointment_start, appointment_end, '[)') WITH &&
  )
  WHERE (status IN ('pending', 'confirmed', 'checked_in', 'in_progress'));

CREATE TRIGGER trg_bookings_updated_at
BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.booking_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  from_status public.booking_status,
  to_status public.booking_status NOT NULL,
  changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_booking_status_history_booking_id ON public.booking_status_history(booking_id);

CREATE OR REPLACE FUNCTION public.log_booking_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.booking_status_history (booking_id, from_status, to_status, changed_by)
    VALUES (NEW.id, NULL, NEW.status, NEW.customer_id);
  ELSIF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.booking_status_history (booking_id, from_status, to_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid());
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_bookings_status_history
AFTER INSERT OR UPDATE OF status ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.log_booking_status_change();

-- =============================================================================
-- FAVORITES / NOTIFICATIONS / VERIFICATION
-- =============================================================================
CREATE TABLE public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT favorites_unique UNIQUE (user_id, salon_id)
);

CREATE INDEX idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX idx_favorites_salon_id ON public.favorites(salon_id);

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type public.notification_type NOT NULL DEFAULT 'system',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id_is_read ON public.notifications(user_id, is_read);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);

CREATE TABLE public.salon_verification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  submitted_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  decision public.verification_decision NOT NULL DEFAULT 'submitted',
  notes TEXT,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ
);

CREATE INDEX idx_salon_verification_requests_salon_id ON public.salon_verification_requests(salon_id);
CREATE INDEX idx_salon_verification_requests_decision ON public.salon_verification_requests(decision);

-- =============================================================================
-- AUTH HELPERS
-- =============================================================================
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin' AND is_active = TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.owns_salon(p_salon_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.salons
    WHERE id = p_salon_id AND owner_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_salon_staff(p_salon_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.salons WHERE id = p_salon_id AND owner_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.salon_members
    WHERE salon_id = p_salon_id AND profile_id = auth.uid() AND is_active = TRUE
  )
  OR EXISTS (
    SELECT 1 FROM public.barbers
    WHERE salon_id = p_salon_id AND profile_id = auth.uid() AND is_active = TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.is_barber_of_booking(p_booking_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.bookings b
    JOIN public.barbers br ON br.id = b.barber_id
    WHERE b.id = p_booking_id AND br.profile_id = auth.uid()
  );
$$;

-- =============================================================================
-- BOOKING ENGINE
-- =============================================================================
CREATE OR REPLACE FUNCTION public.day_of_week_from_ts(p_ts TIMESTAMPTZ)
RETURNS public.day_of_week
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE EXTRACT(ISODOW FROM p_ts)::INTEGER
    WHEN 1 THEN 'monday'::public.day_of_week
    WHEN 2 THEN 'tuesday'::public.day_of_week
    WHEN 3 THEN 'wednesday'::public.day_of_week
    WHEN 4 THEN 'thursday'::public.day_of_week
    WHEN 5 THEN 'friday'::public.day_of_week
    WHEN 6 THEN 'saturday'::public.day_of_week
    WHEN 7 THEN 'sunday'::public.day_of_week
  END;
$$;

CREATE OR REPLACE FUNCTION public.is_valid_booking_transition(
  p_from public.booking_status,
  p_to public.booking_status
)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_from = p_to THEN TRUE
    WHEN p_from = 'pending' AND p_to IN ('confirmed', 'cancelled') THEN TRUE
    WHEN p_from = 'confirmed' AND p_to IN ('checked_in', 'cancelled', 'no_show') THEN TRUE
    WHEN p_from = 'checked_in' AND p_to IN ('in_progress', 'cancelled', 'no_show') THEN TRUE
    WHEN p_from = 'in_progress' AND p_to IN ('completed', 'cancelled') THEN TRUE
    ELSE FALSE
  END;
$$;

CREATE OR REPLACE FUNCTION public.get_available_slots(
  p_salon_id UUID,
  p_service_id UUID,
  p_barber_id UUID DEFAULT NULL,
  p_date DATE DEFAULT CURRENT_DATE,
  p_slot_interval_minutes INTEGER DEFAULT 15,
  p_buffer_minutes INTEGER DEFAULT 0
)
RETURNS TABLE (
  barber_id UUID,
  barber_name TEXT,
  slot_start TIMESTAMPTZ,
  slot_end TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_duration INTEGER;
  v_service_salon UUID;
BEGIN
  SELECT s.duration_minutes, s.salon_id
  INTO v_duration, v_service_salon
  FROM public.services s
  WHERE s.id = p_service_id AND s.is_active = TRUE;

  IF v_duration IS NULL THEN
    RAISE EXCEPTION 'Service not found or inactive';
  END IF;

  IF v_service_salon <> p_salon_id THEN
    RAISE EXCEPTION 'Service does not belong to salon';
  END IF;

  RETURN QUERY
  WITH candidate_barbers AS (
    SELECT b.id, b.display_name
    FROM public.barbers b
    WHERE b.salon_id = p_salon_id
      AND b.is_active = TRUE
      AND (p_barber_id IS NULL OR b.id = p_barber_id)
      AND (
        NOT EXISTS (SELECT 1 FROM public.barber_services bs WHERE bs.barber_id = b.id)
        OR EXISTS (
          SELECT 1 FROM public.barber_services bs
          WHERE bs.barber_id = b.id AND bs.service_id = p_service_id
        )
      )
  ),
  working AS (
    SELECT
      cb.id AS barber_id,
      cb.display_name,
      (p_date + sch.start_time) AT TIME ZONE 'UTC' AS work_start,
      (p_date + sch.end_time) AT TIME ZONE 'UTC' AS work_end
    FROM candidate_barbers cb
    JOIN public.barber_schedules sch ON sch.barber_id = cb.id
    WHERE sch.day_of_week = public.day_of_week_from_ts((p_date::TIMESTAMP AT TIME ZONE 'UTC'))
      AND sch.is_working = TRUE
  ),
  slots AS (
    SELECT
      w.barber_id,
      w.display_name,
      gs AS slot_start,
      gs + make_interval(mins => v_duration) AS slot_end
    FROM working w
    CROSS JOIN LATERAL generate_series(
      w.work_start,
      w.work_end - make_interval(mins => v_duration),
      make_interval(mins => p_slot_interval_minutes)
    ) AS gs
  )
  SELECT
    s.barber_id,
    s.display_name,
    s.slot_start,
    s.slot_end
  FROM slots s
  WHERE s.slot_start >= NOW()
    AND NOT EXISTS (
      SELECT 1 FROM public.barber_breaks br
      WHERE br.barber_id = s.barber_id
        AND br.day_of_week = public.day_of_week_from_ts(s.slot_start)
        AND tstzrange(s.slot_start, s.slot_end, '[)') &&
            tstzrange(
              (p_date + br.start_time) AT TIME ZONE 'UTC',
              (p_date + br.end_time) AT TIME ZONE 'UTC',
              '[)'
            )
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.barber_time_off t
      WHERE t.barber_id = s.barber_id
        AND tstzrange(s.slot_start, s.slot_end, '[)') &&
            tstzrange(t.start_datetime, t.end_datetime, '[)')
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.barber_id = s.barber_id
        AND b.status IN ('pending', 'confirmed', 'checked_in', 'in_progress')
        AND tstzrange(
              s.slot_start - make_interval(mins => p_buffer_minutes),
              s.slot_end + make_interval(mins => p_buffer_minutes),
              '[)'
            ) &&
            tstzrange(b.appointment_start, b.appointment_end, '[)')
    )
  ORDER BY s.slot_start, s.display_name;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_booking(
  p_salon_id UUID,
  p_service_id UUID,
  p_appointment_start TIMESTAMPTZ,
  p_barber_id UUID DEFAULT NULL,
  p_customer_id UUID DEFAULT NULL,
  p_customer_notes TEXT DEFAULT NULL,
  p_is_walk_in BOOLEAN DEFAULT FALSE
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_customer_id UUID;
  v_service RECORD;
  v_barber_id UUID;
  v_end TIMESTAMPTZ;
  v_booking public.bookings;
  v_slot RECORD;
BEGIN
  v_customer_id := COALESCE(p_customer_id, auth.uid());

  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_customer_id AND is_active = TRUE) THEN
    RAISE EXCEPTION 'Customer not found';
  END IF;

  SELECT * INTO v_service
  FROM public.services
  WHERE id = p_service_id AND salon_id = p_salon_id AND is_active = TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service not available';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.salons
    WHERE id = p_salon_id
      AND is_active = TRUE
      AND (
        verification_status = 'verified'
        OR owner_id = auth.uid()
        OR public.is_admin()
      )
  ) THEN
    RAISE EXCEPTION 'Salon not available for booking';
  END IF;

  -- Walk-ins / staff creating bookings for others require salon access
  IF p_is_walk_in OR (p_customer_id IS NOT NULL AND p_customer_id <> auth.uid()) THEN
    IF NOT (public.owns_salon(p_salon_id) OR public.is_salon_staff(p_salon_id) OR public.is_admin()) THEN
      RAISE EXCEPTION 'Not allowed to create bookings for this salon';
    END IF;
  ELSIF v_customer_id <> auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Cannot create booking for another customer';
  END IF;

  SELECT s.barber_id INTO v_barber_id
  FROM public.get_available_slots(
    p_salon_id,
    p_service_id,
    p_barber_id,
    (p_appointment_start AT TIME ZONE 'UTC')::DATE,
    15,
    0
  ) s
  WHERE s.slot_start = p_appointment_start
  ORDER BY CASE WHEN p_barber_id IS NOT NULL AND s.barber_id = p_barber_id THEN 0 ELSE 1 END
  LIMIT 1;

  IF v_barber_id IS NULL THEN
    RAISE EXCEPTION 'Selected time slot is no longer available';
  END IF;

  v_end := p_appointment_start + make_interval(mins => v_service.duration_minutes);

  INSERT INTO public.bookings (
    customer_id,
    salon_id,
    service_id,
    barber_id,
    appointment_start,
    appointment_end,
    price,
    status,
    customer_notes,
    is_walk_in
  )
  VALUES (
    v_customer_id,
    p_salon_id,
    p_service_id,
    v_barber_id,
    p_appointment_start,
    v_end,
    v_service.price,
    'confirmed',
    p_customer_notes,
    p_is_walk_in
  )
  RETURNING * INTO v_booking;

  INSERT INTO public.notifications (user_id, title, message, type, metadata)
  VALUES (
    v_customer_id,
    'Booking confirmed',
    'Your appointment has been confirmed.',
    'booking_confirmed',
    jsonb_build_object('booking_id', v_booking.id)
  );

  RETURN v_booking;
EXCEPTION
  WHEN exclusion_violation THEN
    RAISE EXCEPTION 'Selected time slot is no longer available';
END;
$$;

CREATE OR REPLACE FUNCTION public.transition_booking_status(
  p_booking_id UUID,
  p_to_status public.booking_status,
  p_note TEXT DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking public.bookings;
  v_salon_id UUID;
BEGIN
  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  v_salon_id := v_booking.salon_id;

  IF NOT public.is_valid_booking_transition(v_booking.status, p_to_status) THEN
    RAISE EXCEPTION 'Invalid status transition from % to %', v_booking.status, p_to_status;
  END IF;

  -- Permissions
  IF p_to_status = 'cancelled' THEN
    IF NOT (
      v_booking.customer_id = auth.uid()
      OR public.owns_salon(v_salon_id)
      OR public.is_salon_staff(v_salon_id)
      OR public.is_admin()
    ) THEN
      RAISE EXCEPTION 'Not allowed to cancel booking';
    END IF;
  ELSE
    IF NOT (
      public.owns_salon(v_salon_id)
      OR public.is_barber_of_booking(p_booking_id)
      OR public.is_admin()
    ) THEN
      RAISE EXCEPTION 'Not allowed to update booking status';
    END IF;
  END IF;

  UPDATE public.bookings
  SET
    status = p_to_status,
    cancelled_at = CASE WHEN p_to_status = 'cancelled' THEN NOW() ELSE cancelled_at END,
    cancellation_reason = CASE WHEN p_to_status = 'cancelled' THEN p_note ELSE cancellation_reason END
  WHERE id = p_booking_id
  RETURNING * INTO v_booking;

  INSERT INTO public.notifications (user_id, title, message, type, metadata)
  VALUES (
    v_booking.customer_id,
    'Booking updated',
    'Your booking status is now ' || replace(p_to_status::TEXT, '_', ' ') || '.',
    'booking_status',
    jsonb_build_object('booking_id', v_booking.id, 'status', p_to_status)
  );

  RETURN v_booking;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_in_with_qr(p_qr_token UUID)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking public.bookings;
BEGIN
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE qr_token = p_qr_token
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid QR ticket';
  END IF;

  IF NOT (
    public.owns_salon(v_booking.salon_id)
    OR public.is_barber_of_booking(v_booking.id)
    OR public.is_admin()
  ) THEN
    RAISE EXCEPTION 'Not allowed to check in this booking';
  END IF;

  IF v_booking.status = 'checked_in' THEN
    RAISE EXCEPTION 'QR already processed';
  END IF;

  IF v_booking.status = 'cancelled' THEN
    RAISE EXCEPTION 'Booking cancelled';
  END IF;

  IF v_booking.status <> 'confirmed' THEN
    RAISE EXCEPTION 'Booking cannot be checked in from status %', v_booking.status;
  END IF;

  RETURN public.transition_booking_status(v_booking.id, 'checked_in', 'Checked in via QR');
END;
$$;

-- =============================================================================
-- SEARCH
-- =============================================================================
CREATE OR REPLACE FUNCTION public.search_salons(
  p_query TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_category public.service_category DEFAULT NULL,
  p_verified_only BOOLEAN DEFAULT TRUE,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS SETOF public.salons
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT s.*
  FROM public.salons s
  LEFT JOIN public.services svc ON svc.salon_id = s.id AND svc.is_active = TRUE
  LEFT JOIN public.barbers b ON b.salon_id = s.id AND b.is_active = TRUE
  WHERE s.is_active = TRUE
    AND (NOT p_verified_only OR s.verification_status = 'verified')
    AND (p_city IS NULL OR s.city ILIKE p_city)
    AND (p_category IS NULL OR svc.category = p_category)
    AND (
      p_query IS NULL OR p_query = '' OR
      s.name ILIKE '%' || p_query || '%' OR
      s.city ILIKE '%' || p_query || '%' OR
      s.description ILIKE '%' || p_query || '%' OR
      svc.name ILIKE '%' || p_query || '%' OR
      b.display_name ILIKE '%' || p_query || '%'
    )
  ORDER BY s.name
  LIMIT GREATEST(p_limit, 1)
  OFFSET GREATEST(p_offset, 0);
END;
$$;

-- =============================================================================
-- RLS
-- =============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salon_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barber_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barber_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barber_breaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barber_time_off ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barber_portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salon_gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salon_verification_requests ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY profiles_select_own_or_admin ON public.profiles
  FOR SELECT USING (id = auth.uid() OR public.is_admin());

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (id = auth.uid() OR public.is_admin())
  WITH CHECK (
    (id = auth.uid() AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()))
    OR public.is_admin()
  );

-- Salons
CREATE POLICY salons_public_read ON public.salons
  FOR SELECT USING (
    (verification_status = 'verified' AND is_active = TRUE)
    OR owner_id = auth.uid()
    OR public.is_salon_staff(id)
    OR public.is_admin()
  );

CREATE POLICY salons_owner_insert ON public.salons
  FOR INSERT WITH CHECK (
    owner_id = auth.uid()
    AND public.current_user_role() IN ('salon_owner', 'admin')
  );

CREATE POLICY salons_owner_update ON public.salons
  FOR UPDATE USING (owner_id = auth.uid() OR public.is_admin())
  WITH CHECK (owner_id = auth.uid() OR public.is_admin());

-- Salon members
CREATE POLICY salon_members_select ON public.salon_members
  FOR SELECT USING (
    profile_id = auth.uid()
    OR public.owns_salon(salon_id)
    OR public.is_admin()
  );

CREATE POLICY salon_members_manage ON public.salon_members
  FOR ALL USING (public.owns_salon(salon_id) OR public.is_admin())
  WITH CHECK (public.owns_salon(salon_id) OR public.is_admin());

-- Services
CREATE POLICY services_public_read ON public.services
  FOR SELECT USING (
    (is_active = TRUE AND EXISTS (
      SELECT 1 FROM public.salons s
      WHERE s.id = salon_id AND s.verification_status = 'verified' AND s.is_active = TRUE
    ))
    OR public.owns_salon(salon_id)
    OR public.is_salon_staff(salon_id)
    OR public.is_admin()
  );

CREATE POLICY services_owner_write ON public.services
  FOR ALL USING (public.owns_salon(salon_id) OR public.is_admin())
  WITH CHECK (public.owns_salon(salon_id) OR public.is_admin());

-- Barbers
CREATE POLICY barbers_public_read ON public.barbers
  FOR SELECT USING (
    (is_active = TRUE AND EXISTS (
      SELECT 1 FROM public.salons s
      WHERE s.id = salon_id AND s.verification_status = 'verified' AND s.is_active = TRUE
    ))
    OR public.owns_salon(salon_id)
    OR profile_id = auth.uid()
    OR public.is_admin()
  );

CREATE POLICY barbers_owner_write ON public.barbers
  FOR ALL USING (public.owns_salon(salon_id) OR public.is_admin())
  WITH CHECK (public.owns_salon(salon_id) OR public.is_admin());

-- Barber services / schedules / breaks / time off
CREATE POLICY barber_services_read ON public.barber_services
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (
      public.owns_salon(b.salon_id) OR b.profile_id = auth.uid() OR public.is_admin()
      OR (b.is_active AND EXISTS (
        SELECT 1 FROM public.salons s WHERE s.id = b.salon_id AND s.verification_status = 'verified'
      ))
    ))
  );

CREATE POLICY barber_services_write ON public.barber_services
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  );

CREATE POLICY barber_schedules_read ON public.barber_schedules
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (
      public.owns_salon(b.salon_id) OR b.profile_id = auth.uid() OR public.is_admin()
      OR (b.is_active AND EXISTS (
        SELECT 1 FROM public.salons s WHERE s.id = b.salon_id AND s.verification_status = 'verified'
      ))
    ))
  );

CREATE POLICY barber_schedules_write ON public.barber_schedules
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  );

CREATE POLICY barber_breaks_read ON public.barber_breaks
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (
      public.owns_salon(b.salon_id) OR b.profile_id = auth.uid() OR public.is_admin()
    ))
  );

CREATE POLICY barber_breaks_write ON public.barber_breaks
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  );

CREATE POLICY barber_time_off_read ON public.barber_time_off
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (
      public.owns_salon(b.salon_id) OR b.profile_id = auth.uid() OR public.is_admin()
    ))
  );

CREATE POLICY barber_time_off_write ON public.barber_time_off
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (public.owns_salon(b.salon_id) OR public.is_admin()))
  );

CREATE POLICY barber_portfolio_read ON public.barber_portfolio
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (
      b.is_active OR public.owns_salon(b.salon_id) OR b.profile_id = auth.uid() OR public.is_admin()
    ))
  );

CREATE POLICY barber_portfolio_write ON public.barber_portfolio
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (
      public.owns_salon(b.salon_id) OR b.profile_id = auth.uid() OR public.is_admin()
    ))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.barbers b WHERE b.id = barber_id AND (
      public.owns_salon(b.salon_id) OR b.profile_id = auth.uid() OR public.is_admin()
    ))
  );

-- Gallery
CREATE POLICY salon_gallery_read ON public.salon_gallery
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.salons s
      WHERE s.id = salon_id AND (
        (s.verification_status = 'verified' AND s.is_active)
        OR s.owner_id = auth.uid()
        OR public.is_admin()
      )
    )
  );

CREATE POLICY salon_gallery_write ON public.salon_gallery
  FOR ALL USING (public.owns_salon(salon_id) OR public.is_admin())
  WITH CHECK (public.owns_salon(salon_id) OR public.is_admin());

-- Bookings
CREATE POLICY bookings_select ON public.bookings
  FOR SELECT USING (
    customer_id = auth.uid()
    OR public.owns_salon(salon_id)
    OR public.is_barber_of_booking(id)
    OR public.is_admin()
  );

CREATE POLICY bookings_insert_customer ON public.bookings
  FOR INSERT WITH CHECK (
    customer_id = auth.uid()
    OR public.owns_salon(salon_id)
    OR public.is_admin()
  );

CREATE POLICY bookings_update ON public.bookings
  FOR UPDATE USING (
    customer_id = auth.uid()
    OR public.owns_salon(salon_id)
    OR public.is_barber_of_booking(id)
    OR public.is_admin()
  )
  WITH CHECK (
    customer_id = auth.uid()
    OR public.owns_salon(salon_id)
    OR public.is_barber_of_booking(id)
    OR public.is_admin()
  );

CREATE POLICY booking_status_history_select ON public.booking_status_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_id AND (
        b.customer_id = auth.uid()
        OR public.owns_salon(b.salon_id)
        OR public.is_barber_of_booking(b.id)
        OR public.is_admin()
      )
    )
  );

-- Favorites
CREATE POLICY favorites_own ON public.favorites
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Notifications
CREATE POLICY notifications_own ON public.notifications
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY notifications_update_own ON public.notifications
  FOR UPDATE USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

CREATE POLICY notifications_insert_system ON public.notifications
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_admin() OR auth.role() = 'service_role');

-- Verification requests
CREATE POLICY verification_select ON public.salon_verification_requests
  FOR SELECT USING (
    submitted_by = auth.uid()
    OR public.owns_salon(salon_id)
    OR public.is_admin()
  );

CREATE POLICY verification_insert ON public.salon_verification_requests
  FOR INSERT WITH CHECK (
    submitted_by = auth.uid() AND public.owns_salon(salon_id)
  );

CREATE POLICY verification_admin_update ON public.salon_verification_requests
  FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =============================================================================
-- STORAGE BUCKETS
-- =============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', TRUE, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('salon-images', 'salon-images', TRUE, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('service-images', 'service-images', TRUE, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('barber-portfolios', 'barber-portfolios', TRUE, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY storage_avatars_read ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY storage_avatars_write ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

CREATE POLICY storage_avatars_update ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

CREATE POLICY storage_salon_images_read ON storage.objects
  FOR SELECT USING (bucket_id = 'salon-images');

CREATE POLICY storage_salon_images_write ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'salon-images' AND auth.role() = 'authenticated'
  );

CREATE POLICY storage_service_images_read ON storage.objects
  FOR SELECT USING (bucket_id = 'service-images');

CREATE POLICY storage_service_images_write ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'service-images' AND auth.role() = 'authenticated'
  );

CREATE POLICY storage_barber_portfolios_read ON storage.objects
  FOR SELECT USING (bucket_id = 'barber-portfolios');

CREATE POLICY storage_barber_portfolios_write ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'barber-portfolios' AND auth.role() = 'authenticated'
  );

-- Grant execute on booking functions to authenticated users
GRANT EXECUTE ON FUNCTION public.get_available_slots TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.create_booking TO authenticated;
GRANT EXECUTE ON FUNCTION public.transition_booking_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_in_with_qr TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_salons TO authenticated, anon;
