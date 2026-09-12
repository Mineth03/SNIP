"use client";

import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { StatusBadge } from "@/components/ui/status-badge";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";
import type { Salon, SalonVerificationStatus } from "@/types/database";

export default function AdminVerificationPage() {
  const [salons, setSalons] = useState<Salon[]>([]);
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);

  async function load() {
    const supabase = createClient();
    const { data } = await supabase
      .from("salons")
      .select("*")
      .eq("verification_status", "pending_verification")
      .order("updated_at", { ascending: false });
    setSalons((data as Salon[]) ?? []);
    setLoading(false);
  }

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- client mount data fetch
    void load();
  }, []);

  async function decide(
    salonId: string,
    decision: "approved" | "rejected" | "changes_requested",
  ) {
    try {
      const res = await fetch("/api/admin/verify-salon", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          salonId,
          decision,
          notes: notes[salonId] || null,
        }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "Verification failed");
      toast.success(`Salon ${decision.replaceAll("_", " ")}`);
      await load();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Verification failed");
    }
  }

  if (loading) return <p className="text-sm text-snip-muted">Loading queue...</p>;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Verification</h2>
        <p className="text-sm text-snip-muted">
          Review salons waiting for platform approval.
        </p>
      </div>
      {salons.length === 0 ? (
        <EmptyState title="Queue is clear" description="No salons pending verification." />
      ) : (
        <div className="space-y-4">
          {salons.map((salon) => (
            <Card key={salon.id}>
              <CardContent className="space-y-4 p-5">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="text-lg font-semibold text-snip-charcoal">
                      {salon.name}
                    </p>
                    <p className="text-sm text-snip-muted">
                      {[salon.address, salon.city].filter(Boolean).join(", ") ||
                        "Address not provided"}
                    </p>
                    <p className="mt-2 text-sm text-snip-muted">
                      {salon.description ?? "No description"}
                    </p>
                  </div>
                  <StatusBadge
                    status={salon.verification_status as SalonVerificationStatus}
                    kind="verification"
                  />
                </div>
                <Textarea
                  placeholder="Reviewer notes / rejection reason"
                  value={notes[salon.id] ?? ""}
                  onChange={(e) =>
                    setNotes((prev) => ({ ...prev, [salon.id]: e.target.value }))
                  }
                />
                <div className="flex flex-wrap gap-2">
                  <Button type="button" onClick={() => decide(salon.id, "approved")}>
                    Approve
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => decide(salon.id, "changes_requested")}
                  >
                    Request changes
                  </Button>
                  <Button
                    type="button"
                    variant="danger"
                    onClick={() => decide(salon.id, "rejected")}
                  >
                    Reject
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
