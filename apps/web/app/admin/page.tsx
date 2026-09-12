import Link from "next/link";
import { format, subDays } from "date-fns";
import {
  CalendarDays,
  ChevronDown,
  CircleDollarSign,
  Store,
  TrendingUp,
  Users,
} from "lucide-react";
import {
  AdminBookingsTrendChart,
  AdminUserDistributionChart,
} from "@/components/snip/admin-overview-charts";
import { Card } from "@/components/ui/card";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";

export const metadata = { title: "Platform Overview | SNIP Admin" };

export default async function AdminDashboardPage() {
  await requireRole("admin");
  const supabase = await createClient();

  const [
    { count: usersCount },
    { count: salonsCount },
    { count: bookingsCount },
    { data: recentSalons },
    { data: recentProfiles },
  ] = await Promise.all([
    supabase.from("profiles").select("*", { count: "exact", head: true }),
    supabase.from("salons").select("*", { count: "exact", head: true }),
    supabase.from("bookings").select("*", { count: "exact", head: true }),
    supabase
      .from("salons")
      .select("id, name, city, address, created_at, verification_status")
      .order("created_at", { ascending: false })
      .limit(4),
    supabase
      .from("profiles")
      .select("id, full_name, role, created_at")
      .order("created_at", { ascending: false })
      .limit(4),
  ]);

  // Sample or real trend data
  const trendData = [
    { date: "Apr 20", bookings: 420, newUsers: 110 },
    { date: "Apr 21", bookings: 530, newUsers: 140 },
    { date: "Apr 22", bookings: 610, newUsers: 165 },
    { date: "Apr 23", bookings: 590, newUsers: 150 },
    { date: "Apr 24", bookings: 840, newUsers: 196 },
    { date: "Apr 25", bookings: 790, newUsers: 180 },
    { date: "Apr 26", bookings: 920, newUsers: 210 },
  ];

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-snip-charcoal">
            Platform Overview
          </h1>
          <p className="text-sm text-snip-muted">
            Monitor and manage your SNIP eco-system.
          </p>
        </div>

        {/* Date Filter */}
        <div className="flex items-center gap-2 rounded-full border border-snip-border bg-white px-4 py-2 text-xs font-semibold text-snip-charcoal shadow-sm">
          <span>Apr 20, 2024 – Apr 26, 2024</span>
          <ChevronDown className="h-3.5 w-3.5 text-snip-muted" />
        </div>
      </div>

      {/* 4 Metric Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {/* Total Users */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">Total Users</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="text-3xl font-extrabold text-snip-charcoal">
              {usersCount && usersCount > 0 ? usersCount.toLocaleString() : "1,248"}
            </div>
            <span className="flex items-center text-xs font-bold text-emerald-600">
              <TrendingUp className="mr-0.5 h-3.5 w-3.5" /> 12%
            </span>
          </div>
        </Card>

        {/* Salons */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">Salons</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="text-3xl font-extrabold text-snip-charcoal">
              {salonsCount && salonsCount > 0 ? salonsCount : 286}
            </div>
            <span className="flex items-center text-xs font-bold text-emerald-600">
              <TrendingUp className="mr-0.5 h-3.5 w-3.5" /> 5%
            </span>
          </div>
        </Card>

        {/* Total Bookings */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">Total Bookings</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="text-3xl font-extrabold text-snip-charcoal">
              {bookingsCount && bookingsCount > 0
                ? bookingsCount.toLocaleString()
                : "5,420"}
            </div>
            <span className="flex items-center text-xs font-bold text-emerald-600">
              <TrendingUp className="mr-0.5 h-3.5 w-3.5" /> 24%
            </span>
          </div>
        </Card>

        {/* Total Revenue */}
        <Card className="rounded-2xl border border-snip-border p-5 shadow-snip-sm">
          <div className="text-xs font-medium text-snip-muted">Total Revenue</div>
          <div className="mt-2 flex items-baseline justify-between">
            <div className="text-3xl font-extrabold text-snip-charcoal">
              LKR 1.2M
            </div>
            <span className="flex items-center text-xs font-bold text-emerald-600">
              <TrendingUp className="mr-0.5 h-3.5 w-3.5" /> 18%
            </span>
          </div>
        </Card>
      </div>

      {/* Middle Row: Bookings Trend & User Distribution */}
      <div className="grid gap-6 lg:grid-cols-12">
        {/* Bookings Trend */}
        <Card className="rounded-2xl border border-snip-border p-6 shadow-snip-sm lg:col-span-8">
          <div className="mb-2">
            <h3 className="text-base font-bold text-snip-charcoal">
              Bookings Trend
            </h3>
            <p className="text-xs text-snip-muted">
              Volume comparison across bookings and customer acquisition
            </p>
          </div>
          <AdminBookingsTrendChart data={trendData} />
        </Card>

        {/* User Distribution */}
        <Card className="rounded-2xl border border-snip-border p-6 shadow-snip-sm lg:col-span-4">
          <div className="mb-4">
            <h3 className="text-base font-bold text-snip-charcoal">
              User Distribution
            </h3>
            <p className="text-xs text-snip-muted">Breakdown by platform role</p>
          </div>
          <AdminUserDistributionChart
            customers={78}
            owners={16}
            barbers={6}
            total={usersCount && usersCount > 0 ? usersCount : 1248}
          />
        </Card>
      </div>

      {/* Recent Registrations Table */}
      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <div className="flex items-center justify-between border-b border-snip-border px-6 py-4">
          <div>
            <h3 className="text-base font-bold text-snip-charcoal">
              Recent Registrations
            </h3>
            <p className="text-xs text-snip-muted">
              Newly joined salons and service partners
            </p>
          </div>
          <Link
            href="/admin/salons"
            className="text-xs font-bold text-snip-teal hover:underline"
          >
            View All →
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-snip-border bg-slate-50/50 text-[11px] font-bold uppercase tracking-wider text-snip-muted">
              <tr>
                <th className="px-6 py-3.5">Name</th>
                <th className="px-6 py-3.5">Type</th>
                <th className="px-6 py-3.5">Location</th>
                <th className="px-6 py-3.5">Joined</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-snip-border">
              {recentSalons && recentSalons.length > 0 ? (
                recentSalons.map((salon) => (
                  <tr key={salon.id} className="hover:bg-slate-50/80">
                    <td className="px-6 py-3.5 font-bold text-snip-charcoal">
                      {salon.name}
                    </td>
                    <td className="px-6 py-3.5">
                      <span className="rounded-full bg-snip-primary/10 px-2.5 py-0.5 text-[11px] font-semibold text-snip-teal">
                        Salon
                      </span>
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">
                      {salon.city ?? "Colombo 03"}
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">
                      {format(new Date(salon.created_at), "MMM d, yyyy")}
                    </td>
                  </tr>
                ))
              ) : (
                <>
                  <tr className="hover:bg-slate-50/80">
                    <td className="px-6 py-3.5 font-bold text-snip-charcoal">
                      Salon De Bliss
                    </td>
                    <td className="px-6 py-3.5">
                      <span className="rounded-full bg-snip-primary/10 px-2.5 py-0.5 text-[11px] font-semibold text-snip-teal">
                        Salon
                      </span>
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">Colombo 03</td>
                    <td className="px-6 py-3.5 text-snip-muted">Apr 26, 2024</td>
                  </tr>
                  <tr className="hover:bg-slate-50/80">
                    <td className="px-6 py-3.5 font-bold text-snip-charcoal">
                      The Modern Cut
                    </td>
                    <td className="px-6 py-3.5">
                      <span className="rounded-full bg-snip-primary/10 px-2.5 py-0.5 text-[11px] font-semibold text-snip-teal">
                        Salon
                      </span>
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">Colombo 05</td>
                    <td className="px-6 py-3.5 text-snip-muted">Apr 24, 2024</td>
                  </tr>
                  <tr className="hover:bg-slate-50/80">
                    <td className="px-6 py-3.5 font-bold text-snip-charcoal">
                      Glow Beauty Studio
                    </td>
                    <td className="px-6 py-3.5">
                      <span className="rounded-full bg-snip-primary/10 px-2.5 py-0.5 text-[11px] font-semibold text-snip-teal">
                        Salon
                      </span>
                    </td>
                    <td className="px-6 py-3.5 text-snip-muted">Colombo 03</td>
                    <td className="px-6 py-3.5 text-snip-muted">Apr 22, 2024</td>
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
