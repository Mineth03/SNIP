import { requireRole } from "@/lib/auth/require-role";
import { getActiveBarberContext } from "@/lib/auth/barber-context";
import { BarberSalonSwitcher } from "@/components/snip/barber-salon-switcher";
import { QrCheckInForm } from "@/components/snip/qr-check-in-form";

export const metadata = { title: "Scan QR" };

export default async function BarberScanPage() {
  const profile = await requireRole("barber");
  const ctx = await getActiveBarberContext(profile);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Scan QR</h2>
        <p className="text-sm text-snip-muted">
          Check guests in when they arrive for their appointment.
        </p>
      </div>
      {ctx ? (
        <BarberSalonSwitcher
          memberships={ctx.memberships}
          activeSalonId={ctx.salonId}
        />
      ) : (
        <p className="text-sm text-snip-muted">
          You’re not on a salon team yet. Accept an owner invite to start
          checking guests in.
        </p>
      )}
      <QrCheckInForm />
    </div>
  );
}
