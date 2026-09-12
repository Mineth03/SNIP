import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
import type { Booking, BookingStatus } from "@/types/database";

const schema = z.object({
  bookingId: z.uuid(),
  toStatus: z.enum([
    "pending",
    "confirmed",
    "checked_in",
    "in_progress",
    "completed",
    "cancelled",
    "no_show",
  ]),
  note: z.string().optional().nullable(),
});

export async function POST(request: Request) {
  try {
    const body = schema.parse(await request.json());
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Authentication required" }, { status: 401 });
    }

    const { data, error } = await supabase.rpc("transition_booking_status", {
      p_booking_id: body.bookingId,
      p_to_status: body.toStatus as BookingStatus,
      p_note: body.note ?? null,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ booking: data as Booking });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to transition status";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
