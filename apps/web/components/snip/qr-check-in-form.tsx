"use client";

import { useState } from "react";
import { CheckCircle2, QrCode, Search, UserCheck } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface CheckedInBooking {
  id: string;
  status: string;
  serviceName: string;
  customerName: string;
  barberName: string;
  appointment_start: string;
}

export function QrCheckInForm() {
  const [qrToken, setQrToken] = useState("");
  const [loading, setLoading] = useState(false);
  const [lastCheckIn, setLastCheckIn] = useState<CheckedInBooking | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!qrToken.trim()) return;
    setLoading(true);
    setLastCheckIn(null);
    try {
      const res = await fetch("/api/bookings/check-in", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ qrToken: qrToken.trim() }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "Check-in failed");

      toast.success("Guest checked in successfully!");
      setLastCheckIn(json.booking);
      setQrToken("");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Check-in failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-6 max-w-xl">
      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base font-bold text-snip-charcoal">
            <QrCode className="h-5 w-5 text-snip-teal" />
            Check-In by QR Code or Ticket ID
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} className="space-y-4">
            <div>
              <Label htmlFor="qr" className="text-xs font-semibold text-snip-muted">
                Ticket Code or QR UUID
              </Label>
              <div className="mt-1 flex gap-2">
                <div className="relative flex-1">
                  <Input
                    id="qr"
                    value={qrToken}
                    onChange={(e) => setQrToken(e.target.value)}
                    placeholder="e.g. SNIP784629 or paste QR UUID"
                    className="font-mono text-sm pl-9"
                    required
                  />
                  <Search className="absolute left-3 top-2.5 h-4 w-4 text-snip-muted" />
                </div>
                <Button type="submit" disabled={loading || !qrToken}>
                  {loading ? "Checking..." : "Check In"}
                </Button>
              </div>
            </div>

            {/* Quick demo action */}
            <div className="flex items-center gap-2 text-xs text-snip-muted pt-1">
              <span>Quick test:</span>
              <button
                type="button"
                onClick={() => setQrToken("SNIP784629")}
                className="font-mono font-semibold text-snip-teal underline hover:text-snip-primary-hover"
              >
                SNIP784629
              </button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Success Confirmation Card */}
      {lastCheckIn && (
        <Card className="rounded-2xl border border-emerald-200 bg-emerald-50/50 p-6 shadow-snip-sm animate-in fade-in-50 duration-200">
          <div className="flex items-start gap-4">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
              <CheckCircle2 className="h-6 w-6" />
            </div>
            <div className="space-y-1">
              <div className="text-xs font-bold uppercase tracking-wider text-emerald-700">
                Check-in Confirmed
              </div>
              <h4 className="text-base font-bold text-snip-charcoal">
                {lastCheckIn.customerName}
              </h4>
              <p className="text-xs text-snip-muted">
                Service: <span className="font-semibold text-snip-charcoal">{lastCheckIn.serviceName}</span> with{" "}
                <span className="font-semibold text-snip-charcoal">{lastCheckIn.barberName}</span>
              </p>
              <div className="pt-2">
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-600/10 px-2.5 py-0.5 text-xs font-bold text-emerald-700">
                  <UserCheck className="h-3 w-3" /> Status: Checked In
                </span>
              </div>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}
