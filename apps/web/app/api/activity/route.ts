import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import type { ServiceCategory, UserActivityType } from "@/types/database";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { activityType, salonId, serviceId, category, metadata } = body as {
      activityType?: UserActivityType;
      salonId?: string;
      serviceId?: string;
      category?: ServiceCategory;
      metadata?: Record<string, unknown>;
    };

    if (!activityType) {
      return NextResponse.json({ error: "Missing activityType" }, { status: 400 });
    }

    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ ok: false, reason: "anonymous" });
    }

    const { data, error } = await supabase.rpc("log_user_activity", {
      p_activity_type: activityType,
      p_salon_id: salonId ?? null,
      p_service_id: serviceId ?? null,
      p_category: category ?? null,
      p_metadata: metadata ?? {},
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ ok: true, activityId: data });
  } catch (err) {
    return NextResponse.json(
      { error: (err as Error).message },
      { status: 500 },
    );
  }
}
