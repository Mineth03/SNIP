import { requireRole } from "@/lib/auth/require-role";
import { AppShell } from "@/components/snip/app-shell";
import { customerNav } from "@/lib/nav";

export default async function CustomerLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const profile = await requireRole(["customer", "admin"]);

  return (
    <AppShell
      title="Customer"
      description="Your bookings and favorites"
      items={customerNav}
      profileName={profile.full_name}
      profileAvatar={profile.avatar_url}
      brandSubtitle="Customer"
    >
      {children}
    </AppShell>
  );
}
