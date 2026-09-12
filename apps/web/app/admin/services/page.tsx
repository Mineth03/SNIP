import { formatCurrency, formatDuration } from "@/lib/utils";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";

export const metadata = { title: "Services" };

export default async function AdminServicesPage() {
  await requireRole("admin");
  const supabase = await createClient();
  const { data: services } = await supabase
    .from("services")
    .select("*, salons(name)")
    .order("created_at", { ascending: false })
    .limit(100);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Services</h2>
        <p className="text-sm text-snip-muted">Catalog across all salons.</p>
      </div>
      {!services?.length ? (
        <EmptyState title="No services yet" />
      ) : (
        <div className="space-y-3">
          {services.map((service) => {
            const row = service as {
              id: string;
              name: string;
              category: string;
              price: number;
              duration_minutes: number;
              is_active: boolean;
              salons: { name: string } | null;
            };
            return (
              <Card key={row.id}>
                <CardContent className="flex flex-wrap items-center justify-between gap-3 p-4">
                  <div>
                    <p className="font-semibold text-snip-charcoal">{row.name}</p>
                    <p className="text-sm text-snip-muted">
                      {row.salons?.name ?? "Salon"} · {formatDuration(row.duration_minutes)} ·{" "}
                      {formatCurrency(row.price)}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <Badge variant="outline" className="capitalize">
                      {row.category}
                    </Badge>
                    <Badge variant={row.is_active ? "success" : "danger"}>
                      {row.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
