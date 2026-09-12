import { Suspense } from "react";
import { AuthShell } from "@/components/auth/auth-shell";
import { LoginForm } from "@/components/auth/login-form";
import { LoadingSkeleton } from "@/components/ui/loading-skeleton";

export const metadata = { title: "Sign in | SNIP" };

export default function LoginPage() {
  return (
    <AuthShell
      title="Welcome back to SNIP"
      subtitle="Sign in to manage your bookings, grow your business, and keep beauty moving."
      mode="login"
    >
      <Suspense fallback={<LoadingSkeleton rows={3} />}>
        <LoginForm />
      </Suspense>
    </AuthShell>
  );
}
