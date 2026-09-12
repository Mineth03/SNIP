import { notFound } from "next/navigation";
import { Suspense } from "react";
import { BookingFlow } from "@/components/snip/booking-flow";
import { EmptyState } from "@/components/ui/empty-state";
import { LoadingSkeleton } from "@/components/ui/loading-skeleton";
import { createClient } from "@/lib/supabase/server";
import type { Barber, Salon, Service } from "@/types/database";

export const metadata = { title: "Book appointment" };

export default async function BookSalonPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const supabase = await createClient();

  const { data: salon } = await supabase
    .from("salons")
    .select("*")
    .eq("slug", slug)
    .maybeSingle();

  if (!salon) notFound();
  const salonRow = salon as Salon;

  const [{ data: services }, { data: barbers }] = await Promise.all([
    supabase
      .from("services")
      .select("*")
      .eq("salon_id", salonRow.id)
      .eq("is_active", true)
      .order("name"),
    supabase
      .from("barbers")
      .select("*")
      .eq("salon_id", salonRow.id)
      .eq("is_active", true)
      .order("display_name"),
  ]);

  if (!services?.length) {
    return (
      <div className="snip-container py-10">
        <EmptyState
          title="Nothing to book yet"
          description="This salon hasn’t published bookable services."
          actionLabel="Back to salon"
          actionHref={`/salons/${slug}`}
        />
      </div>
    );
  }

  return (
    <div className="snip-container py-10 md:py-12">
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight text-snip-charcoal">
          Book at {salonRow.name}
        </h1>
        <p className="mt-2 text-snip-muted">
          Choose a service, stylist, and time that works for you.
        </p>
      </div>
      <Suspense fallback={<LoadingSkeleton rows={4} />}>
        <BookingFlow
          salonId={salonRow.id}
          salonName={salonRow.name}
          slug={slug}
          services={services as Service[]}
          barbers={(barbers as Barber[]) ?? []}
        />
      </Suspense>
    </div>
  );
}
