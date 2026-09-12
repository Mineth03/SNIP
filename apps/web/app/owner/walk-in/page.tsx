"use client";

import { useEffect, useState } from "react";
import { addMinutes, format } from "date-fns";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createClient } from "@/lib/supabase/client";
import type { Barber, Service } from "@/types/database";

export default function OwnerWalkInPage() {
  const [salonId, setSalonId] = useState<string | null>(null);
  const [services, setServices] = useState<Service[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [serviceId, setServiceId] = useState("");
  const [barberId, setBarberId] = useState("");
  const [customerEmail, setCustomerEmail] = useState("");
  const [notes, setNotes] = useState("");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;
      const { data: salon } = await supabase
        .from("salons")
        .select("id")
        .eq("owner_id", user.id)
        .limit(1)
        .maybeSingle();
      if (!salon) {
        setLoading(false);
        return;
      }
      setSalonId(salon.id);
      const [{ data: serviceRows }, { data: barberRows }] = await Promise.all([
        supabase
          .from("services")
          .select("*")
          .eq("salon_id", salon.id)
          .eq("is_active", true),
        supabase
          .from("barbers")
          .select("*")
          .eq("salon_id", salon.id)
          .eq("is_active", true),
      ]);
      setServices((serviceRows as Service[]) ?? []);
      setBarbers((barberRows as Barber[]) ?? []);
      setServiceId(serviceRows?.[0]?.id ?? "");
      setBarberId(barberRows?.[0]?.id ?? "");
      setLoading(false);
    }
    load();
  }, []);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!salonId || !serviceId) {
      toast.error("Select a service");
      return;
    }
    setSubmitting(true);
    try {
      const supabase = createClient();
      if (!customerEmail) {
        toast.error("Enter the customer’s SNIP email");
        setSubmitting(false);
        return;
      }
      const { data: profile } = await supabase
        .from("profiles")
        .select("id")
        .eq("email", customerEmail)
        .maybeSingle();
      const customerId = profile?.id ?? null;
      if (!customerId) {
        toast.error("No customer found with that email. Use an existing SNIP customer.");
        setSubmitting(false);
        return;
      }

      const start = new Date();
      start.setSeconds(0, 0);
      const rounded = addMinutes(start, 5 - (start.getMinutes() % 5 || 5));

      const res = await fetch("/api/bookings/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          salonId,
          serviceId,
          barberId: barberId || null,
          appointmentStart: rounded.toISOString(),
          customerId,
          customerNotes: notes || "Walk-in",
          isWalkIn: true,
        }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "Unable to create walk-in");
      toast.success(`Walk-in booked for ${format(rounded, "h:mm a")}`);
      setNotes("");
      setCustomerEmail("");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to create walk-in");
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) return <p className="text-sm text-snip-muted">Loading...</p>;
  if (!salonId) {
    return (
      <EmptyState
        title="No salon yet"
        actionLabel="Create salon"
        actionHref="/owner/salon"
      />
    );
  }

  if (!services.length) {
    return (
      <EmptyState
        title="Add a service first"
        description="Walk-ins need at least one active service."
        actionLabel="Manage services"
        actionHref="/owner/services"
      />
    );
  }

  return (
    <div className="mx-auto max-w-xl space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Walk-in booking</h2>
        <p className="text-sm text-snip-muted">
          Quickly seat a guest without an online reservation.
        </p>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>New walk-in</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} className="space-y-4">
            <div>
              <Label htmlFor="service">Service</Label>
              <select
                id="service"
                className="flex h-11 w-full rounded-md border border-snip-border bg-white px-3 text-sm"
                value={serviceId}
                onChange={(e) => setServiceId(e.target.value)}
              >
                {services.map((service) => (
                  <option key={service.id} value={service.id}>
                    {service.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <Label htmlFor="barber">Stylist</Label>
              <select
                id="barber"
                className="flex h-11 w-full rounded-md border border-snip-border bg-white px-3 text-sm"
                value={barberId}
                onChange={(e) => setBarberId(e.target.value)}
              >
                <option value="">Any available</option>
                {barbers.map((barber) => (
                  <option key={barber.id} value={barber.id}>
                    {barber.display_name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <Label htmlFor="email">Customer email</Label>
              <Input
                id="email"
                type="email"
                value={customerEmail}
                onChange={(e) => setCustomerEmail(e.target.value)}
                placeholder="Existing SNIP customer email"
                required
              />
            </div>
            <div>
              <Label htmlFor="notes">Notes</Label>
              <Input
                id="notes"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
              />
            </div>
            <Button type="submit" disabled={submitting}>
              {submitting ? "Creating..." : "Create walk-in"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
