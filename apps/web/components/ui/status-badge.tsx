import { Badge } from "@/components/ui/badge";
import type { BookingStatus, SalonVerificationStatus } from "@/types/database";

const bookingMap: Record<
  BookingStatus,
  { label: string; variant: "default" | "primary" | "success" | "warning" | "danger" | "info" }
> = {
  pending: { label: "Pending", variant: "warning" },
  confirmed: { label: "Confirmed", variant: "primary" },
  checked_in: { label: "Checked in", variant: "info" },
  in_progress: { label: "In progress", variant: "info" },
  completed: { label: "Completed", variant: "success" },
  cancelled: { label: "Cancelled", variant: "danger" },
  no_show: { label: "No show", variant: "danger" },
};

const verificationMap: Record<
  SalonVerificationStatus,
  { label: string; variant: "default" | "primary" | "success" | "warning" | "danger" | "info" }
> = {
  draft: { label: "Draft", variant: "default" },
  pending_verification: { label: "Pending", variant: "warning" },
  verified: { label: "Verified", variant: "success" },
  rejected: { label: "Rejected", variant: "danger" },
  suspended: { label: "Suspended", variant: "danger" },
};

export function StatusBadge({
  status,
  kind = "booking",
}: {
  status: BookingStatus | SalonVerificationStatus;
  kind?: "booking" | "verification";
}) {
  const meta =
    kind === "verification"
      ? verificationMap[status as SalonVerificationStatus]
      : bookingMap[status as BookingStatus];

  return <Badge variant={meta.variant}>{meta.label}</Badge>;
}
