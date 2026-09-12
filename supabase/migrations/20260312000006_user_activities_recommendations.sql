-- Migration: 20260312000006_user_activities_recommendations.sql
-- Description: Creates user_activities table for tracking client views, searches, bookings, favorites, and reviews.
-- Adds automated triggers, log_user_activity RPC, and intelligent recommendation engine RPC get_personalized_recommendations.

-- 1. Create user_activities table
CREATE TABLE IF NOT EXISTS public.user_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('view_salon', 'view_service', 'search', 'favorite_salon', 'book_appointment', 'review_salon')),
  salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.services(id) ON DELETE CASCADE,
  category public.service_category,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON public.user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_user_created ON public.user_activities(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_activities_salon_id ON public.user_activities(salon_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_category ON public.user_activities(category);
CREATE INDEX IF NOT EXISTS idx_user_activities_type ON public.user_activities(activity_type);

-- 2. Row Level Security for user_activities
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own activities" ON public.user_activities;
CREATE POLICY "Users can view their own activities"
  ON public.user_activities
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can insert their own activities" ON public.user_activities;
CREATE POLICY "Users can insert their own activities"
  ON public.user_activities
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role full access on user_activities" ON public.user_activities;
CREATE POLICY "Service role full access on user_activities"
  ON public.user_activities
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 3. Automatic Triggers for Bookings, Favorites, Reviews

-- Trigger on bookings: logs 'book_appointment'
CREATE OR REPLACE FUNCTION public.trg_log_booking_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_category public.service_category;
BEGIN
  SELECT category INTO v_category FROM public.services WHERE id = NEW.service_id LIMIT 1;
  INSERT INTO public.user_activities (
    user_id,
    activity_type,
    salon_id,
    service_id,
    category,
    metadata
  )
  VALUES (
    NEW.customer_id,
    'book_appointment',
    NEW.salon_id,
    NEW.service_id,
    v_category,
    jsonb_build_object('booking_id', NEW.id, 'price', NEW.price)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bookings_log_activity ON public.bookings;
CREATE TRIGGER trg_bookings_log_activity
AFTER INSERT ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.trg_log_booking_activity();

-- Trigger on favorites: logs 'favorite_salon'
CREATE OR REPLACE FUNCTION public.trg_log_favorite_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_activities (
    user_id,
    activity_type,
    salon_id,
    metadata
  )
  VALUES (
    NEW.user_id,
    'favorite_salon',
    NEW.salon_id,
    '{}'::JSONB
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_favorites_log_activity ON public.favorites;
CREATE TRIGGER trg_favorites_log_activity
AFTER INSERT ON public.favorites
FOR EACH ROW EXECUTE FUNCTION public.trg_log_favorite_activity();

-- Trigger on reviews: logs 'review_salon'
CREATE OR REPLACE FUNCTION public.trg_log_review_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_activities (
    user_id,
    activity_type,
    salon_id,
    metadata
  )
  VALUES (
    NEW.customer_id,
    'review_salon',
    NEW.salon_id,
    jsonb_build_object('rating', NEW.rating, 'review_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reviews_log_activity ON public.reviews;
CREATE TRIGGER trg_reviews_log_activity
AFTER INSERT ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.trg_log_review_activity();

-- 4. RPC: log_user_activity
CREATE OR REPLACE FUNCTION public.log_user_activity(
  p_activity_type TEXT,
  p_salon_id UUID DEFAULT NULL,
  p_service_id UUID DEFAULT NULL,
  p_category public.service_category DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_activity_id UUID;
  v_category public.service_category := p_category;
  v_salon_id UUID := p_salon_id;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- Auto-populate category and salon_id from service if provided
  IF p_service_id IS NOT NULL THEN
    IF v_category IS NULL THEN
      SELECT category INTO v_category FROM public.services WHERE id = p_service_id LIMIT 1;
    END IF;
    IF v_salon_id IS NULL THEN
      SELECT salon_id INTO v_salon_id FROM public.services WHERE id = p_service_id LIMIT 1;
    END IF;
  END IF;

  INSERT INTO public.user_activities (
    user_id,
    activity_type,
    salon_id,
    service_id,
    category,
    metadata
  )
  VALUES (
    v_user_id,
    p_activity_type,
    v_salon_id,
    p_service_id,
    v_category,
    COALESCE(p_metadata, '{}'::JSONB)
  )
  RETURNING id INTO v_activity_id;

  RETURN v_activity_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.log_user_activity(TEXT, UUID, UUID, public.service_category, JSONB) TO authenticated;

-- 5. RPC: get_personalized_recommendations
CREATE OR REPLACE FUNCTION public.get_personalized_recommendations(
  p_user_id UUID DEFAULT NULL,
  p_latitude NUMERIC DEFAULT NULL,
  p_longitude NUMERIC DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  description TEXT,
  city TEXT,
  address TEXT,
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  logo_url TEXT,
  cover_url TEXT,
  avg_rating NUMERIC(3, 2),
  review_count INTEGER,
  distance_km NUMERIC(10, 2),
  recommendation_score NUMERIC(10, 2),
  recommendation_reason TEXT,
  matched_category TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := COALESCE(p_user_id, auth.uid());
BEGIN
  RETURN QUERY
  WITH user_category_weights AS (
    -- Aggregate user category affinities from activities
    SELECT
      ua.category,
      SUM(
        CASE ua.activity_type
          WHEN 'book_appointment' THEN 10
          WHEN 'favorite_salon' THEN 6
          WHEN 'review_salon' THEN 5
          WHEN 'view_service' THEN 3
          WHEN 'view_salon' THEN 2
          WHEN 'search' THEN 2
          ELSE 1
        END
      )::NUMERIC AS weight
    FROM public.user_activities ua
    WHERE (v_user_id IS NOT NULL AND ua.user_id = v_user_id)
      AND ua.category IS NOT NULL
    GROUP BY ua.category
  ),
  salon_category_matches AS (
    -- Match verified salons to user preferred categories
    SELECT
      s_inner.id AS s_id,
      svc.category AS svc_cat,
      COALESCE(ucw.weight, 0) AS cat_weight
    FROM public.salons s_inner
    JOIN public.services svc ON svc.salon_id = s_inner.id AND svc.is_active = TRUE
    LEFT JOIN user_category_weights ucw ON ucw.category = svc.category
    WHERE s_inner.verification_status = 'verified' AND s_inner.is_active = TRUE
  ),
  salon_scores AS (
    SELECT
      scm.s_id,
      MAX(scm.cat_weight) AS max_cat_weight,
      SUM(scm.cat_weight) AS total_cat_affinity,
      (
        SELECT sub.svc_cat::TEXT
        FROM salon_category_matches sub
        WHERE sub.s_id = scm.s_id AND sub.cat_weight > 0
        ORDER BY sub.cat_weight DESC
        LIMIT 1
      ) AS top_matched_category
    FROM salon_category_matches scm
    GROUP BY scm.s_id
  ),
  calculated_salons AS (
    SELECT
      s.id,
      s.name,
      s.slug,
      s.description,
      s.city,
      s.address,
      s.latitude,
      s.longitude,
      s.logo_url,
      s.cover_url,
      s.avg_rating,
      s.review_count,
      CASE
        WHEN p_latitude IS NOT NULL AND p_longitude IS NOT NULL AND s.latitude IS NOT NULL AND s.longitude IS NOT NULL
        THEN ROUND((6371 * acos(
          LEAST(1.0, GREATEST(-1.0,
            cos(radians(p_latitude)) * cos(radians(s.latitude)) * cos(radians(s.longitude) - radians(p_longitude)) +
            sin(radians(p_latitude)) * sin(radians(s.latitude))
          ))
        ))::NUMERIC, 2)
        ELSE NULL
      END AS calc_dist_km,
      COALESCE(sc.total_cat_affinity, 0) AS cat_affinity,
      COALESCE(sc.max_cat_weight, 0) AS max_weight,
      sc.top_matched_category,
      EXISTS (
        SELECT 1 FROM public.favorites f
        WHERE v_user_id IS NOT NULL AND f.user_id = v_user_id AND f.salon_id = s.id
      ) AS is_user_favorite
    FROM public.salons s
    LEFT JOIN salon_scores sc ON sc.s_id = s.id
    WHERE s.verification_status = 'verified' AND s.is_active = TRUE
  )
  SELECT
    cs.id,
    cs.name,
    cs.slug,
    cs.description,
    cs.city,
    cs.address,
    cs.latitude,
    cs.longitude,
    cs.logo_url,
    cs.cover_url,
    cs.avg_rating,
    cs.review_count,
    cs.calc_dist_km AS distance_km,
    ROUND(
      (
        -- Activity & category affinity score (up to 40 pts)
        (cs.cat_affinity * 1.5) +
        -- Rating score (5 stars = 25 pts)
        (COALESCE(cs.avg_rating, 0) * 5.0) +
        -- Social proof review count (logarithmic, up to 15 pts)
        (LN(GREATEST(cs.review_count, 0) + 1) * 3.0) +
        -- Proximity bonus (up to 10 pts if within 20km)
        (CASE WHEN cs.calc_dist_km IS NOT NULL AND cs.calc_dist_km <= 20 THEN (20 - cs.calc_dist_km) * 0.5 ELSE 0 END) +
        -- Favorited bonus (15 pts)
        (CASE WHEN cs.is_user_favorite THEN 15.0 ELSE 0.0 END)
      )::NUMERIC,
      2
    ) AS recommendation_score,
    CASE
      WHEN cs.is_user_favorite
        THEN 'In your favorites'
      WHEN cs.top_matched_category IS NOT NULL AND cs.max_weight > 0
        THEN 'Specializes in ' || initcap(cs.top_matched_category) || ' based on your activity'
      WHEN cs.calc_dist_km IS NOT NULL AND cs.calc_dist_km <= 5
        THEN 'Near your location (' || cs.calc_dist_km || ' km away)'
      WHEN cs.avg_rating >= 4.5 AND cs.review_count > 0
        THEN 'Top rated (' || cs.avg_rating || '★ with ' || cs.review_count || ' reviews)'
      WHEN cs.calc_dist_km IS NOT NULL AND cs.calc_dist_km <= 25
        THEN 'Popular in your area'
      ELSE 'Recommended on SNIP'
    END AS recommendation_reason,
    cs.top_matched_category AS matched_category
  FROM calculated_salons cs
  ORDER BY
    recommendation_score DESC,
    cs.avg_rating DESC,
    cs.calc_dist_km ASC NULLS LAST
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_personalized_recommendations(UUID, NUMERIC, NUMERIC, INTEGER) TO authenticated, anon;

-- 6. RPC: get_user_recent_activity
CREATE OR REPLACE FUNCTION public.get_user_recent_activity(
  p_user_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  activity_type TEXT,
  salon_id UUID,
  salon_name TEXT,
  salon_slug TEXT,
  salon_cover_url TEXT,
  service_id UUID,
  service_name TEXT,
  category TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := COALESCE(p_user_id, auth.uid());
BEGIN
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    ua.id,
    ua.activity_type,
    ua.salon_id,
    s.name AS salon_name,
    s.slug AS salon_slug,
    s.cover_url AS salon_cover_url,
    ua.service_id,
    svc.name AS service_name,
    ua.category::TEXT,
    ua.metadata,
    ua.created_at
  FROM public.user_activities ua
  LEFT JOIN public.salons s ON s.id = ua.salon_id
  LEFT JOIN public.services svc ON svc.id = ua.service_id
  WHERE ua.user_id = v_user_id
  ORDER BY ua.created_at DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_recent_activity(UUID, INTEGER) TO authenticated;

-- 7. Backfill activities for existing bookings, favorites, and reviews
INSERT INTO public.user_activities (user_id, activity_type, salon_id, service_id, category, metadata, created_at)
SELECT
  b.customer_id,
  'book_appointment',
  b.salon_id,
  b.service_id,
  svc.category,
  jsonb_build_object('booking_id', b.id, 'price', b.price),
  b.created_at
FROM public.bookings b
LEFT JOIN public.services svc ON svc.id = b.service_id;

INSERT INTO public.user_activities (user_id, activity_type, salon_id, metadata, created_at)
SELECT
  f.user_id,
  'favorite_salon',
  f.salon_id,
  '{}'::JSONB,
  f.created_at
FROM public.favorites f;

INSERT INTO public.user_activities (user_id, activity_type, salon_id, metadata, created_at)
SELECT
  r.customer_id,
  'review_salon',
  r.salon_id,
  jsonb_build_object('rating', r.rating, 'review_id', r.id),
  r.created_at
FROM public.reviews r;
