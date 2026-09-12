import Link from "next/link";
import { format } from "date-fns";
import { CalendarClock } from "lucide-react";
import { StatusBadge } from "@/components/ui/status-badge";
import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency } from "@/lib/utils";
import type { BookingStatus } from "@/types/database";

export function BookingCard({
  id,
  salonName,
  serviceName,
  barberName,
  start,
  price,
  status,
  href,
}: {
  id: string;
  salonName: string;
  serviceName: string;
  barberName?: string;
  start: string;
  price: number | string;
  status: BookingStatus;
  href?: string;
}) {
  const content = (
    <Card className="transition hover:shadow-snip">
      <CardContent className="flex flex-col gap-4 p-5 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="font-semibold text-snip-charcoal">{serviceName}</h3>
            <StatusBadge status={status} />
          </div>
          <p className="text-sm text-snip-muted">{salonName}</p>
          {barberName ? (
            <p className="text-sm text-snip-muted">with {barberName}</p>
          ) : null}
          <p className="inline-flex items-center gap-1.5 text-sm text-snip-charcoal">
            <CalendarClock className="h-4 w-4 text-snip-teal" />
            {format(new Date(start), "EEE, MMM d · h:mm a")}
          </p>
        </div>
        <div className="text-left sm:text-right">
          <p className="text-lg font-semibold text-snip-charcoal">
            {formatCurrency(price)}
          </p>
          <p className="text-xs text-snip-muted">#{id.slice(0, 8)}</p>
        </div>
      </CardContent>
    </Card>
  );

  if (!href) return content;
  return <Link href={href}>{content}</Link>;
}
