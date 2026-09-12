-- Migration: 20260312000004_reviews_and_ratings.sql
-- Description: Adds reviews table, salon rating aggregates, triggers, RLS policies, and submit_booking_review RPC.

-- 1. Add rating aggregate columns to public.salons
ALTER TABLE public.salons
  ADD COLUMN IF NOT EXISTS avg_rating NUMERIC(3, 2) NOT NULL DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS review_count INTEGER NOT NULL DEFAULT 0;

-- 2. Create public.reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  barber_id UUID REFERENCES public.barbers(id) ON DELETE SET NULL,
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CONSTRAINT reviews_rating_check CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT reviews_booking_id_unique UNIQUE (booking_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_salon_id ON public.reviews(salon_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON public.reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_barber_id ON public.reviews(barber_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews(created_at DESC);

-- 3. Trigger for updated_at on reviews
CREATE TRIGGER trg_reviews_updated_at
BEFORE UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 4. Function to recalculate salon avg_rating and review_count
CREATE OR REPLACE FUNCTION public.sync_salon_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_salon_id UUID;
  new_avg NUMERIC(3, 2);
  new_count INTEGER;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_salon_id := OLD.salon_id;
  ELSE
    target_salon_id := NEW.salon_id;
  END IF;

  SELECT
    COALESCE(ROUND(AVG(rating)::numeric, 2), 0.00),
    COUNT(*)
  INTO
    new_avg,
    new_count
  FROM public.reviews
  WHERE salon_id = target_salon_id;

  UPDATE public.salons
  SET
    avg_rating = new_avg,
    review_count = new_count,
    updated_at = NOW()
  WHERE id = target_salon_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_salon_rating ON public.reviews;
CREATE TRIGGER trg_sync_salon_rating
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.sync_salon_rating();

-- 5. Enable RLS on public.reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Select: Publicly viewable
DROP POLICY IF EXISTS reviews_select_policy ON public.reviews;
CREATE POLICY reviews_select_policy ON public.reviews
  FOR SELECT USING (true);

-- Insert: Customer can only insert a review for their own completed booking
DROP POLICY IF EXISTS reviews_insert_policy ON public.reviews;
CREATE POLICY reviews_insert_policy ON public.reviews
  FOR INSERT WITH CHECK (
    auth.uid() = customer_id
    AND EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_id
        AND b.customer_id = auth.uid()
        AND b.status = 'completed'
    )
  );

-- Update: Customer can update their own review
DROP POLICY IF EXISTS reviews_update_policy ON public.reviews;
CREATE POLICY reviews_update_policy ON public.reviews
  FOR UPDATE USING (
    auth.uid() = customer_id
  ) WITH CHECK (
    auth.uid() = customer_id
  );

-- Delete: Customer or Admin can delete review
DROP POLICY IF EXISTS reviews_delete_policy ON public.reviews;
CREATE POLICY reviews_delete_policy ON public.reviews
  FOR DELETE USING (
    auth.uid() = customer_id OR public.current_user_role() = 'admin'
  );

-- 6. RPC Function for submitting reviews safely
CREATE OR REPLACE FUNCTION public.submit_booking_review(
  p_booking_id UUID,
  p_rating INTEGER,
  p_comment TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking RECORD;
  v_user_id UUID;
  v_review_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5';
  END IF;

  SELECT id, customer_id, salon_id, barber_id, status
  INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_booking.customer_id != v_user_id AND public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'You can only review your own appointments';
  END IF;

  IF v_booking.status != 'completed' THEN
    RAISE EXCEPTION 'You can only review completed appointments (current status: %)', v_booking.status;
  END IF;

  INSERT INTO public.reviews (
    booking_id,
    salon_id,
    barber_id,
    customer_id,
    rating,
    comment
  ) VALUES (
    v_booking.id,
    v_booking.salon_id,
    v_booking.barber_id,
    v_booking.customer_id,
    p_rating,
    NULLIF(TRIM(p_comment), '')
  )
  ON CONFLICT (booking_id) DO UPDATE SET
    rating = EXCLUDED.rating,
    comment = EXCLUDED.comment,
    updated_at = NOW()
  RETURNING id INTO v_review_id;

  RETURN jsonb_build_object(
    'review_id', v_review_id,
    'booking_id', v_booking.id,
    'salon_id', v_booking.salon_id,
    'rating', p_rating,
    'success', true
  );
END;
$$;

-- 7. Add reviews to Realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.reviews;
