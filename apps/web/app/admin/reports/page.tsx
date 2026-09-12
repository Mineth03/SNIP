import { formatCurrency } from "@/lib/utils";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import { MetricCard } from "@/components/ui/metric-card";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export const metadata = { title: "Reports" };

export default async function AdminReportsPage() {
  await requireRole("admin");
  const supabase = await createClient();

  const [{ data: bookings }, { count: cancelled }, { count: completed }] =
    await Promise.all([
      supabase.from("bookings").select("price, status"),
      supabase
        .from("bookings")
        .select("*", { count: "exact", head: true })
        .eq("status", "cancelled"),
      supabase
        .from("bookings")
        .select("*", { count: "exact", head: true })
        .eq("status", "completed"),
    ]);

  const gmv =
    bookings?.reduce((sum, row) => sum + Number(row.price || 0), 0) ?? 0;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Reports</h2>
        <p className="text-sm text-snip-muted">
          High-level marketplace performance metrics.
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <MetricCard label="Gross booking value" value={formatCurrency(gmv)} />
        <MetricCard label="Completed" value={completed ?? 0} />
        <MetricCard label="Cancelled" value={cancelled ?? 0} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Notes</CardTitle>
        </CardHeader>
        <CardContent className="text-sm text-snip-muted">
          Export-ready analytics can plug into this page later. Current metrics are
          computed live from Supabase booking rows.
        </CardContent>
      </Card>
    </div>
  );
}
