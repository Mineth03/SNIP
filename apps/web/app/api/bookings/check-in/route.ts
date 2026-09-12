import { NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
import type { Booking } from "@/types/database";

const schema = z.object({
  qrToken: z.uuid(),
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

    const { data, error } = await supabase.rpc("check_in_with_qr", {
      p_qr_token: body.qrToken,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ booking: data as Booking });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to check in";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
