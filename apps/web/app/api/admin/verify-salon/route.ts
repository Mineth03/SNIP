import { NextResponse } from "next/server";
import { z } from "zod";
import { getProfile } from "@/lib/auth/get-profile";
import { createClient } from "@/lib/supabase/server";
import { sendTemplatedEmail } from "@/lib/email/resend";
import type { Salon } from "@/types/database";

const schema = z.object({
  salonId: z.uuid(),
  decision: z.enum(["approved", "rejected", "changes_requested"]),
  notes: z.string().optional().nullable(),
});

export async function POST(request: Request) {
  try {
    const admin = await getProfile();
    if (!admin || admin.role !== "admin") {
      return NextResponse.json({ error: "Admin access required" }, { status: 403 });
    }

    const body = schema.parse(await request.json());
    const supabase = await createClient();

    const status =
      body.decision === "approved"
        ? "verified"
        : body.decision === "rejected"
          ? "rejected"
          : "pending_verification";

    const { data: salon, error } = await supabase
      .from("salons")
      .update({
        verification_status: status,
        rejection_reason:
          body.decision === "approved" ? null : body.notes ?? null,
      })
      .eq("id", body.salonId)
      .select("*")
      .maybeSingle();

    if (error || !salon) {
      return NextResponse.json(
        { error: error?.message ?? "Salon not found" },
        { status: 400 },
      );
    }

    const salonRow = salon as Salon;

    await supabase.from("salon_verification_requests").insert({
      salon_id: body.salonId,
      submitted_by: salonRow.owner_id,
      decision: body.decision,
      reviewed_by: admin.id,
      notes: body.notes ?? null,
      reason: body.notes ?? null,
      reviewed_at: new Date().toISOString(),
    });

    const { data: owner } = await supabase
      .from("profiles")
      .select("email, full_name")
      .eq("id", salonRow.owner_id)
      .maybeSingle();

    if (owner?.email) {
      await sendTemplatedEmail({
        to: owner.email,
        template:
          body.decision === "approved" ? "salon_approved" : "salon_rejected",
        data: {
          name: owner.full_name ?? "there",
          salonName: salonRow.name,
          reason: body.notes ?? "",
          ctaUrl: `${process.env.NEXT_PUBLIC_APP_URL ?? ""}/owner/salon`,
        },
      }).catch(() => undefined);
    }

    return NextResponse.json({ ok: true, salon: salonRow });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to verify salon";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
