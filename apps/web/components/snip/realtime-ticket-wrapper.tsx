"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { format } from "date-fns";
import {
  Calendar,
  CalendarCheck,
  CheckCircle2,
  Clock,
  MapPin,
  RotateCcw,
  Sparkles,
  Store,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "@/components/ui/status-badge";
import { BookingReviewForm } from "@/components/snip/booking-review-form";
import { createClient } from "@/lib/supabase/client";
import { formatCurrency } from "@/lib/utils";
import type { Booking, BookingStatus } from "@/types/database";

export function RealtimeTicketWrapper({
  initialBooking,
  qrCodeElement,
}: {
  initialBooking: Booking & {
    salons: {
      name: string;
      address: string | null;
      city: string | null;
      phone: string | null;
    } | null;
    services: { name: string; duration_minutes: number } | null;
    barbers: { display_name: string } | null;
  };
  qrCodeElement: React.ReactNode;
}) {
  const router = useRouter();
  const [booking, setBooking] = useState(initialBooking);

  useEffect(() => {
    const supabase = createClient();
    const topic = `booking-live-${booking.id}`;
    const existing = supabase
      .getChannels()
      .find((c) => c.topic === `realtime:${topic}`);
    if (existing) {
      supabase.removeChannel(existing);
    }

    const channel = supabase
      .channel(topic)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "bookings",
          filter: `id=eq.${booking.id}`,
        },
        (payload) => {
          const updated = payload.new as Booking;
          setBooking((prev) => ({
            ...prev,
            status: updated.status,
            appointment_start: updated.appointment_start,
            appointment_end: updated.appointment_end,
          }));

          const statusLabels: Record<string, string> = {
            checked_in: "You are checked in! The stylist will see you shortly.",
            in_progress: "Your service has started! Relax and enjoy.",
            completed: "Your service is completed! Thank you for visiting.",
            cancelled: "Your appointment has been cancelled.",
          };

          const msg = statusLabels[updated.status] || `Status updated: ${updated.status}`;
          toast.success(msg, {
            icon: <Sparkles className="h-4 w-4 text-snip-teal" />,
            duration: 6000,
          });

          router.refresh();
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [booking.id, router]);

  const ticketCode = `SNIP${booking.qr_token.replaceAll("-", "").slice(0, 6).toUpperCase()}`;
  const startDate = new Date(booking.appointment_start);

  return (
    <div className="overflow-hidden rounded-3xl border border-snip-border bg-white shadow-snip transition-all">
      {/* Ticket Header */}
      <div className="flex items-center justify-between border-b border-snip-border bg-slate-50/70 px-6 py-4">
        <div className="flex items-center gap-2">
          <Calendar className="h-4 w-4 text-snip-teal" />
          <span className="text-sm font-bold text-snip-charcoal">
            {format(startDate, "EEE, MMM d · h:mm a")}
          </span>
        </div>
        <div className="flex items-center gap-2">
          {booking.status === "in_progress" && (
            <span className="flex h-2 w-2 rounded-full bg-snip-teal animate-ping" />
          )}
          <StatusBadge status={booking.status as BookingStatus} />
        </div>
      </div>

      {/* Salon & Service Details */}
      <div className="border-b border-snip-border p-6 space-y-4">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-snip-primary/10 text-snip-teal">
            <Store className="h-6 w-6" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-snip-charcoal">
              {booking.salons?.name ?? "Salon"}
            </h3>
            <p className="text-xs text-snip-muted flex items-center gap-1">
              <MapPin className="h-3 w-3" />
              {[booking.salons?.address, booking.salons?.city]
                .filter(Boolean)
                .join(", ") || "Colombo, Sri Lanka"}
            </p>
          </div>
        </div>

        <div className="rounded-2xl border border-snip-border bg-snip-bg p-4 flex items-center justify-between">
          <div className="space-y-1">
            <div className="text-xs font-medium text-snip-muted">
              Service & Stylist
            </div>
            <div className="text-sm font-bold text-snip-charcoal">
              {booking.services?.name ?? "Service"} with{" "}
              {booking.barbers?.display_name ?? "Stylist"}
            </div>
            <div className="text-xs text-snip-muted flex items-center gap-1">
              <Clock className="h-3 w-3" />
              {booking.services?.duration_minutes ?? 30} mins
            </div>
          </div>
          <div className="text-right">
            <div className="text-xs text-snip-muted font-medium">Amount</div>
            <div className="text-base font-extrabold text-snip-charcoal">
              {formatCurrency(booking.price)}
            </div>
          </div>
        </div>
      </div>

      {/* QR Code Section */}
      <div className="flex flex-col items-center justify-center p-8 text-center bg-white">
        <div className="rounded-2xl border border-snip-border bg-white p-3 shadow-snip-sm relative">
          {qrCodeElement}
          {booking.status === "completed" && (
            <div className="absolute inset-0 bg-white/85 backdrop-blur-[2px] rounded-2xl flex flex-col items-center justify-center text-emerald-700 font-bold gap-1">
              <CheckCircle2 className="h-10 w-10 text-emerald-600" />
              <span>Checked Out</span>
            </div>
          )}
        </div>

        <div className="mt-4 space-y-1">
          <div className="font-mono text-2xl font-extrabold tracking-widest text-snip-charcoal">
            {ticketCode}
          </div>
          <p className="text-xs text-snip-muted">
            {booking.status === "confirmed"
              ? "Show this QR code at the salon desk for instant check-in"
              : booking.status === "checked_in"
              ? "✓ Checked in — Stylist notified"
              : booking.status === "in_progress"
              ? "Service in progress with stylist"
              : "Appointment completed"}
          </p>
        </div>

        {/* Action buttons */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3 w-full">
          <Button variant="outline" className="gap-2">
            <CalendarCheck className="h-4 w-4" />
            Add to Calendar
          </Button>
          {booking.status === "confirmed" && (
            <Button variant="secondary" className="gap-2">
              <RotateCcw className="h-4 w-4" />
              Reschedule
            </Button>
          )}
        </div>

        {/* Post-appointment Review Prompt */}
        {booking.status === "completed" && (
          <div className="mt-6 w-full">
            <BookingReviewForm
              bookingId={booking.id}
              salonName={booking.salons?.name}
              barberName={booking.barbers?.display_name}
            />
          </div>
        )}
      </div>
    </div>
  );
}
