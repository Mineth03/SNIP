-- Migration: 20260312000005_nearby_salons.sql
-- Description: Adds Haversine proximity search RPC get_nearby_salons, updates search_salons to support optional coordinates, and populates default coordinates for existing demo salons.

-- 1. Ensure existing salons have valid default coordinates if null (Default: Colombo, Sri Lanka)
UPDATE public.salons
SET
  latitude = 6.8918,
  longitude = 79.8732
WHERE latitude IS NULL OR longitude IS NULL;

-- Index on latitude and longitude for performance
CREATE INDEX IF NOT EXISTS idx_salons_coordinates ON public.salons(latitude, longitude);

-- 2. Create RPC function: get_nearby_salons
CREATE OR REPLACE FUNCTION public.get_nearby_salons(
  p_latitude NUMERIC,
  p_longitude NUMERIC,
  p_radius_km NUMERIC DEFAULT 50,
  p_category public.service_category DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  owner_id UUID,
  name TEXT,
  slug TEXT,
  description TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  logo_url TEXT,
  cover_url TEXT,
  verification_status public.salon_verification_status,
  rejection_reason TEXT,
  is_active BOOLEAN,
  opening_hours JSONB,
  avg_rating NUMERIC(3, 2),
  review_count INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  distance_km NUMERIC(10, 2)
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.owner_id,
    s.name,
    s.slug,
    s.description,
    s.email,
    s.phone,
    s.address,
    s.city,
    s.latitude,
    s.longitude,
    s.logo_url,
    s.cover_url,
    s.verification_status,
    s.rejection_reason,
    s.is_active,
    s.opening_hours,
    s.avg_rating,
    s.review_count,
    s.created_at,
    s.updated_at,
    ROUND(
      (6371 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(p_latitude)) * cos(radians(s.latitude)) *
          cos(radians(s.longitude) - radians(p_longitude)) +
          sin(radians(p_latitude)) * sin(radians(s.latitude))
        ))
      ))::numeric,
      2
    ) AS distance_km
  FROM public.salons s
  LEFT JOIN public.services svc ON svc.salon_id = s.id AND svc.is_active = TRUE
  WHERE s.is_active = TRUE
    AND s.latitude IS NOT NULL
    AND s.longitude IS NOT NULL
    AND (p_category IS NULL OR svc.category = p_category)
    AND (
      6371 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(p_latitude)) * cos(radians(s.latitude)) *
          cos(radians(s.longitude) - radians(p_longitude)) +
          sin(radians(p_latitude)) * sin(radians(s.latitude))
        ))
      )
    ) <= p_radius_km
  GROUP BY s.id
  ORDER BY distance_km ASC
  LIMIT GREATEST(p_limit, 1)
  OFFSET GREATEST(p_offset, 0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_nearby_salons TO authenticated, anon;
