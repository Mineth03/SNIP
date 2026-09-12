import { CalendarDays } from "lucide-react";
import { BookingCard } from "@/components/snip/booking-card";
import { EmptyState } from "@/components/ui/empty-state";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "My bookings" };

export default async function CustomerBookingsPage() {
  const profile = await requireRole(["customer", "admin"]);
  const supabase = await createClient();

  const { data: bookings } = await supabase
    .from("bookings")
    .select(
      "id, appointment_start, price, status, salons(name), services(name), barbers(display_name)",
    )
    .eq("customer_id", profile.id)
    .order("appointment_start", { ascending: false });

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Bookings</h2>
        <p className="text-sm text-snip-muted">
          Track upcoming and past appointments.
        </p>
      </div>
      {!bookings?.length ? (
        <EmptyState
          icon={CalendarDays}
          title="No bookings yet"
          description="Explore salons and book your first appointment."
          actionLabel="Explore salons"
          actionHref="/explore"
        />
      ) : (
        <div className="space-y-3">
          {bookings.map((booking) => {
            const row = booking as unknown as {
              id: string;
              appointment_start: string;
              price: number;
              status: BookingStatus;
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
    </div>
  );
}
