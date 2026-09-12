import { createClient } from "@/lib/supabase/server";
import type { Salon } from "@/types/database";

export async function getOwnedSalon(ownerId: string): Promise<Salon | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("salons")
    .select("*")
    .eq("owner_id", ownerId)
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  return (data as Salon | null) ?? null;
}
