import type { UserRole } from "@/types/database";

export type AppCapability = "customer" | "salon_owner" | "barber" | "admin";

export const ROLE_HOME: Record<UserRole, string> = {
  customer: "/customer",
  salon_owner: "/owner",
  barber: "/barber",
  admin: "/admin",
};

/** @deprecated Prefer capability-aware helpers */
export const PROTECTED_PREFIXES: { prefix: string; roles: UserRole[] }[] = [
  { prefix: "/customer", roles: ["customer", "admin"] },
  { prefix: "/owner", roles: ["salon_owner", "admin"] },
  { prefix: "/barber", roles: ["barber", "admin"] },
  { prefix: "/admin", roles: ["admin"] },
];

export function getRoleHome(role: UserRole): string {
  return ROLE_HOME[role] ?? "/customer";
}

export function getActiveRoleHome(activeRole: UserRole | null | undefined): string {
  return getRoleHome(activeRole ?? "customer");
}

export function roleLabel(role: UserRole): string {
  switch (role) {
    case "salon_owner":
      return "Salon Owner";
    case "barber":
      return "Barber";
    case "admin":
      return "Admin";
    default:
      return "Customer";
  }
}

export function canAccessPathWithCapabilities(
  pathname: string,
  capabilities: AppCapability[],
): boolean {
  if (capabilities.includes("admin")) return true;

  if (pathname.startsWith("/admin")) {
    return capabilities.includes("admin");
  }
  if (pathname.startsWith("/owner")) {
    return capabilities.includes("salon_owner");
  }
  if (pathname.startsWith("/barber")) {
    return capabilities.includes("barber");
  }
  if (pathname.startsWith("/customer")) {
    return true;
  }
  return true;
}

/** @deprecated Prefer canAccessPathWithCapabilities */
export function canAccessPath(pathname: string, role: UserRole): boolean {
  const caps: AppCapability[] =
    role === "admin"
      ? ["customer", "salon_owner", "barber", "admin"]
      : role === "salon_owner"
        ? ["customer", "salon_owner"]
        : role === "barber"
          ? ["customer", "barber"]
          : ["customer"];
  return canAccessPathWithCapabilities(pathname, caps);
}

export function resolveHomeFromCapabilities(
  capabilities: AppCapability[],
  preferred?: UserRole | null,
): string {
  if (preferred && capabilities.includes(preferred as AppCapability)) {
    return getRoleHome(preferred);
  }
  if (capabilities.includes("admin")) return "/admin";
  if (capabilities.includes("salon_owner") && preferred === "salon_owner") {
    return "/owner";
  }
  if (capabilities.includes("barber") && preferred === "barber") {
    return "/barber";
  }
  return "/customer";
}
