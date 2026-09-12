import type { UserRole } from "@/types/database";

export const ROLE_HOME: Record<UserRole, string> = {
  customer: "/customer",
  salon_owner: "/owner",
  barber: "/barber",
  admin: "/admin",
};

export const PROTECTED_PREFIXES: { prefix: string; roles: UserRole[] }[] = [
  { prefix: "/customer", roles: ["customer", "admin"] },
  { prefix: "/owner", roles: ["salon_owner", "admin"] },
  { prefix: "/barber", roles: ["barber", "admin"] },
  { prefix: "/admin", roles: ["admin"] },
];

export function getRoleHome(role: UserRole): string {
  return ROLE_HOME[role] ?? "/customer";
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

export function canAccessPath(pathname: string, role: UserRole): boolean {
  const rule = PROTECTED_PREFIXES.find((item) =>
    pathname === item.prefix || pathname.startsWith(`${item.prefix}/`),
  );
  if (!rule) return true;
  return rule.roles.includes(role);
}
