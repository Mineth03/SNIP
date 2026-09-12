import { QrCheckInForm } from "@/components/snip/qr-check-in-form";

export const metadata = { title: "QR check-in" };

export default function OwnerQrPage() {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">QR check-in</h2>
        <p className="text-sm text-snip-muted">
          Paste a guest’s booking QR token to mark them as checked in.
        </p>
      </div>
      <QrCheckInForm />
    </div>
  );
}
