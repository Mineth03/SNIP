"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

export function OwnerBookingsChart({
  data,
}: {
  data: { day: string; bookings: number }[];
}) {
  return (
    <div className="h-64 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
          <XAxis
            dataKey="day"
            tick={{ fill: "#64748B", fontSize: 12, fontWeight: 500 }}
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
            cursor={{ fill: "rgba(20, 184, 166, 0.08)" }}
          />
          <Bar
            dataKey="bookings"
            fill="#14B8A6"
            radius={[6, 6, 0, 0]}
            maxBarSize={36}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

export function TopServicesWidget({
  services,
}: {
  services: { name: string; count: number; max: number }[];
}) {
  return (
    <div className="space-y-4">
      {services.map((item) => {
        const pct = Math.min(100, Math.round((item.count / (item.max || 1)) * 100));
        return (
          <div key={item.name} className="space-y-1.5">
            <div className="flex items-center justify-between text-xs font-semibold">
              <span className="text-snip-charcoal">{item.name}</span>
              <span className="text-snip-muted">{item.count}</span>
            </div>
            <div className="h-2 w-full overflow-hidden rounded-full bg-snip-bg-muted">
              <div
                className="h-full rounded-full bg-snip-primary transition-all duration-500"
                style={{ width: `${pct}%` }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}
