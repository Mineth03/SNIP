import { QrCheckInForm } from "@/components/snip/qr-check-in-form";

export const metadata = { title: "Scan QR" };

export default function BarberScanPage() {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Scan QR</h2>
        <p className="text-sm text-snip-muted">
          Check guests in when they arrive for their appointment.
        </p>
      </div>
      <QrCheckInForm />
    </div>
  );
}
