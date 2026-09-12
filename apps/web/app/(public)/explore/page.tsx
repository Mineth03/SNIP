import { Search } from "lucide-react";
import { SalonCard } from "@/components/snip/salon-card";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { createClient } from "@/lib/supabase/server";
import type { Salon, ServiceCategory } from "@/types/database";

export const metadata = { title: "Explore salons" };

export default async function ExplorePage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; city?: string; category?: string }>;
}) {
  const params = await searchParams;
  const supabase = await createClient();

  let salons: Salon[] = [];
  try {
    const { data, error } = await supabase.rpc("search_salons", {
      p_query: params.q || null,
      p_city: params.city || null,
      p_category: (params.category as ServiceCategory) || null,
      p_verified_only: true,
      p_limit: 24,
      p_offset: 0,
    });
    if (!error && data) salons = data as Salon[];
  } catch {
    salons = [];
  }

  return (
    <div className="snip-container py-10 md:py-14">
      <div className="max-w-2xl">
        <h1 className="text-3xl font-bold tracking-tight text-snip-charcoal">
          Explore salons
        </h1>
        <p className="mt-2 text-snip-muted">
          Find verified salons, compare services, and book your next appointment.
        </p>
      </div>

      <form className="mt-8 grid gap-3 rounded-lg border border-snip-border bg-white p-4 shadow-snip-sm md:grid-cols-[1fr_220px_auto]">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-snip-muted" />
          <Input
            name="q"
            defaultValue={params.q}
            placeholder="Search by salon or style"
            className="pl-9"
          />
        </div>
        <Input
          name="city"
          defaultValue={params.city}
          placeholder="City"
        />
        <button
          type="submit"
          className="h-11 rounded-md bg-snip-primary px-5 text-sm font-semibold text-white hover:bg-snip-primary-hover"
        >
          Search
        </button>
      </form>

      <div className="mt-8">
        {salons.length === 0 ? (
          <EmptyState
            icon={Search}
            title="No salons found"
            description="Try another city or search term. Verified salons will appear here once available."
            actionLabel="Clear filters"
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
    </div>
  );
}
