import { requireRole } from "@/lib/auth/require-role";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export const metadata = { title: "Admin settings" };

export default async function AdminSettingsPage() {
  const profile = await requireRole("admin");

  return (
    <div className="mx-auto max-w-xl space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Settings</h2>
        <p className="text-sm text-snip-muted">Platform configuration overview.</p>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Admin account</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm text-snip-muted">
          <p>
            Signed in as <span className="font-medium text-snip-charcoal">{profile.full_name}</span>
          </p>
          <p>{profile.email}</p>
          <p>
            Email delivery uses Resend when <code>RESEND_API_KEY</code> is configured.
            Supabase URL and keys must be set for auth and data access.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
