import { createClient } from "@/lib/supabase/server";
import type { Profile } from "@/types/database";

export type ActiveBarberContext = {
  barberId: string;
  salonId: string;
  displayName: string;
  salonName: string | null;
  memberships: { salonId: string; salonName: string; barberId: string }[];
};

export async function getActiveBarberContext(
  profile: Profile,
): Promise<ActiveBarberContext | null> {
  const supabase = await createClient();

  const { data: rows } = await supabase
    .from("barbers")
    .select("id, display_name, salon_id, salons(name)")
    .eq("profile_id", profile.id)
    .eq("is_active", true)
    .order("created_at", { ascending: true });

  if (!rows?.length) return null;

  const memberships = rows.map((row) => {
    const salon = row.salons as unknown as { name: string } | null;
    return {
      salonId: row.salon_id as string,
      salonName: salon?.name ?? "Salon",
      barberId: row.id as string,
    };
  });

  const preferredSalonId = profile.active_barber_salon_id;
  const active =
    memberships.find((m) => m.salonId === preferredSalonId) ?? memberships[0];

  const activeRow = rows.find((r) => r.id === active.barberId)!;

  return {
    barberId: active.barberId,
    salonId: active.salonId,
    displayName: (activeRow.display_name as string) ?? profile.full_name,
    salonName: active.salonName,
    memberships,
  };
}
