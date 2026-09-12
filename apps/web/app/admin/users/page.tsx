import { roleLabel } from "@/lib/auth/roles";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import { Avatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import type { UserRole } from "@/types/database";

export const metadata = { title: "Users" };

export default async function AdminUsersPage() {
  await requireRole("admin");
  const supabase = await createClient();
  const { data: users } = await supabase
    .from("profiles")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Users</h2>
        <p className="text-sm text-snip-muted">All SNIP profiles on the platform.</p>
      </div>
      {!users?.length ? (
        <EmptyState title="No users yet" />
      ) : (
        <div className="space-y-3">
          {users.map((user) => (
            <Card key={user.id}>
              <CardContent className="flex flex-wrap items-center justify-between gap-3 p-4">
                <div className="flex items-center gap-3">
                  <Avatar name={user.full_name} src={user.avatar_url} />
                  <div>
                    <p className="font-semibold text-snip-charcoal">{user.full_name}</p>
                    <p className="text-sm text-snip-muted">{user.email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant="primary">{roleLabel(user.role as UserRole)}</Badge>
                  <Badge variant={user.is_active ? "success" : "danger"}>
                    {user.is_active ? "Active" : "Inactive"}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
