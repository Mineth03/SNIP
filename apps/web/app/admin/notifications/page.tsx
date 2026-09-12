import { format } from "date-fns";
import { Bell } from "lucide-react";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import { Card, CardContent } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";

export const metadata = { title: "Admin notifications" };

export default async function AdminNotificationsPage() {
  const profile = await requireRole("admin");
  const supabase = await createClient();
  const { data } = await supabase
    .from("notifications")
    .select("*")
    .eq("user_id", profile.id)
    .order("created_at", { ascending: false })
    .limit(50);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Notifications</h2>
        <p className="text-sm text-snip-muted">Platform alerts for admins.</p>
      </div>
      {!data?.length ? (
        <EmptyState icon={Bell} title="No notifications" />
      ) : (
        <div className="space-y-3">
          {data.map((item) => (
            <Card key={item.id}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-semibold text-snip-charcoal">{item.title}</p>
                    <p className="mt-1 text-sm text-snip-muted">{item.message}</p>
                  </div>
                  <p className="text-xs text-snip-muted">
                    {format(new Date(item.created_at), "MMM d · h:mm a")}
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
