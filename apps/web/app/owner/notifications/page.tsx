import { Bell } from "lucide-react";
import { EmptyState } from "@/components/ui/empty-state";
import { Card, CardContent } from "@/components/ui/card";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import { format } from "date-fns";

export const metadata = { title: "Notifications" };

export default async function OwnerNotificationsPage() {
  const profile = await requireRole(["salon_owner", "admin"]);
  const supabase = await createClient();
  const { data } = await supabase
    .from("notifications")
    .select("*")
    .eq("user_id", profile.id)
    .order("created_at", { ascending: false })
    .limit(40);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Notifications</h2>
        <p className="text-sm text-snip-muted">Stay on top of salon activity.</p>
      </div>
      {!data?.length ? (
        <EmptyState
          icon={Bell}
          title="You’re all caught up"
          description="New booking and verification alerts will show here."
        />
      ) : (
        <div className="space-y-3">
          {data.map((item) => (
            <Card key={item.id} className={item.is_read ? "opacity-80" : ""}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-semibold text-snip-charcoal">{item.title}</p>
                    <p className="mt-1 text-sm text-snip-muted">{item.message}</p>
                  </div>
                  <p className="shrink-0 text-xs text-snip-muted">
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
