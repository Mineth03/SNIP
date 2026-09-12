import { Suspense } from "react";
import { AuthShell } from "@/components/auth/auth-shell";
import { RegisterForm } from "@/components/auth/register-form";
import { LoadingSkeleton } from "@/components/ui/loading-skeleton";

export const metadata = { title: "Create account | SNIP" };

export default function RegisterPage() {
  return (
    <AuthShell
      title="Create your account"
      subtitle="Sign up to book appointments, manage your salon, and keep beauty moving."
      mode="register"
    >
      <Suspense fallback={<LoadingSkeleton rows={4} />}>
        <RegisterForm />
      </Suspense>
    </AuthShell>
  );
}
