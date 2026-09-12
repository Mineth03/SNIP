"use client";

import { useEffect, useRef } from "react";

interface TrackSalonViewProps {
  salonId: string;
}

export function TrackSalonView({ salonId }: TrackSalonViewProps) {
  const tracked = useRef(false);

  useEffect(() => {
    if (tracked.current || !salonId) return;
    tracked.current = true;

    fetch("/api/activity", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        activityType: "view_salon",
        salonId,
      }),
    }).catch(() => {
      // Non-blocking telemetry
    });
  }, [salonId]);

  return null;
}
