import { notFound } from "next/navigation";
import { format } from "date-fns";
import { QrCode } from "lucide-react";
import { StatusBadge } from "@/components/ui/status-badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import { formatCurrency } from "@/lib/utils";
import type { Booking, BookingStatus } from "@/types/database";

export const metadata = { title: "Booking details" };

export default async function CustomerBookingDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const profile = await requireRole(["customer", "admin"]);
  const supabase = await createClient();

  const { data } = await supabase
    .from("bookings")
    .select(
      "*, salons(name, address, city, phone), services(name, duration_minutes), barbers(display_name)",
    )
    .eq("id", id)
    .eq("customer_id", profile.id)
    .maybeSingle();

  if (!data) notFound();

  const booking = data as Booking & {
    salons: {
      name: string;
      address: string | null;
      city: string | null;
      phone: string | null;
    } | null;
    services: { name: string; duration_minutes: number } | null;
    barbers: { display_name: string } | null;
  };

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="flex flex-wrap items-center gap-3">
        <h2 className="text-2xl font-semibold text-snip-charcoal">
          {booking.services?.name ?? "Booking"}
        </h2>
        <StatusBadge status={booking.status as BookingStatus} />
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Appointment</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm text-snip-muted">
            <p className="text-base font-semibold text-snip-charcoal">
              {format(new Date(booking.appointment_start), "EEEE, MMM d · h:mm a")}
            </p>
            <p>Salon: {booking.salons?.name}</p>
            <p>Stylist: {booking.barbers?.display_name ?? "Assigned stylist"}</p>
            <p>Total: {formatCurrency(booking.price)}</p>
            {booking.customer_notes ? <p>Notes: {booking.customer_notes}</p> : null}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <QrCode className="h-4 w-4 text-snip-teal" />
              Check-in ticket
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="rounded-lg border border-dashed border-snip-border bg-snip-bg p-6 text-center">
              <p className="font-mono text-sm font-semibold tracking-wider text-snip-charcoal">
                {booking.qr_token}
              </p>
              <p className="mt-2 text-xs text-snip-muted">
                Show this QR token at the salon for check-in.
              </p>
            </div>
            <p className="text-sm text-snip-muted">
              {[booking.salons?.address, booking.salons?.city]
                .filter(Boolean)
                .join(", ") || "Address on file with salon"}
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
