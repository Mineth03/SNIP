import { format, subDays } from "date-fns";
import { CalendarDays, Store, Users } from "lucide-react";
import { AdminCharts } from "@/components/snip/admin-charts";
import { MetricCard } from "@/components/ui/metric-card";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { SalonVerificationStatus } from "@/types/database";

export const metadata = { title: "Admin dashboard" };

export default async function AdminDashboardPage() {
  await requireRole("admin");
  const supabase = await createClient();

  const [{ count: users }, { count: salons }, { count: bookings }, { data: recentBookings }, { data: salonRows }] =
    await Promise.all([
      supabase.from("profiles").select("*", { count: "exact", head: true }),
      supabase.from("salons").select("*", { count: "exact", head: true }),
      supabase.from("bookings").select("*", { count: "exact", head: true }),
      supabase
        .from("bookings")
        .select("appointment_start")
        .gte("appointment_start", subDays(new Date(), 6).toISOString()),
      supabase.from("salons").select("verification_status"),
    ]);

  const bookingsByDay = Array.from({ length: 7 }).map((_, i) => {
    const day = subDays(new Date(), 6 - i);
    const key = format(day, "yyyy-MM-dd");
    const count =
      recentBookings?.filter(
        (b) => format(new Date(b.appointment_start), "yyyy-MM-dd") === key,
      ).length ?? 0;
    return { day: format(day, "EEE"), bookings: count };
  });

  const statusOrder: SalonVerificationStatus[] = [
    "draft",
    "pending_verification",
    "verified",
    "rejected",
    "suspended",
  ];
  const salonsByStatus = statusOrder.map((status) => ({
    status: status.replaceAll("_", " "),
    count:
      salonRows?.filter((row) => row.verification_status === status).length ?? 0,
  }));

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Dashboard</h2>
        <p className="text-sm text-snip-muted">
          Platform health across users, salons, and bookings.
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <MetricCard label="Users" value={users ?? 0} icon={Users} />
        <MetricCard label="Salons" value={salons ?? 0} icon={Store} />
        <MetricCard label="Bookings" value={bookings ?? 0} icon={CalendarDays} />
      </div>
      <AdminCharts bookingsByDay={bookingsByDay} salonsByStatus={salonsByStatus} />
    </div>
  );
}
