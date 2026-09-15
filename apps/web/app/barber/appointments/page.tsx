import { BarberSalonSwitcher } from "@/components/snip/barber-salon-switcher";
import { BookingCard } from "@/components/snip/booking-card";
import { EmptyState } from "@/components/ui/empty-state";
import { getActiveBarberContext } from "@/lib/auth/barber-context";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Appointments" };

export default async function BarberAppointmentsPage() {
  const profile = await requireRole(["barber", "admin"]);
  const supabase = await createClient();
  const ctx = await getActiveBarberContext(profile);

  if (!ctx) {
    return (
      <EmptyState
        title="You’re not on a salon team yet"
        description="Contact a salon owner for an invite."
        actionLabel="Customer home"
        actionHref="/customer"
      />
    );
  }

  const { data: appointments } = await supabase
    .from("bookings")
    .select(
      "id, appointment_start, price, status, services(name), profiles:customer_id(full_name)",
    )
    .eq("barber_id", ctx.barberId)
    .order("appointment_start", { ascending: false })
    .limit(40);

  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <h2 className="text-2xl font-semibold text-snip-charcoal">Appointments</h2>
        <p className="text-sm text-snip-muted">Bookings for your active salon chair.</p>
        <BarberSalonSwitcher
          memberships={ctx.memberships}
          activeSalonId={ctx.salonId}
        />
      </div>
      {!appointments?.length ? (
        <EmptyState title="No appointments" description="New bookings will show up here." />
      ) : (
        <div className="space-y-3">
          {appointments.map((booking) => {
            const row = booking as unknown as {
              id: string;
              appointment_start: string;
              price: number;
              status: BookingStatus;
              services: { name: string } | null;
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
              />
            );
          })}
        </div>
      )}
    </div>
  );
}
