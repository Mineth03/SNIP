import Link from "next/link";
import { CalendarDays, Search } from "lucide-react";
import { BookingCard } from "@/components/snip/booking-card";
import { CustomerRecommendations } from "@/components/snip/customer-recommendations";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { MetricCard } from "@/components/ui/metric-card";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";

export const metadata = { title: "Customer home" };

export default async function CustomerHomePage() {
  const profile = await requireRole(["customer", "admin"]);
  const supabase = await createClient();

  const [
    { data: bookings },
    { data: recommendations },
    { data: recentActivities },
  ] = await Promise.all([
    supabase
      .from("bookings")
      .select(
        "id, appointment_start, price, status, salons(name), services(name), barbers(display_name)",
      )
      .eq("customer_id", profile.id)
      .order("appointment_start", { ascending: true })
      .limit(5),
    supabase.rpc("get_personalized_recommendations", {
      p_user_id: profile.id,
      p_latitude: 6.8918,
      p_longitude: 79.8732,
      p_limit: 6,
    }),
    supabase.rpc("get_user_recent_activity", {
      p_user_id: profile.id,
      p_limit: 4,
    }),
  ]);

  const upcoming =
    bookings?.filter((b) =>
      ["pending", "confirmed", "checked_in", "in_progress"].includes(b.status),
    ) ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold text-snip-charcoal">
            Hello, {profile.full_name.split(" ")[0]}
          </h2>
          <p className="text-sm text-snip-muted">
            Ready for your next look? Book a salon in minutes.
          </p>
        </div>
        <Link href="/explore">
          <Button type="button">
            <Search className="h-4 w-4" />
            Find a salon
          </Button>
        </Link>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <MetricCard
          label="Upcoming"
          value={upcoming.length}
          icon={CalendarDays}
          hint="Confirmed appointments"
        />
        <MetricCard
          label="City"
          value={profile.city ?? "Not set"}
          hint="Update in profile"
        />
        <MetricCard
          label="Quick action"
          value="Explore"
          hint="Browse verified salons"
        />
      </div>

      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-snip-charcoal">
            Upcoming bookings
          </h3>
          <Link href="/customer/bookings" className="text-sm font-medium text-snip-teal">
            View all
          </Link>
        </div>
        {upcoming.length === 0 ? (
          <EmptyState
            icon={CalendarDays}
            title="No upcoming bookings"
            description="Explore salons and book your next appointment."
            actionLabel="Explore salons"
            actionHref="/explore"
          />
        ) : (
          <div className="space-y-3">
            {upcoming.map((booking) => {
              const row = booking as unknown as {
                id: string;
                appointment_start: string;
                price: number;
                status: import("@/types/database").BookingStatus;
                salons: { name: string } | null;
                services: { name: string } | null;
                barbers: { display_name: string } | null;
              };
              return (
                <BookingCard
                  key={row.id}
                  id={row.id}
                  salonName={row.salons?.name ?? "Salon"}
                  serviceName={row.services?.name ?? "Service"}
                  barberName={row.barbers?.display_name}
                  start={row.appointment_start}
                  price={row.price}
                  status={row.status}
                  href={`/customer/bookings/${row.id}`}
                />
              );
            })}
          </div>
        )}
      </section>

      {/* Personalized Recommendations based on User Activities */}
      <CustomerRecommendations
        recommendations={recommendations ?? []}
        recentActivities={recentActivities ?? []}
      />
    </div>
  );
}
