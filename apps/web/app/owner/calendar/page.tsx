import { format, startOfDay, addHours } from "date-fns";
import { EmptyState } from "@/components/ui/empty-state";
import { Card, CardContent } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { requireRole } from "@/lib/auth/require-role";
import { getOwnedSalon } from "@/lib/owner/get-owned-salon";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Calendar" };

export default async function OwnerCalendarPage() {
  const profile = await requireRole(["salon_owner", "admin"]);
  const salon = await getOwnedSalon(profile.id);
  if (!salon) {
    return (
      <EmptyState
        title="No salon yet"
        actionLabel="Create salon"
        actionHref="/owner/salon"
      />
    );
  }

  const supabase = await createClient();
  const dayStart = startOfDay(new Date()).toISOString();
  const dayEnd = addHours(startOfDay(new Date()), 24).toISOString();

  const { data: bookings } = await supabase
    .from("bookings")
    .select(
      "id, appointment_start, appointment_end, status, services(name), barbers(display_name), profiles:customer_id(full_name)",
    )
    .eq("salon_id", salon.id)
    .gte("appointment_start", dayStart)
    .lt("appointment_start", dayEnd)
    .order("appointment_start", { ascending: true });

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Calendar</h2>
        <p className="text-sm text-snip-muted">
          Today · {format(new Date(), "EEEE, MMMM d")}
        </p>
      </div>
      {!bookings?.length ? (
        <EmptyState
          title="No appointments today"
          description="Your day is clear. Walk-ins can still be added anytime."
          actionLabel="Add walk-in"
          actionHref="/owner/walk-in"
        />
      ) : (
        <div className="space-y-3">
          {bookings.map((booking) => {
            const row = booking as unknown as {
              id: string;
              appointment_start: string;
              appointment_end: string;
              status: BookingStatus;
              services: { name: string } | null;
              barbers: { display_name: string } | null;
              profiles: { full_name: string } | null;
            };
            return (
              <Card key={row.id}>
                <CardContent className="flex flex-wrap items-center justify-between gap-3 p-4">
                  <div>
                    <p className="font-semibold text-snip-charcoal">
                      {format(new Date(row.appointment_start), "h:mm a")} –{" "}
                      {format(new Date(row.appointment_end), "h:mm a")}
                    </p>
                    <p className="text-sm text-snip-muted">
                      {row.services?.name} · {row.profiles?.full_name ?? "Guest"}
                      {row.barbers?.display_name
                        ? ` · ${row.barbers.display_name}`
                        : ""}
                    </p>
                  </div>
                  <StatusBadge status={row.status} />
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
