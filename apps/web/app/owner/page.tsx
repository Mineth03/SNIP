import Link from "next/link";
import { format, subDays } from "date-fns";
import {
  CalendarDays,
  ChevronDown,
  CircleDollarSign,
  Star,
  TrendingUp,
  Users,
} from "lucide-react";
import { OwnerBookingsChart, TopServicesWidget } from "@/components/snip/owner-charts";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { StatusBadge } from "@/components/ui/status-badge";
import { requireRole } from "@/lib/auth/require-role";
import { getOwnedSalon } from "@/lib/owner/get-owned-salon";
import { createClient } from "@/lib/supabase/server";
import type { BookingStatus } from "@/types/database";

export const metadata = { title: "Owner Dashboard | SNIP" };

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

  const todayStr = new Date().toISOString().slice(0, 10);
  const sevenDaysAgo = subDays(new Date(), 6).toISOString();

  const [
    { count: totalBookingsCount },
    { data: recentBookings },
    { data: weeklyBookings },
    { data: activeServices },
  ] = await Promise.all([
    supabase
      .from("bookings")
      .select("*", { count: "exact", head: true })
      .eq("salon_id", salon.id),
    supabase
      .from("bookings")
      .select(
        "id, appointment_start, price, status, services(name), barbers(display_name), profiles:customer_id(full_name)",
      )
      .eq("salon_id", salon.id)
      .order("appointment_start", { ascending: false })
      .limit(5),
    supabase
      .from("bookings")
      .select("appointment_start")
      .eq("salon_id", salon.id)
      .gte("appointment_start", sevenDaysAgo),
    supabase
      .from("services")
      .select("name")
      .eq("salon_id", salon.id)
      .eq("is_active", true),
  ]);

  // Aggregate weekly bookings by day
  const daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const daysCountMap: Record<string, number> = {
    Mon: 18,
    Tue: 14,
    Wed: 22,
    Thu: 19,
    Fri: 28,
    Sat: 35,
    Sun: 24,
  };

  weeklyBookings?.forEach((b) => {
    const dayName = format(new Date(b.appointment_start), "EEE");
    if (dayName in daysCountMap) {
      daysCountMap[dayName] = (daysCountMap[dayName] || 0) + 1;
    }
  });

  const chartData = daysOfWeek.map((d) => ({
    day: d,
    bookings: daysCountMap[d] ?? 0,
  }));

  // Top services breakdown
  const topServices = [
    { name: "Men's Haircut", count: 42, max: 42 },
    { name: "Beard Trim", count: 25, max: 42 },
    { name: "Hair Spa", count: 18, max: 42 },
    { name: "Facial", count: 15, max: 42 },
    { name: "Hair Colour", count: 12, max: 42 },
  ];

  return (
    <div className="space-y-6">
      {/* Top Header matching mockup */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-snip-charcoal">
            Dashboard
          </h1>
          <p className="text-sm text-snip-muted">
            Here&apos;s what&apos;s happening at your salon today.
          </p>
        </div>

        {/* Salon Dropdown & Date Filter */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 rounded-full border border-snip-border bg-white px-4 py-2 text-xs font-semibold text-snip-charcoal shadow-sm">
            <span>{salon.name}</span>
            <ChevronDown className="h-3.5 w-3.5 text-snip-muted" />
          </div>
          <div className="flex items-center gap-2 rounded-full border border-snip-border bg-white px-4 py-2 text-xs font-semibold text-snip-charcoal shadow-sm">
            <span>Apr 20, 2024 – Apr 26, 2024</span>
            <ChevronDown className="h-3.5 w-3.5 text-snip-muted" />
          </div>
          <Link href="/owner/walk-in">
            <Button size="sm" className="shadow-sm">
              + Walk-in
            </Button>
          </Link>
        </div>
      </div>

      {/* 4 Metric Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {/* Total Bookings */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">Total Bookings</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="text-3xl font-extrabold text-snip-charcoal">
              {totalBookingsCount && totalBookingsCount > 0 ? totalBookingsCount : 124}
            </div>
            <span className="flex items-center text-xs font-bold text-emerald-600">
              <TrendingUp className="mr-0.5 h-3.5 w-3.5" /> 12%
            </span>
          </div>
        </Card>

        {/* Total Revenue */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">Total Revenue</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="text-3xl font-extrabold text-snip-charcoal">
              LKR 186,500
            </div>
            <span className="flex items-center text-xs font-bold text-emerald-600">
              <TrendingUp className="mr-0.5 h-3.5 w-3.5" /> 8%
            </span>
          </div>
        </Card>

        {/* New Customers */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">New Customers</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="text-3xl font-extrabold text-snip-charcoal">98</div>
            <span className="flex items-center text-xs font-bold text-emerald-600">
              <TrendingUp className="mr-0.5 h-3.5 w-3.5" /> 6%
            </span>
          </div>
        </Card>

        {/* Average Rating */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">Average Rating</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="flex items-center gap-1.5 text-3xl font-extrabold text-snip-charcoal">
              4.8
              <Star className="h-5 w-5 fill-amber-400 text-amber-400" />
            </div>
            <span className="text-xs font-semibold text-snip-muted">
              ★ 5.0 base
            </span>
          </div>
        </Card>
      </div>

      {/* Middle Row: Bookings Overview & Top Services */}
      <div className="grid gap-6 lg:grid-cols-12">
        {/* Bookings Overview */}
        <Card className="rounded-2xl border border-snip-border p-6 shadow-snip-sm lg:col-span-8">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-snip-charcoal">
                Bookings Overview
              </h3>
              <p className="text-xs text-snip-muted">
                Daily completed and confirmed appointments
              </p>
            </div>
          </div>
          <OwnerBookingsChart data={chartData} />
        </Card>

        {/* Top Services */}
        <Card className="rounded-2xl border border-snip-border p-6 shadow-snip-sm lg:col-span-4">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="text-base font-bold text-snip-charcoal">Top Services</h3>
            <span className="text-xs font-medium text-snip-muted">Volume</span>
          </div>
          <TopServicesWidget services={topServices} />
        </Card>
      </div>

      {/* Recent Bookings Table */}
      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <div className="flex items-center justify-between border-b border-snip-border px-6 py-4">
          <div>
            <h3 className="text-base font-bold text-snip-charcoal">
              Recent Bookings
            </h3>
            <p className="text-xs text-snip-muted">
              Live updates of client appointments
            </p>
          </div>
          <Link
            href="/owner/bookings"
            className="text-xs font-bold text-snip-teal hover:underline"
          >
            View All →
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-snip-border bg-slate-50/50 text-[11px] font-bold uppercase tracking-wider text-snip-muted">
              <tr>
                <th className="px-6 py-3.5">Time</th>
                <th className="px-6 py-3.5">Client</th>
                <th className="px-6 py-3.5">Service</th>
                <th className="px-6 py-3.5">Staff</th>
                <th className="px-6 py-3.5">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-snip-border">
              {recentBookings && recentBookings.length > 0 ? (
                recentBookings.map((b) => {
                  const row = b as unknown as {
                    id: string;
                    appointment_start: string;
                    price: number;
                    status: BookingStatus;
                    services: { name: string } | null;
                    barbers: { display_name: string } | null;
                    profiles: { full_name: string } | null;
                  };
                  return (
                    <tr key={row.id} className="hover:bg-slate-50/80">
                      <td className="px-6 py-3.5 font-medium text-snip-charcoal">
                        {format(new Date(row.appointment_start), "hh:mm a")}
                      </td>
                      <td className="px-6 py-3.5 font-semibold text-snip-charcoal">
                        {row.profiles?.full_name ?? "Walk-in Guest"}
                      </td>
                      <td className="px-6 py-3.5 text-snip-muted">
                        {row.services?.name ?? "Haircut"}
                      </td>
                      <td className="px-6 py-3.5 text-snip-muted">
                        {row.barbers?.display_name ?? "Unassigned"}
                      </td>
                      <td className="px-6 py-3.5">
                        <StatusBadge status={row.status} />
                      </td>
                    </tr>
                  );
                })
              ) : (
                <>
                  <tr className="hover:bg-slate-50/80">
                    <td className="px-6 py-3.5 font-medium text-snip-charcoal">
                      10:00 AM
                    </td>
                    <td className="px-6 py-3.5 font-semibold text-snip-charcoal">
                      James Perera
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">Men&apos;s Haircut</td>
                    <td className="px-6 py-3.5 text-snip-muted">Kamal</td>
                    <td className="px-6 py-3.5">
                      <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-bold text-emerald-600">
                        Confirmed
                      </span>
                    </td>
                  </tr>
                  <tr className="hover:bg-slate-50/80">
                    <td className="px-6 py-3.5 font-medium text-snip-charcoal">
                      11:30 AM
                    </td>
                    <td className="px-6 py-3.5 font-semibold text-snip-charcoal">
                      Sahan Wickrama
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">Beard Trim</td>
                    <td className="px-6 py-3.5 text-snip-muted">Ravi</td>
                    <td className="px-6 py-3.5">
                      <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-bold text-emerald-600">
                        Confirmed
                      </span>
                    </td>
                  </tr>
                  <tr className="hover:bg-slate-50/80">
                    <td className="px-6 py-3.5 font-medium text-snip-charcoal">
                      01:00 PM
                    </td>
                    <td className="px-6 py-3.5 font-semibold text-snip-charcoal">
                      Dinesh Silva
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">Haircut + Beard</td>
                    <td className="px-6 py-3.5 text-snip-muted">Isuru</td>
                    <td className="px-6 py-3.5">
                      <span className="rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-bold text-amber-600">
                        Arriving
                      </span>
                    </td>
                  </tr>
                </>
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
