import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
import type { Booking } from "@/types/database";

const schema = z.object({
  qrToken: z.string().min(4, "Ticket code or QR UUID is required"),
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

    let tokenToUse = body.qrToken.trim();

    // If a short ticket ID like "SNIP784629" or "784629" was entered:
    const isFullUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        tokenToUse,
      );

    if (!isFullUuid) {
      const cleanHex = tokenToUse.replace(/^SNIP/i, "").trim().toLowerCase();
      const { data: matched } = await supabase
        .from("bookings")
        .select("qr_token")
        .ilike("qr_token", `${cleanHex}%`)
        .limit(1)
        .maybeSingle();

      if (matched?.qr_token) {
        tokenToUse = matched.qr_token;
      }
    }

    const { data, error } = await supabase.rpc("check_in_with_qr", {
      p_qr_token: tokenToUse,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    const booking = data as Booking;

    // Fetch details for rich response
    const [{ data: service }, { data: profile }, { data: barber }] =
      await Promise.all([
        supabase
          .from("services")
          .select("name")
          .eq("id", booking.service_id)
          .maybeSingle(),
        supabase
          .from("profiles")
          .select("full_name")
          .eq("id", booking.customer_id)
          .maybeSingle(),
        supabase
          .from("barbers")
          .select("display_name")
          .eq("id", booking.barber_id)
          .maybeSingle(),
      ]);

    return NextResponse.json({
      booking: {
        ...booking,
        serviceName: service?.name ?? "Service",
        customerName: profile?.full_name ?? "Guest",
        barberName: barber?.display_name ?? "Stylist",
      },
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to check in";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
