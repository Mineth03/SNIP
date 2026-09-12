"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { ArrowRight, Eye, EyeOff, Lock, Mail, Sparkles } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { getRoleHome } from "@/lib/auth/roles";
import type { UserRole } from "@/types/database";

const schema = z.object({
  email: z.string().email("Enter a valid email address"),
  password: z.string().min(6, "Password must be at least 6 characters"),
});

type FormValues = z.infer<typeof schema>;

const DEMO_ACCOUNTS = [
  { role: "Customer", email: "customer@snip.demo", label: "Client" },
  { role: "Owner", email: "owner@snip.demo", label: "Owner" },
  { role: "Barber", email: "barber@snip.demo", label: "Barber" },
  { role: "Admin", email: "admin@snip.demo", label: "Admin" },
];

export function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [activeDemo, setActiveDemo] = useState<string | null>(null);

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: "", password: "" },
  });

  function fillDemo(email: string, role: string) {
    form.setValue("email", email, { shouldValidate: true });
    form.setValue("password", "SnipPassword123!", { shouldValidate: true });
    setActiveDemo(role);
    toast.info(`Filled credentials for ${role} demo`);
  }

  async function onSubmit(values: FormValues) {
    setLoading(true);
    try {
      const supabase = createClient();
      const { data, error } = await supabase.auth.signInWithPassword(values);
      if (error) throw error;

      const { data: profile } = await supabase
        .from("profiles")
        .select("role")
        .eq("id", data.user.id)
        .maybeSingle();

      const role = ((profile as { role?: UserRole } | null)?.role ??
        "customer") as UserRole;
      const next = searchParams.get("next");
      toast.success("Welcome back to SNIP!");
      router.push(next && next.startsWith("/") ? next : getRoleHome(role));
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to sign in");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-4">
      {/* Quick Demo Accounts Pill Bar */}
      <div className="flex items-center justify-between rounded-xl bg-slate-50 px-3 py-2 text-xs dark:bg-slate-800/80">
        <span className="flex items-center gap-1 font-semibold text-slate-500 dark:text-slate-400">
          <Sparkles className="h-3.5 w-3.5 text-snip-teal" />
          Demo:
        </span>
        <div className="flex items-center gap-1">
          {DEMO_ACCOUNTS.map((acc) => (
            <button
              key={acc.role}
              type="button"
              onClick={() => fillDemo(acc.email, acc.role)}
              className={`rounded-lg px-2 py-0.5 text-[11px] font-semibold transition ${
                activeDemo === acc.role
                  ? "bg-snip-teal text-white shadow-xs"
                  : "bg-white text-slate-600 hover:bg-slate-100 dark:bg-slate-700 dark:text-slate-200"
              }`}
            >
              {acc.label}
            </button>
          ))}
        </div>
      </div>

      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        {/* Email Address */}
        <div>
          <div className="relative">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
              <Mail className="h-4 w-4" />
            </div>
            <input
              id="email"
              type="email"
              autoComplete="email"
              placeholder="Email address"
              className="flex h-12 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm text-slate-800 transition placeholder:text-slate-400 focus:border-snip-teal focus:outline-none focus:ring-2 focus:ring-snip-teal/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder:text-slate-500"
              {...form.register("email")}
            />
          </div>
          {form.formState.errors.email ? (
            <p className="mt-1 pl-1 text-xs text-rose-500">
              {form.formState.errors.email.message}
            </p>
          ) : null}
        </div>

        {/* Password */}
        <div>
          <div className="relative">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
              <Lock className="h-4 w-4" />
            </div>
            <input
              id="password"
              type={showPassword ? "text" : "password"}
              autoComplete="current-password"
              placeholder="Password"
              className="flex h-12 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-11 text-sm text-slate-800 transition placeholder:text-slate-400 focus:border-snip-teal focus:outline-none focus:ring-2 focus:ring-snip-teal/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder:text-slate-500"
              {...form.register("password")}
            />
            <button
              type="button"
              onClick={() => setShowPassword((prev) => !prev)}
              className="absolute inset-y-0 right-0 flex items-center pr-3.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
              aria-label={showPassword ? "Hide password" : "Show password"}
            >
              {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
            </button>
          </div>
          {form.formState.errors.password ? (
            <p className="mt-1 pl-1 text-xs text-rose-500">
              {form.formState.errors.password.message}
            </p>
          ) : null}

          {/* Forgot Password Link */}
          <div className="mt-2 text-right">
            <Link
              href="/forgot-password"
              className="text-xs font-semibold text-snip-teal hover:underline transition-colors"
            >
              Forgot password?
            </Link>
          </div>
        </div>

        {/* Primary Sign In Button */}
        <button
          type="submit"
          disabled={loading}
          className="group flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-[#14B8A6] font-bold text-white shadow-sm transition-all hover:bg-[#0D9488] active:scale-[0.99] disabled:opacity-60"
        >
          {loading ? (
            <>
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
              <span>Signing in...</span>
            </>
          ) : (
            <>
              <span>Sign In</span>
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
            </>
          )}
        </button>
      </form>

      {/* Divider */}
      <div className="relative my-4">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-slate-200 dark:border-slate-800" />
        </div>
        <div className="relative flex justify-center text-xs">
          <span className="bg-white px-3 text-slate-400 dark:bg-slate-900 dark:text-slate-500">
            Don&apos;t have an account?
          </span>
        </div>
      </div>

      {/* Register Link */}
      <div className="text-center">
        <Link
          href="/register"
          className="inline-flex items-center gap-1 text-sm font-bold text-snip-teal hover:underline transition-colors"
        >
          <span>Create account</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </div>
  );
}
