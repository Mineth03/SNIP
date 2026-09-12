import { Suspense } from "react";
import { AuthShell } from "@/components/auth/auth-shell";
import { ResetPasswordForm } from "@/components/auth/reset-password-form";
import { LoadingSkeleton } from "@/components/ui/loading-skeleton";

export const metadata = { title: "Set New Password | SNIP" };

export default function ResetPasswordPage() {
  return (
    <AuthShell
      title="Create new password"
      subtitle="Ensure your account stays safe by choosing a strong, unique password"
      mode="login"
    >
      <Suspense fallback={<LoadingSkeleton rows={2} />}>
        <ResetPasswordForm />
      </Suspense>
    </AuthShell>
  );
}
