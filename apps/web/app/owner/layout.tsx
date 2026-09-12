import { requireRole } from "@/lib/auth/require-role";
import { AppShell } from "@/components/snip/app-shell";
import { ownerNav } from "@/lib/nav";

export default async function OwnerLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const profile = await requireRole(["salon_owner", "admin"]);

  return (
    <AppShell
      title="Owner"
      description="Salon operations"
      items={ownerNav}
      profileName={profile.full_name}
      profileAvatar={profile.avatar_url}
      brandSubtitle="Salon Owner"
    >
      {children}
    </AppShell>
  );
}
