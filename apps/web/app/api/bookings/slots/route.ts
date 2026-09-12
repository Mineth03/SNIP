import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import type { AvailableSlot } from "@/types/database";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const salonId = searchParams.get("salonId");
    const serviceId = searchParams.get("serviceId");
    const date = searchParams.get("date");
    const barberId = searchParams.get("barberId");

    if (!salonId || !serviceId || !date) {
      return NextResponse.json(
        { error: "salonId, serviceId, and date are required" },
        { status: 400 },
      );
    }

    const supabase = await createClient();
    const { data, error } = await supabase.rpc("get_available_slots", {
      p_salon_id: salonId,
      p_service_id: serviceId,
      p_barber_id: barberId || null,
      p_date: date,
      p_slot_interval_minutes: 15,
      p_buffer_minutes: 0,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ slots: (data as AvailableSlot[]) ?? [] });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to load slots";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
