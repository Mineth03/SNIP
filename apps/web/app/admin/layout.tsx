import { requireRole } from "@/lib/auth/require-role";
import { AppShell } from "@/components/snip/app-shell";
import { adminNav } from "@/lib/nav";

export default async function AdminLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const profile = await requireRole("admin");

  return (
    <AppShell
      title="Admin"
      description="Platform control"
      items={adminNav}
      profileName={profile.full_name}
      profileAvatar={profile.avatar_url}
      darkSidebar
      brandTitle="SNIP Admin"
      brandSubtitle="Platform"
    >
      {children}
    </AppShell>
  );
}
