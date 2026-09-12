import { redirect } from "next/navigation";
import { getProfile } from "@/lib/auth/get-profile";
import { getRoleHome } from "@/lib/auth/roles";
import type { Profile, UserRole } from "@/types/database";

export async function requireUser(): Promise<Profile> {
  const profile = await getProfile();
  if (!profile) {
    redirect("/login");
  }
  return profile;
}

export async function requireRole(
  allowed: UserRole | UserRole[],
): Promise<Profile> {
  const profile = await requireUser();
  const roles = Array.isArray(allowed) ? allowed : [allowed];

  if (!roles.includes(profile.role) && profile.role !== "admin") {
    redirect(getRoleHome(profile.role));
  }

  return profile;
}
