import { Suspense } from "react";
import { Search } from "lucide-react";
import { SalonCard } from "@/components/snip/salon-card";
import { ExploreSearchFilters } from "@/components/snip/explore-search-filters";
import { EmptyState } from "@/components/ui/empty-state";
import { createClient } from "@/lib/supabase/server";
import type { Salon, ServiceCategory } from "@/types/database";

export const metadata = { title: "Explore Salons | SNIP" };

export default async function ExplorePage({
  searchParams,
}: {
  searchParams: Promise<{
    q?: string;
    city?: string;
    category?: string;
    lat?: string;
    lng?: string;
    radius?: string;
  }>;
}) {
  const params = await searchParams;
  const supabase = await createClient();

  const isNearbySearch = Boolean(params.lat && params.lng);
  let salons: Salon[] = [];

  try {
    if (isNearbySearch) {
      const lat = parseFloat(params.lat!);
      const lng = parseFloat(params.lng!);
      const radiusKm = params.radius ? parseFloat(params.radius) : 60;

      const { data, error } = await supabase.rpc("get_nearby_salons", {
        p_latitude: lat,
        p_longitude: lng,
        p_radius_km: radiusKm,
        p_category: (params.category as ServiceCategory) || null,
        p_limit: 30,
        p_offset: 0,
      });

      if (!error && data) {
        // If search term is also provided, filter locally or let query refine
        if (params.q) {
          const qLower = params.q.toLowerCase();
          salons = (data as Salon[]).filter(
            (s) =>
              s.name.toLowerCase().includes(qLower) ||
              s.city?.toLowerCase().includes(qLower) ||
              s.description?.toLowerCase().includes(qLower)
          );
        } else {
          salons = data as Salon[];
        }
      }
    } else {
      const { data, error } = await supabase.rpc("search_salons", {
        p_query: params.q || null,
        p_city: params.city || null,
        p_category: (params.category as ServiceCategory) || null,
        p_verified_only: true,
        p_limit: 30,
        p_offset: 0,
      });
      if (!error && data) salons = data as Salon[];
    }
  } catch {
    salons = [];
  }

  return (
    <div className="snip-container py-10 md:py-14 space-y-8">
      <div className="max-w-2xl">
        <h1 className="text-3xl font-extrabold tracking-tight text-snip-charcoal">
          Explore Salons
        </h1>
        <p className="mt-1 text-sm text-snip-muted">
          Find verified salons near your current location, compare treatments, and book guaranteed time slots.
        </p>
      </div>

      <Suspense fallback={<div className="h-20 animate-pulse rounded-2xl bg-slate-100" />}>
        <ExploreSearchFilters />
      </Suspense>

      <div className="pt-2">
        {salons.length === 0 ? (
          <EmptyState
            icon={Search}
            title="No salons found nearby"
            description="Try increasing your search radius, selecting another city, or clearing treatment filters."
            actionLabel="Reset All Filters"
            actionHref="/explore"
          />
        ) : (
          <div className="space-y-4">
            <div className="flex items-center justify-between text-xs font-semibold text-snip-muted">
              <span>
                Found {salons.length} {salons.length === 1 ? "salon" : "salons"}
                {isNearbySearch ? " nearby" : ""}
              </span>
              {isNearbySearch && (
                <span className="text-snip-teal">Sorted by distance</span>
              )}
            </div>

            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
              {salons.map((salon) => (
                <SalonCard key={salon.id} salon={salon} />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
