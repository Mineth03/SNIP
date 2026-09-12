import { BookingCard } from "@/components/snip/booking-card";
import { EmptyState } from "@/components/ui/empty-state";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Admin bookings" };

export default async function AdminBookingsPage() {
  await requireRole("admin");
  const supabase = await createClient();
  const { data: bookings } = await supabase
    .from("bookings")
    .select(
      "id, appointment_start, price, status, salons(name), services(name), barbers(display_name)",
    )
    .order("appointment_start", { ascending: false })
    .limit(50);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Bookings</h2>
        <p className="text-sm text-snip-muted">Latest appointments across SNIP.</p>
      </div>
      {!bookings?.length ? (
        <EmptyState title="No bookings yet" />
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
              />
            );
          })}
        </div>
      )}
    </div>
  );
}
