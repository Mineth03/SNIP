import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import type { ServiceCategory } from "@/types/database";

export async function GET(req: NextRequest) {
  const searchParams = req.nextUrl.searchParams;
  const latStr = searchParams.get("lat");
  const lngStr = searchParams.get("lng");
  const radiusStr = searchParams.get("radius");
  const category = searchParams.get("category") as ServiceCategory | null;
  const limitStr = searchParams.get("limit");

  if (!latStr || !lngStr) {
    return NextResponse.json(
      { error: "Latitude ('lat') and longitude ('lng') parameters are required." },
      { status: 400 }
    );
  }

  const latitude = parseFloat(latStr);
  const longitude = parseFloat(lngStr);
  const radiusKm = radiusStr ? parseFloat(radiusStr) : 50;
  const limit = limitStr ? parseInt(limitStr, 10) : 20;

  if (isNaN(latitude) || isNaN(longitude)) {
    return NextResponse.json(
      { error: "Invalid coordinates provided." },
      { status: 400 }
    );
  }

  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("get_nearby_salons", {
      p_latitude: latitude,
      p_longitude: longitude,
      p_radius_km: radiusKm,
      p_category: category || null,
      p_limit: limit,
      p_offset: 0,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({
      salons: data ?? [],
      userCoordinates: { latitude, longitude },
      radiusKm,
    });
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Failed to fetch nearby salons" },
      { status: 500 }
    );
  }
}
