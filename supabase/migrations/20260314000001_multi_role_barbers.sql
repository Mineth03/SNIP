-- Multi-role capabilities, multi-salon barbers, invite/resign RPCs

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS active_role public.user_role NOT NULL DEFAULT 'customer',
  ADD COLUMN IF NOT EXISTS active_barber_salon_id UUID REFERENCES public.salons(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_active_role ON public.profiles(active_role);
CREATE INDEX IF NOT EXISTS idx_profiles_active_barber_salon ON public.profiles(active_barber_salon_id);

UPDATE public.profiles
SET active_role = role
WHERE active_role IS DISTINCT FROM role;

ALTER TABLE public.salon_members
  ALTER COLUMN profile_id DROP NOT NULL;

ALTER TABLE public.salon_members
  DROP CONSTRAINT IF EXISTS salon_members_unique;

CREATE UNIQUE INDEX IF NOT EXISTS salon_members_salon_profile_unique
  ON public.salon_members (salon_id, profile_id)
  WHERE profile_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS salon_members_salon_invited_email_unique
  ON public.salon_members (salon_id, lower(invited_email))
  WHERE invited_email IS NOT NULL AND invitation_accepted_at IS NULL AND is_active = TRUE;

CREATE UNIQUE INDEX IF NOT EXISTS barbers_salon_profile_unique
  ON public.barbers (salon_id, profile_id)
  WHERE profile_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.has_owner_capability(p_uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.salons s
    WHERE s.owner_id = p_uid AND s.is_active = TRUE
  )
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_uid AND p.role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.has_barber_capability(p_uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.barbers b
    WHERE b.profile_id = p_uid AND b.is_active = TRUE
  )
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_uid AND p.role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.user_barber_salon_ids(p_uid UUID DEFAULT auth.uid())
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT b.salon_id
  FROM public.barbers b
  WHERE b.profile_id = p_uid AND b.is_active = TRUE;
$$;

CREATE OR REPLACE FUNCTION public.user_capabilities(p_uid UUID DEFAULT auth.uid())
RETURNS TEXT[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caps TEXT[] := ARRAY['customer'];
BEGIN
  IF public.has_owner_capability(p_uid) THEN
    caps := array_append(caps, 'salon_owner');
  END IF;
  IF public.has_barber_capability(p_uid) THEN
    caps := array_append(caps, 'barber');
  END IF;
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = p_uid AND role = 'admin') THEN
    caps := array_append(caps, 'admin');
  END IF;
  RETURN caps;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, role, active_role, full_name, email, phone)
  VALUES (
    NEW.id,
    'customer',
    'customer',
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.email,
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$;

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (id = auth.uid() OR public.is_admin())
  WITH CHECK (
    public.is_admin()
    OR (
      id = auth.uid()
      AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
    )
  );

DROP POLICY IF EXISTS salons_owner_insert ON public.salons;
CREATE POLICY salons_owner_insert ON public.salons
  FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS salon_members_select ON public.salon_members;
CREATE POLICY salon_members_select ON public.salon_members
  FOR SELECT USING (
    profile_id = auth.uid()
    OR public.owns_salon(salon_id)
    OR public.is_admin()
    OR (
      invited_email IS NOT NULL
      AND lower(invited_email) = lower((SELECT email FROM public.profiles WHERE id = auth.uid()))
    )
  );
CREATE OR REPLACE FUNCTION public.invite_barber_to_salon(
  p_salon_id UUID,
  p_email TEXT,
  p_display_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email TEXT := lower(trim(p_email));
  v_token TEXT := encode(gen_random_bytes(24), 'hex');
  v_name TEXT := COALESCE(NULLIF(trim(p_display_name), ''), split_part(v_email, '@', 1));
  v_barber_id UUID;
  v_member_id UUID;
  v_existing_profile UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT (public.owns_salon(p_salon_id) OR public.is_admin()) THEN
    RAISE EXCEPTION 'Only salon owners can invite staff';
  END IF;
  IF v_email IS NULL OR v_email = '' OR position('@' IN v_email) = 0 THEN
    RAISE EXCEPTION 'A valid email is required';
  END IF;

  SELECT id INTO v_existing_profile
  FROM public.profiles
  WHERE lower(email) = v_email
  LIMIT 1;

  SELECT id INTO v_member_id
  FROM public.salon_members
  WHERE salon_id = p_salon_id
    AND (
      (v_existing_profile IS NOT NULL AND profile_id = v_existing_profile)
      OR (invited_email IS NOT NULL AND lower(invited_email) = v_email)
    )
  LIMIT 1;

  IF v_member_id IS NULL THEN
    INSERT INTO public.salon_members (
      salon_id, profile_id, member_role, is_active,
      invited_email, invitation_token, invitation_accepted_at
    )
    VALUES (
      p_salon_id, v_existing_profile, 'barber', TRUE, v_email, v_token, NULL
    )
    RETURNING id INTO v_member_id;
  ELSE
    UPDATE public.salon_members
    SET
      invited_email = v_email,
      invitation_token = v_token,
      invitation_accepted_at = NULL,
      is_active = TRUE,
      profile_id = COALESCE(profile_id, v_existing_profile),
      member_role = 'barber',
      updated_at = NOW()
    WHERE id = v_member_id;
  END IF;

  SELECT id INTO v_barber_id
  FROM public.barbers
  WHERE salon_id = p_salon_id
    AND (
      (v_existing_profile IS NOT NULL AND profile_id = v_existing_profile)
      OR lower(display_name) = lower(v_name)
    )
  LIMIT 1;

  IF v_barber_id IS NULL THEN
    INSERT INTO public.barbers (salon_id, profile_id, display_name, is_active)
    VALUES (p_salon_id, NULL, v_name, TRUE)
    RETURNING id INTO v_barber_id;
  ELSE
    UPDATE public.barbers
    SET is_active = TRUE, display_name = COALESCE(NULLIF(display_name, ''), v_name), updated_at = NOW()
    WHERE id = v_barber_id;
  END IF;

  RETURN jsonb_build_object(
    'member_id', v_member_id,
    'barber_id', v_barber_id,
    'invitation_token', v_token,
    'email', v_email,
    'display_name', v_name
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_barber_invite(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_member public.salon_members%ROWTYPE;
  v_barber_id UUID;
  v_uid UUID := auth.uid();
  v_email TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT email INTO v_email FROM public.profiles WHERE id = v_uid;

  SELECT * INTO v_member
  FROM public.salon_members
  WHERE invitation_token = p_token
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation';
  END IF;

  IF v_member.invitation_accepted_at IS NOT NULL AND v_member.profile_id = v_uid THEN
    RETURN jsonb_build_object('salon_id', v_member.salon_id, 'already_accepted', TRUE);
  END IF;

  IF v_member.invited_email IS NOT NULL
     AND lower(v_member.invited_email) <> lower(v_email) THEN
    RAISE EXCEPTION 'This invitation was sent to a different email address';
  END IF;

  UPDATE public.salon_members
  SET profile_id = v_uid, invitation_accepted_at = NOW(), is_active = TRUE, updated_at = NOW()
  WHERE id = v_member.id;

  SELECT id INTO v_barber_id
  FROM public.barbers
  WHERE salon_id = v_member.salon_id
    AND (profile_id = v_uid OR profile_id IS NULL)
  ORDER BY CASE WHEN profile_id = v_uid THEN 0 ELSE 1 END
  LIMIT 1;

  IF v_barber_id IS NULL THEN
    INSERT INTO public.barbers (salon_id, profile_id, display_name, is_active)
    VALUES (
      v_member.salon_id, v_uid,
      COALESCE((SELECT full_name FROM public.profiles WHERE id = v_uid), 'Stylist'),
      TRUE
    )
    RETURNING id INTO v_barber_id;
  ELSE
    UPDATE public.barbers
    SET
      profile_id = v_uid,
      is_active = TRUE,
      display_name = COALESCE(NULLIF(display_name, ''), (SELECT full_name FROM public.profiles WHERE id = v_uid)),
      updated_at = NOW()
    WHERE id = v_barber_id;
  END IF;

  UPDATE public.profiles
  SET
    active_role = 'barber',
    active_barber_salon_id = COALESCE(active_barber_salon_id, v_member.salon_id),
    updated_at = NOW()
  WHERE id = v_uid;

  RETURN jsonb_build_object('salon_id', v_member.salon_id, 'barber_id', v_barber_id, 'already_accepted', FALSE);
END;
$$;

CREATE OR REPLACE FUNCTION public._deactivate_barber_membership(
  p_salon_id UUID,
  p_profile_id UUID,
  p_barber_id UUID DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.salon_members
  SET is_active = FALSE, updated_at = NOW()
  WHERE salon_id = p_salon_id AND profile_id = p_profile_id;

  IF p_barber_id IS NOT NULL THEN
    UPDATE public.barbers
    SET is_active = FALSE, updated_at = NOW()
    WHERE id = p_barber_id AND salon_id = p_salon_id;
  ELSE
    UPDATE public.barbers
    SET is_active = FALSE, updated_at = NOW()
    WHERE salon_id = p_salon_id AND profile_id = p_profile_id;
  END IF;

  UPDATE public.profiles p
  SET
    active_barber_salon_id = (
      SELECT b.salon_id FROM public.barbers b
      WHERE b.profile_id = p_profile_id AND b.is_active = TRUE
      ORDER BY b.updated_at DESC
      LIMIT 1
    ),
    active_role = CASE
      WHEN EXISTS (
        SELECT 1 FROM public.barbers b
        WHERE b.profile_id = p_profile_id AND b.is_active = TRUE
      ) THEN p.active_role
      WHEN p.active_role = 'barber' THEN 'customer'
      ELSE p.active_role
    END,
    updated_at = NOW()
  WHERE p.id = p_profile_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.resign_from_salon(p_salon_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.barbers
    WHERE salon_id = p_salon_id AND profile_id = v_uid AND is_active = TRUE
  ) THEN
    RAISE EXCEPTION 'You are not an active barber at this salon';
  END IF;

  PERFORM public._deactivate_barber_membership(p_salon_id, v_uid);

  RETURN jsonb_build_object(
    'salon_id', p_salon_id,
    'remaining_salons', COALESCE(
      (SELECT array_agg(sid) FROM public.user_barber_salon_ids(v_uid) sid),
      ARRAY[]::UUID[]
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_barber_from_salon(
  p_salon_id UUID,
  p_barber_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_barber public.barbers%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF NOT (public.owns_salon(p_salon_id) OR public.is_admin()) THEN
    RAISE EXCEPTION 'Only salon owners can remove staff';
  END IF;

  SELECT * INTO v_barber FROM public.barbers WHERE id = p_barber_id AND salon_id = p_salon_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Barber not found at this salon'; END IF;

  IF v_barber.profile_id IS NOT NULL THEN
    PERFORM public._deactivate_barber_membership(p_salon_id, v_barber.profile_id, p_barber_id);
  ELSE
    UPDATE public.barbers SET is_active = FALSE, updated_at = NOW() WHERE id = p_barber_id;
  END IF;

  RETURN jsonb_build_object('barber_id', p_barber_id, 'salon_id', p_salon_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.set_active_barber_salon(p_salon_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.barbers
    WHERE salon_id = p_salon_id AND profile_id = v_uid AND is_active = TRUE
  ) THEN
    RAISE EXCEPTION 'You are not an active barber at this salon';
  END IF;

  UPDATE public.profiles
  SET active_barber_salon_id = p_salon_id, active_role = 'barber', updated_at = NOW()
  WHERE id = v_uid;

  RETURN jsonb_build_object('active_barber_salon_id', p_salon_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.set_active_role(p_role public.user_role)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_caps TEXT[];
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_role = 'admin' THEN RAISE EXCEPTION 'Cannot switch to admin from the app'; END IF;

  v_caps := public.user_capabilities(v_uid);
  IF NOT (p_role::TEXT = ANY (v_caps)) THEN
    RAISE EXCEPTION 'You do not have the % capability', p_role;
  END IF;

  UPDATE public.profiles SET active_role = p_role, updated_at = NOW() WHERE id = v_uid;
  RETURN jsonb_build_object('active_role', p_role);
END;
$$;

CREATE OR REPLACE FUNCTION public.become_salon_owner(
  p_name TEXT,
  p_city TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_salon_id UUID;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_name IS NULL OR trim(p_name) = '' THEN RAISE EXCEPTION 'Salon name is required'; END IF;

  SELECT id INTO v_salon_id FROM public.salons WHERE owner_id = v_uid ORDER BY created_at LIMIT 1;

  IF v_salon_id IS NULL THEN
    INSERT INTO public.salons (owner_id, name, city, phone, address, verification_status)
    VALUES (v_uid, trim(p_name), NULLIF(trim(p_city), ''), NULLIF(trim(p_phone), ''), NULLIF(trim(p_address), ''), 'draft')
    RETURNING id INTO v_salon_id;

    INSERT INTO public.salon_members (salon_id, profile_id, member_role, is_active, invitation_accepted_at)
    VALUES (v_salon_id, v_uid, 'salon_owner', TRUE, NOW());
  END IF;

  UPDATE public.profiles SET active_role = 'salon_owner', updated_at = NOW() WHERE id = v_uid;
  RETURN jsonb_build_object('salon_id', v_salon_id);
END;
$$;

INSERT INTO public.salon_members (salon_id, profile_id, member_role, is_active, invitation_accepted_at)
SELECT s.id, s.owner_id, 'salon_owner', TRUE, NOW()
FROM public.salons s
WHERE NOT EXISTS (
  SELECT 1 FROM public.salon_members sm WHERE sm.salon_id = s.id AND sm.profile_id = s.owner_id
);

INSERT INTO public.salon_members (salon_id, profile_id, member_role, is_active, invitation_accepted_at)
SELECT b.salon_id, b.profile_id, 'barber', b.is_active, NOW()
FROM public.barbers b
WHERE b.profile_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.salon_members sm WHERE sm.salon_id = b.salon_id AND sm.profile_id = b.profile_id
  );

UPDATE public.profiles p
SET active_barber_salon_id = sub.salon_id
FROM (
  SELECT DISTINCT ON (profile_id) profile_id, salon_id
  FROM public.barbers
  WHERE profile_id IS NOT NULL AND is_active = TRUE
  ORDER BY profile_id, created_at
) sub
WHERE p.id = sub.profile_id AND p.active_barber_salon_id IS NULL;

GRANT EXECUTE ON FUNCTION public.invite_barber_to_salon(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_barber_invite(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resign_from_salon(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_barber_from_salon(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_active_barber_salon(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_active_role(public.user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.become_salon_owner(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_owner_capability(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_barber_capability(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_capabilities(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_barber_salon_ids(UUID) TO authenticated;
