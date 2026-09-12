"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Check, CheckCircle2, Play, UserCheck } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import type { BookingStatus } from "@/types/database";

export function BookingStatusActionButton({
  bookingId,
  currentStatus,
}: {
  bookingId: string;
  currentStatus: BookingStatus;
}) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<BookingStatus>(currentStatus);

  async function handleTransition(toStatus: BookingStatus) {
    setLoading(true);
    try {
      const res = await fetch("/api/bookings/status", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ bookingId, toStatus }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "Update failed");

      setStatus(toStatus);
      toast.success(`Status updated to ${toStatus.replace("_", " ")}`);
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to update status");
    } finally {
      setLoading(false);
    }
  }

  if (status === "confirmed") {
    return (
      <Button
        size="sm"
        variant="outline"
        disabled={loading}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          handleTransition("checked_in");
        }}
        className="h-8 gap-1.5 border-snip-primary/40 text-snip-teal hover:bg-snip-primary/10"
      >
        <UserCheck className="h-3.5 w-3.5" />
        {loading ? "Checking in..." : "Check In"}
      </Button>
    );
  }

  if (status === "checked_in") {
    return (
      <Button
        size="sm"
        disabled={loading}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          handleTransition("in_progress");
        }}
        className="h-8 gap-1.5 bg-snip-primary text-white hover:bg-snip-primary-hover shadow-sm"
      >
        <Play className="h-3.5 w-3.5 fill-current" />
        {loading ? "Starting..." : "Start Service"}
      </Button>
    );
  }

  if (status === "in_progress") {
    return (
      <Button
        size="sm"
        disabled={loading}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          handleTransition("completed");
        }}
        className="h-8 gap-1.5 bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm"
      >
        <Check className="h-3.5 w-3.5" />
        {loading ? "Finishing..." : "Complete"}
      </Button>
    );
  }

  if (status === "completed") {
    return (
      <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-600">
        <CheckCircle2 className="h-4 w-4" /> Done
      </span>
    );
  }

  return null;
}
