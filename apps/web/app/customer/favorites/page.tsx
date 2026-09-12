import { Heart } from "lucide-react";
import { SalonCard } from "@/components/snip/salon-card";
import { EmptyState } from "@/components/ui/empty-state";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { Salon } from "@/types/database";

export const metadata = { title: "Favorites" };

export default async function CustomerFavoritesPage() {
  const profile = await requireRole(["customer", "admin"]);
  const supabase = await createClient();

  const { data } = await supabase
    .from("favorites")
    .select("salon_id, salons(*)")
    .eq("customer_id", profile.id)
    .order("created_at", { ascending: false });

  const salons =
    data
      ?.map((row) => (row as unknown as { salons: Salon | null }).salons)
      .filter((salon): salon is Salon => Boolean(salon)) ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Favorites</h2>
        <p className="text-sm text-snip-muted">
          Salons you love, ready for quick rebooking.
        </p>
      </div>
      {salons.length === 0 ? (
        <EmptyState
          icon={Heart}
          title="No favorites yet"
          description="Save salons from their profile pages to see them here."
          actionLabel="Explore salons"
          actionHref="/explore"
        />
      ) : (
        <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
          {salons.map((salon) => (
            <SalonCard key={salon.id} salon={salon} />
          ))}
        </div>
      )}
    </div>
  );
}
