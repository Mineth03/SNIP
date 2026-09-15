import { createClient } from "@/lib/supabase/server";
import type { AppCapability } from "@/lib/auth/roles";
import type { Profile, UserRole } from "@/types/database";

export type ProfileWithCapabilities = Profile & {
  capabilities: AppCapability[];
  active_role: UserRole;
  active_barber_salon_id: string | null;
};

export async function getUserCapabilities(
  userId?: string,
): Promise<AppCapability[]> {
  const supabase = await createClient();
  const uid =
    userId ??
    (
      await supabase.auth.getUser()
    ).data.user?.id;

  if (!uid) return [];

  const { data, error } = await supabase.rpc("user_capabilities", {
    p_uid: uid,
  });

  if (!error && Array.isArray(data)) {
    return data as AppCapability[];
  }

  // Fallback if RPC not applied yet
  const caps: AppCapability[] = ["customer"];
  const [{ count: salonCount }, { count: barberCount }, { data: profile }] =
    await Promise.all([
      supabase
        .from("salons")
        .select("id", { count: "exact", head: true })
        .eq("owner_id", uid)
        .eq("is_active", true),
      supabase
        .from("barbers")
        .select("id", { count: "exact", head: true })
        .eq("profile_id", uid)
        .eq("is_active", true),
      supabase.from("profiles").select("role").eq("id", uid).maybeSingle(),
    ]);

  if ((salonCount ?? 0) > 0) caps.push("salon_owner");
  if ((barberCount ?? 0) > 0) caps.push("barber");
  if ((profile as { role?: string } | null)?.role === "admin") caps.push("admin");
  return caps;
}

export async function getProfileWithCapabilities(): Promise<ProfileWithCapabilities | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  if (error || !data) return null;

  const profile = data as Profile & {
    active_role?: UserRole;
    active_barber_salon_id?: string | null;
  };

  const capabilities = await getUserCapabilities(user.id);

  return {
    ...profile,
    active_role: profile.active_role ?? profile.role ?? "customer",
    active_barber_salon_id: profile.active_barber_salon_id ?? null,
    capabilities,
  };
}
