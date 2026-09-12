import { notFound } from "next/navigation";
import Link from "next/link";
import { ChevronLeft } from "lucide-react";
import { QRCodeImage } from "@/components/snip/qr-code-image";
import { RealtimeTicketWrapper } from "@/components/snip/realtime-ticket-wrapper";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { Booking } from "@/types/database";

export const metadata = { title: "Booking Ticket | SNIP" };

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
    <div className="mx-auto max-w-2xl space-y-6 py-6">
      <div className="flex items-center justify-between">
        <Link
          href="/customer/bookings"
          className="inline-flex items-center gap-1.5 text-sm font-semibold text-snip-muted hover:text-snip-charcoal"
        >
          <ChevronLeft className="h-4 w-4" />
          Back to Bookings
        </Link>
        <span className="text-xs font-medium text-snip-muted">
          Ref: {booking.id.slice(0, 8)}
        </span>
      </div>

      <RealtimeTicketWrapper
        initialBooking={booking}
        qrCodeElement={<QRCodeImage value={booking.qr_token} size={180} />}
      />
    </div>
  );
}
