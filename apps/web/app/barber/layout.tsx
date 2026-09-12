import { requireRole } from "@/lib/auth/require-role";
import { AppShell } from "@/components/snip/app-shell";
import { barberNav } from "@/lib/nav";

export default async function BarberLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const profile = await requireRole(["barber", "admin"]);

  return (
    <AppShell
      title="Barber"
      description="Your chair, your schedule"
      items={barberNav}
      profileName={profile.full_name}
      profileAvatar={profile.avatar_url}
      brandSubtitle="Barber"
    >
      {children}
    </AppShell>
  );
}
