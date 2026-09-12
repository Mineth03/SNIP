import { CalendarDays } from "lucide-react";
import { BookingCard } from "@/components/snip/booking-card";
import { EmptyState } from "@/components/ui/empty-state";
import { MetricCard } from "@/components/ui/metric-card";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Barber dashboard" };

export default async function BarberDashboardPage() {
  const profile = await requireRole(["barber", "admin"]);
  const supabase = await createClient();

  const { data: barber } = await supabase
    .from("barbers")
    .select("id, display_name, salon_id")
    .eq("profile_id", profile.id)
    .maybeSingle();

  if (!barber) {
    return (
      <EmptyState
        title="Barber profile not linked"
        description="Ask your salon owner to link your SNIP account to a staff profile."
      />
    );
  }

  const today = new Date().toISOString().slice(0, 10);
  const { data: appointments } = await supabase
    .from("bookings")
    .select(
      "id, appointment_start, price, status, services(name), salons(name), profiles:customer_id(full_name)",
    )
    .eq("barber_id", barber.id)
    .gte("appointment_start", `${today}T00:00:00.000Z`)
    .order("appointment_start", { ascending: true })
    .limit(10);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">
          Hello, {barber.display_name}
        </h2>
        <p className="text-sm text-snip-muted">Here’s what’s on your chair today.</p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <MetricCard
          label="Today’s appointments"
          value={appointments?.length ?? 0}
          icon={CalendarDays}
        />
        <MetricCard
          label="Next up"
          value={
            appointments?.[0]
              ? new Date(appointments[0].appointment_start).toLocaleTimeString([], {
                  hour: "numeric",
                  minute: "2-digit",
                })
              : "—"
          }
        />
      </div>
      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-snip-charcoal">Today</h3>
        {!appointments?.length ? (
          <EmptyState
            title="No appointments today"
            description="Enjoy the breather — new bookings will appear here."
            actionLabel="Open schedule"
            actionHref="/barber/schedule"
          />
        ) : (
          appointments.map((booking) => {
            const row = booking as unknown as {
              id: string;
              appointment_start: string;
              price: number;
              status: BookingStatus;
              services: { name: string } | null;
              salons: { name: string } | null;
              profiles: { full_name: string } | null;
            };
            return (
              <BookingCard
                key={row.id}
                id={row.id}
                salonName={row.profiles?.full_name ?? "Guest"}
                serviceName={row.services?.name ?? "Service"}
                start={row.appointment_start}
                price={row.price}
                status={row.status}
                href="/barber/appointments"
              />
            );
          })
        )}
      </section>
    </div>
  );
}
