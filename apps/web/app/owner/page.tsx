import Link from "next/link";
import { CalendarDays, Scissors, Users } from "lucide-react";
import { BookingCard } from "@/components/snip/booking-card";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { MetricCard } from "@/components/ui/metric-card";
import { StatusBadge } from "@/components/ui/status-badge";
import { requireRole } from "@/lib/auth/require-role";
import { getOwnedSalon } from "@/lib/owner/get-owned-salon";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Owner dashboard" };

export default async function OwnerDashboardPage() {
  const profile = await requireRole(["salon_owner", "admin"]);
  const salon = await getOwnedSalon(profile.id);
  const supabase = await createClient();

  if (!salon) {
    return (
      <EmptyState
        title="Set up your salon"
        description="Create your salon profile to start accepting bookings on SNIP."
        actionLabel="Create salon"
        actionHref="/owner/salon"
      />
    );
  }

  const today = new Date().toISOString().slice(0, 10);
  const [{ count: bookingCount }, { count: serviceCount }, { count: staffCount }, { data: recent }] =
    await Promise.all([
      supabase
        .from("bookings")
        .select("*", { count: "exact", head: true })
        .eq("salon_id", salon.id)
        .gte("appointment_start", `${today}T00:00:00.000Z`),
      supabase
        .from("services")
        .select("*", { count: "exact", head: true })
        .eq("salon_id", salon.id)
        .eq("is_active", true),
      supabase
        .from("barbers")
        .select("*", { count: "exact", head: true })
        .eq("salon_id", salon.id)
        .eq("is_active", true),
      supabase
        .from("bookings")
        .select(
          "id, appointment_start, price, status, services(name), barbers(display_name), profiles:customer_id(full_name)",
        )
        .eq("salon_id", salon.id)
        .order("appointment_start", { ascending: true })
        .limit(6),
    ]);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold text-snip-charcoal">{salon.name}</h2>
          <div className="mt-1 flex items-center gap-2 text-sm text-snip-muted">
            <StatusBadge status={salon.verification_status} kind="verification" />
            <span>Owner dashboard</span>
          </div>
        </div>
        <div className="flex gap-2">
          <Link href="/owner/walk-in">
            <Button type="button" variant="outline">
              Walk-in
            </Button>
          </Link>
          <Link href="/owner/qr">
            <Button type="button">QR check-in</Button>
          </Link>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <MetricCard label="Today’s bookings" value={bookingCount ?? 0} icon={CalendarDays} />
        <MetricCard label="Active services" value={serviceCount ?? 0} icon={Scissors} />
        <MetricCard label="Staff" value={staffCount ?? 0} icon={Users} />
      </div>

      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-snip-charcoal">Upcoming</h3>
          <Link href="/owner/bookings" className="text-sm font-medium text-snip-teal">
            View all
          </Link>
        </div>
        {!recent?.length ? (
          <EmptyState
            title="No bookings yet"
            description="Share your salon page or add a walk-in to get started."
            actionLabel="Open walk-in"
            actionHref="/owner/walk-in"
          />
        ) : (
          <div className="space-y-3">
            {recent.map((booking) => {
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
                  href="/owner/bookings"
                />
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}
