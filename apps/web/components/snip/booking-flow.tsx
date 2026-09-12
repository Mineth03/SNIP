"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { addDays, format } from "date-fns";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { formatCurrency, formatDuration } from "@/lib/utils";
import type { AvailableSlot, Barber, Service } from "@/types/database";

export function BookingFlow({
  salonId,
  salonName,
  slug,
  services,
  barbers,
}: {
  salonId: string;
  salonName: string;
  slug: string;
  services: Service[];
  barbers: Barber[];
}) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [serviceId, setServiceId] = useState(
    searchParams.get("service") ?? services[0]?.id ?? "",
  );
  const [barberId, setBarberId] = useState("");
  const [date, setDate] = useState(format(new Date(), "yyyy-MM-dd"));
  const [slots, setSlots] = useState<AvailableSlot[]>([]);
  const [selectedSlot, setSelectedSlot] = useState<AvailableSlot | null>(null);
  const [notes, setNotes] = useState("");
  const [loadingSlots, setLoadingSlots] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const selectedService = useMemo(
    () => services.find((s) => s.id === serviceId),
    [services, serviceId],
  );

  useEffect(() => {
    if (!serviceId || !date) return;
    let cancelled = false;

    async function loadSlots() {
      setLoadingSlots(true);
      setSelectedSlot(null);
      try {
        const qs = new URLSearchParams({
          salonId,
          serviceId,
          date,
        });
        if (barberId) qs.set("barberId", barberId);
        const res = await fetch(`/api/bookings/slots?${qs.toString()}`);
        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "Failed to load slots");
        if (!cancelled) setSlots(json.slots ?? []);
      } catch (err) {
        if (!cancelled) {
          setSlots([]);
          toast.error(err instanceof Error ? err.message : "Unable to load slots");
        }
      } finally {
        if (!cancelled) setLoadingSlots(false);
      }
    }

    loadSlots();
    return () => {
      cancelled = true;
    };
  }, [salonId, serviceId, barberId, date]);

  async function confirmBooking() {
    if (!selectedSlot || !selectedService) {
      toast.error("Select a service and time slot");
      return;
    }
    setSubmitting(true);
    try {
      const res = await fetch("/api/bookings/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          salonId,
          serviceId,
          barberId: selectedSlot.barber_id,
          appointmentStart: selectedSlot.slot_start,
          customerNotes: notes || null,
        }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "Booking failed");
      toast.success("Booking confirmed");
      router.push(`/customer/bookings/${json.booking.id}`);
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Booking failed");
    } finally {
      setSubmitting(false);
    }
  }

  const dateOptions = Array.from({ length: 14 }).map((_, i) => {
    const d = addDays(new Date(), i);
    return {
      value: format(d, "yyyy-MM-dd"),
      label: format(d, "EEE, MMM d"),
    };
  });

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_340px]">
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>1. Choose a service</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-3">
            {services.map((service) => (
              <button
                key={service.id}
                type="button"
                onClick={() => setServiceId(service.id)}
                className={`rounded-md border px-4 py-3 text-left transition ${
                  serviceId === service.id
                    ? "border-snip-primary bg-snip-primary/10"
                    : "border-snip-border hover:bg-snip-bg-muted"
                }`}
              >
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <p className="font-semibold text-snip-charcoal">
                      {service.name}
                    </p>
                    <p className="text-xs text-snip-muted">
                      {formatDuration(service.duration_minutes)}
                    </p>
                  </div>
                  <p className="font-semibold text-snip-charcoal">
                    {formatCurrency(service.price)}
                  </p>
                </div>
              </button>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>2. Stylist & date</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label>Stylist</Label>
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={() => setBarberId("")}
                  className={`rounded-md border px-3 py-2 text-sm ${
                    !barberId
                      ? "border-snip-primary bg-snip-primary/10 text-snip-teal"
                      : "border-snip-border text-snip-muted"
                  }`}
                >
                  Any available
                </button>
                {barbers.map((barber) => (
                  <button
                    key={barber.id}
                    type="button"
                    onClick={() => setBarberId(barber.id)}
                    className={`rounded-md border px-3 py-2 text-sm ${
                      barberId === barber.id
                        ? "border-snip-primary bg-snip-primary/10 text-snip-teal"
                        : "border-snip-border text-snip-muted"
                    }`}
                  >
                    {barber.display_name}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <Label>Date</Label>
              <div className="flex gap-2 overflow-x-auto pb-1">
                {dateOptions.map((option) => (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => setDate(option.value)}
                    className={`shrink-0 rounded-md border px-3 py-2 text-sm ${
                      date === option.value
                        ? "border-snip-primary bg-snip-primary/10 text-snip-teal"
                        : "border-snip-border text-snip-muted"
                    }`}
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>3. Available times</CardTitle>
          </CardHeader>
          <CardContent>
            {loadingSlots ? (
              <p className="text-sm text-snip-muted">Loading slots...</p>
            ) : slots.length === 0 ? (
              <p className="text-sm text-snip-muted">
                No open slots for this selection. Try another day or stylist.
              </p>
            ) : (
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4">
                {slots.map((slot) => {
                  const active =
                    selectedSlot?.slot_start === slot.slot_start &&
                    selectedSlot?.barber_id === slot.barber_id;
                  return (
                    <button
                      key={`${slot.barber_id}-${slot.slot_start}`}
                      type="button"
                      onClick={() => setSelectedSlot(slot)}
                      className={`rounded-md border px-3 py-2 text-sm ${
                        active
                          ? "border-snip-primary bg-snip-primary text-white"
                          : "border-snip-border hover:bg-snip-bg-muted"
                      }`}
                    >
                      <div className="font-semibold">
                        {format(new Date(slot.slot_start), "h:mm a")}
                      </div>
                      <div className={active ? "text-white/80" : "text-snip-muted"}>
                        {slot.barber_name}
                      </div>
                    </button>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <Card className="h-fit lg:sticky lg:top-24">
        <CardHeader>
          <CardTitle>Booking summary</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1 text-sm">
            <p className="font-semibold text-snip-charcoal">{salonName}</p>
            <p className="text-snip-muted">
              {selectedService?.name ?? "Select a service"}
            </p>
            {selectedSlot ? (
              <p className="text-snip-muted">
                {format(new Date(selectedSlot.slot_start), "EEE, MMM d · h:mm a")}
                {" · "}
                {selectedSlot.barber_name}
              </p>
            ) : (
              <p className="text-snip-muted">Choose a time slot</p>
            )}
            {selectedService ? (
              <p className="pt-2 text-lg font-semibold text-snip-charcoal">
                {formatCurrency(selectedService.price)}
              </p>
            ) : null}
          </div>
          <div>
            <Label htmlFor="notes">Notes (optional)</Label>
            <Textarea
              id="notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Allergies, style preferences..."
            />
          </div>
          <Button
            type="button"
            className="w-full"
            disabled={!selectedSlot || submitting}
            onClick={confirmBooking}
          >
            {submitting ? "Confirming..." : "Confirm booking"}
          </Button>
          <Button
            type="button"
            variant="ghost"
            className="w-full"
            onClick={() => router.push(`/salons/${slug}`)}
          >
            Back to salon
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
