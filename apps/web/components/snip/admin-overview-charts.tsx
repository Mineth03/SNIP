"use client";

import {
  Area,
  AreaChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

export function AdminBookingsTrendChart({
  data,
}: {
  data: { date: string; bookings: number; newUsers: number }[];
}) {
  return (
    <div className="h-72 w-full">
      <div className="mb-4 flex items-center justify-end gap-6 text-xs font-medium">
        <div className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full bg-snip-primary" />
          <span className="text-snip-charcoal">Bookings</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full bg-slate-400" />
          <span className="text-snip-muted">New Users</span>
        </div>
      </div>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
          <defs>
            <linearGradient id="trendBookings" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#14B8A6" stopOpacity={0.4} />
              <stop offset="95%" stopColor="#14B8A6" stopOpacity={0.0} />
            </linearGradient>
            <linearGradient id="trendUsers" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#94A3B8" stopOpacity={0.3} />
              <stop offset="95%" stopColor="#94A3B8" stopOpacity={0.0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
          <XAxis
            dataKey="date"
            tick={{ fill: "#64748B", fontSize: 12 }}
            axisLine={{ stroke: "#E2E8F0" }}
            tickLine={false}
          />
          <YAxis
            allowDecimals={false}
            tick={{ fill: "#64748B", fontSize: 12 }}
            axisLine={false}
            tickLine={false}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: "#1F2937",
              borderRadius: "8px",
              border: "none",
              color: "#FFFFFF",
              fontSize: "12px",
            }}
          />
          <Area
            type="monotone"
            dataKey="bookings"
            stroke="#14B8A6"
            strokeWidth={2.5}
            fill="url(#trendBookings)"
          />
          <Area
            type="monotone"
            dataKey="newUsers"
            stroke="#94A3B8"
            strokeWidth={2}
            fill="url(#trendUsers)"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}

export function AdminUserDistributionChart({
  customers = 78,
  owners = 16,
  barbers = 6,
  total = 1248,
}: {
  customers?: number;
  owners?: number;
  barbers?: number;
  total?: number;
}) {
  const data = [
    { name: "Customers", value: customers, color: "#14B8A6" },
    { name: "Salon Owners", value: owners, color: "#1F2937" },
    { name: "Barbers", value: barbers, color: "#5EEAD4" },
  ];

  return (
    <div className="flex flex-col items-center justify-between sm:flex-row sm:gap-6">
      <div className="relative h-56 w-56 flex-shrink-0">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={data}
              innerRadius={68}
              outerRadius={92}
              paddingAngle={4}
              dataKey="value"
            >
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Pie>
            <Tooltip />
          </PieChart>
        </ResponsiveContainer>
        {/* Center label */}
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center text-center">
          <span className="text-2xl font-bold text-snip-charcoal">{total}</span>
          <span className="text-[11px] font-medium text-snip-muted uppercase tracking-wider">
            Total Users
          </span>
        </div>
      </div>

      {/* Legend */}
      <div className="mt-4 w-full space-y-3 sm:mt-0 sm:w-auto">
        {data.map((item) => (
          <div key={item.name} className="flex items-center justify-between gap-6 text-sm">
            <div className="flex items-center gap-2">
              <span
                className="h-3 w-3 rounded-full"
                style={{ backgroundColor: item.color }}
              />
              <span className="font-medium text-snip-charcoal">{item.name}</span>
            </div>
            <span className="font-bold text-snip-muted">{item.value}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}
