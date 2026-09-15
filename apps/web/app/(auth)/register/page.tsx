import { Suspense } from "react";
import { AuthShell } from "@/components/auth/auth-shell";
import { RegisterForm } from "@/components/auth/register-form";
import { LoadingSkeleton } from "@/components/ui/loading-skeleton";

export const metadata = { title: "Create account | SNIP" };

export default function RegisterPage() {
  return (
    <AuthShell
      title="Create your account"
      subtitle="Join SNIP as a customer. You can become a salon owner or join a salon team later from your profile."
      mode="register"
    >
      <Suspense fallback={<LoadingSkeleton rows={4} />}>
        <RegisterForm />
      </Suspense>
    </AuthShell>
  );
}
