import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
import { sendTemplatedEmail } from "@/lib/email/resend";
import type { Booking } from "@/types/database";

const schema = z.object({
  salonId: z.uuid(),
  serviceId: z.uuid(),
  appointmentStart: z.string().min(1),
  barberId: z.uuid().optional().nullable(),
  customerNotes: z.string().optional().nullable(),
  customerId: z.uuid().optional().nullable(),
  isWalkIn: z.boolean().optional(),
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

    const { data, error } = await supabase.rpc("create_booking", {
      p_salon_id: body.salonId,
      p_service_id: body.serviceId,
      p_appointment_start: body.appointmentStart,
      p_barber_id: body.barberId ?? null,
      p_customer_id: body.customerId ?? null,
      p_customer_notes: body.customerNotes ?? null,
      p_is_walk_in: body.isWalkIn ?? false,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    const booking = data as Booking;

    const [{ data: salon }, { data: service }, { data: profile }] =
      await Promise.all([
        supabase.from("salons").select("name").eq("id", body.salonId).maybeSingle(),
        supabase
          .from("services")
          .select("name")
          .eq("id", body.serviceId)
          .maybeSingle(),
        supabase
          .from("profiles")
          .select("email, full_name")
          .eq("id", booking.customer_id)
          .maybeSingle(),
      ]);

    if (profile?.email) {
      await sendTemplatedEmail({
        to: profile.email,
        template: "booking_confirmation",
        data: {
          name: profile.full_name ?? "there",
          salonName: salon?.name ?? "your salon",
          serviceName: service?.name ?? "your service",
          when: new Date(booking.appointment_start).toLocaleString(),
        },
      }).catch(() => undefined);
    }

    return NextResponse.json({ booking });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to create booking";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
