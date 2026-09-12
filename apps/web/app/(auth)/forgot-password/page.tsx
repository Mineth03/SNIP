import { Suspense } from "react";
import { AuthShell } from "@/components/auth/auth-shell";
import { ForgotPasswordForm } from "@/components/auth/forgot-password-form";
import { LoadingSkeleton } from "@/components/ui/loading-skeleton";

export const metadata = { title: "Forgot Password | SNIP" };

export default function ForgotPasswordPage() {
  return (
    <AuthShell
      title="Reset your password"
      subtitle="Enter your email to receive a recovery link and regain access to your account"
      mode="login"
    >
      <Suspense fallback={<LoadingSkeleton rows={2} />}>
        <ForgotPasswordForm />
      </Suspense>
    </AuthShell>
  );
}
