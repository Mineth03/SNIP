"use client";

import { useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export function QrCheckInForm() {
  const [qrToken, setQrToken] = useState("");
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch("/api/bookings/check-in", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ qrToken }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "Check-in failed");
      toast.success("Guest checked in");
      setQrToken("");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Check-in failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Card className="max-w-lg">
      <CardHeader>
        <CardTitle>Scan or paste QR token</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <Label htmlFor="qr">QR token</Label>
            <Input
              id="qr"
              value={qrToken}
              onChange={(e) => setQrToken(e.target.value)}
              placeholder="Paste booking QR UUID"
              required
            />
          </div>
          <Button type="submit" disabled={loading || !qrToken}>
            {loading ? "Checking in..." : "Check in guest"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
