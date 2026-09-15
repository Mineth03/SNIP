import { redirect } from "next/navigation";
import { getProfileWithCapabilities } from "@/lib/auth/capabilities";
import {
  getActiveRoleHome,
  type AppCapability,
} from "@/lib/auth/roles";
import type { Profile, UserRole } from "@/types/database";

export async function requireUser(): Promise<Profile> {
  const profile = await getProfileWithCapabilities();
  if (!profile) {
    redirect("/login");
  }
  return profile;
}

export async function requireRole(
  allowed: UserRole | UserRole[],
): Promise<Profile> {
  const profile = await getProfileWithCapabilities();
  if (!profile) {
    redirect("/login");
  }

  const roles = (Array.isArray(allowed) ? allowed : [allowed]) as AppCapability[];
  const caps = profile.capabilities;

  if (caps.includes("admin")) {
    return profile;
  }

  const allowedOk = roles.some((role) => {
    if (role === "customer") return true;
    return caps.includes(role);
  });

  if (!allowedOk) {
    redirect(getActiveRoleHome(profile.active_role));
  }

  return profile;
}

export async function requireCapability(
  required: AppCapability | AppCapability[],
): Promise<Profile> {
  const profile = await getProfileWithCapabilities();
  if (!profile) {
    redirect("/login");
  }

  const needed = Array.isArray(required) ? required : [required];
  if (profile.capabilities.includes("admin")) return profile;

  if (!needed.some((c) => profile.capabilities.includes(c) || c === "customer")) {
    redirect(getActiveRoleHome(profile.active_role));
  }

  return profile;
}
