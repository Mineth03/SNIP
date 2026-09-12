import Link from "next/link";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import { StatusBadge } from "@/components/ui/status-badge";
import { Card, CardContent } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import type { SalonVerificationStatus } from "@/types/database";

export const metadata = { title: "Salons" };

export default async function AdminSalonsPage() {
  await requireRole("admin");
  const supabase = await createClient();
  const { data: salons } = await supabase
    .from("salons")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Salons</h2>
        <p className="text-sm text-snip-muted">Directory of all salon businesses.</p>
      </div>
      {!salons?.length ? (
        <EmptyState title="No salons yet" />
      ) : (
        <div className="space-y-3">
          {salons.map((salon) => (
            <Card key={salon.id}>
              <CardContent className="flex flex-wrap items-center justify-between gap-3 p-4">
                <div>
                  <Link
                    href={`/salons/${salon.slug}`}
                    className="font-semibold text-snip-charcoal hover:text-snip-teal"
                  >
                    {salon.name}
                  </Link>
                  <p className="text-sm text-snip-muted">
                    {salon.city ?? "City TBA"} · /{salon.slug}
                  </p>
                </div>
                <StatusBadge
                  status={salon.verification_status as SalonVerificationStatus}
                  kind="verification"
                />
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
