import { CalendarDays } from "lucide-react";
import { BookingCard } from "@/components/snip/booking-card";
import { EmptyState } from "@/components/ui/empty-state";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Appointments" };

export default async function BarberAppointmentsPage() {
  const profile = await requireRole(["barber", "admin"]);
  const supabase = await createClient();
  const { data: barber } = await supabase
    .from("barbers")
    .select("id")
    .eq("profile_id", profile.id)
    .maybeSingle();

  if (!barber) {
    return (
      <EmptyState title="Barber profile not linked" description="Contact your salon owner." />
    );
  }

  const { data: appointments } = await supabase
    .from("bookings")
    .select(
      "id, appointment_start, price, status, services(name), profiles:customer_id(full_name)",
    )
    .eq("barber_id", barber.id)
    .order("appointment_start", { ascending: false })
    .limit(40);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Appointments</h2>
        <p className="text-sm text-snip-muted">All bookings assigned to you.</p>
      </div>
      {!appointments?.length ? (
        <EmptyState icon={CalendarDays} title="No appointments yet" />
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
