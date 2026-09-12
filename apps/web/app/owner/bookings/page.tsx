import { CalendarDays } from "lucide-react";
import { BookingCard } from "@/components/snip/booking-card";
import { EmptyState } from "@/components/ui/empty-state";
import { requireRole } from "@/lib/auth/require-role";
import { getOwnedSalon } from "@/lib/owner/get-owned-salon";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Owner bookings" };

export default async function OwnerBookingsPage() {
  const profile = await requireRole(["salon_owner", "admin"]);
  const salon = await getOwnedSalon(profile.id);
  if (!salon) {
    return (
      <EmptyState
        title="No salon yet"
        description="Create your salon to manage bookings."
        actionLabel="Create salon"
        actionHref="/owner/salon"
      />
    );
  }

  const supabase = await createClient();
  const { data: bookings } = await supabase
    .from("bookings")
    .select(
      "id, appointment_start, price, status, services(name), barbers(display_name), profiles:customer_id(full_name)",
    )
    .eq("salon_id", salon.id)
    .order("appointment_start", { ascending: false })
    .limit(50);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Bookings</h2>
        <p className="text-sm text-snip-muted">Manage appointments for {salon.name}.</p>
      </div>
      {!bookings?.length ? (
        <EmptyState
          icon={CalendarDays}
          title="No bookings"
          description="Walk-ins and online bookings will appear here."
          actionLabel="Add walk-in"
          actionHref="/owner/walk-in"
        />
      ) : (
        <div className="space-y-3">
          {bookings.map((booking) => {
            const row = booking as unknown as {
              id: string;
              appointment_start: string;
              price: number;
              status: BookingStatus;
              services: { name: string } | null;
              barbers: { display_name: string } | null;
              profiles: { full_name: string } | null;
            };
            return (
              <BookingCard
                key={row.id}
                id={row.id}
                salonName={row.profiles?.full_name ?? "Customer"}
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
