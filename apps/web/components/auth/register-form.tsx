"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { ArrowRight, Eye, EyeOff, Lock, Mail, Phone, Store, User } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { getRoleHome } from "@/lib/auth/roles";
import type { UserRole } from "@/types/database";

const schema = z.object({
  full_name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().optional(),
  password: z.string().min(6, "Password must be at least 6 characters"),
  role: z.enum(["customer", "salon_owner"]),
});

type FormValues = z.infer<typeof schema>;

export function RegisterForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialRole =
    searchParams.get("role") === "salon_owner" ? "salon_owner" : "customer";
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      full_name: "",
      email: "",
      phone: "",
      password: "",
      role: initialRole,
    },
  });

  const selectedRole = form.watch("role");

  async function onSubmit(values: FormValues) {
    setLoading(true);
    try {
      const supabase = createClient();
      const origin = window.location.origin;
      const { data, error } = await supabase.auth.signUp({
        email: values.email,
        password: values.password,
        options: {
          emailRedirectTo: `${origin}/login`,
          data: {
            full_name: values.full_name,
            phone: values.phone || null,
            role: values.role,
          },
        },
      });
      if (error) throw error;

      if (data.session && data.user) {
        await fetch("/api/emails", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            to: values.email,
            template: "welcome",
            data: {
              name: values.full_name,
              ctaUrl: `${origin}${getRoleHome(values.role as UserRole)}`,
            },
          }),
        }).catch(() => undefined);

        toast.success("Welcome to SNIP! Account created successfully.");
        router.push(getRoleHome(values.role));
        router.refresh();
        return;
      }

      toast.success("Please check your email to confirm your account");
      router.push("/login");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to register");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3.5">
      {/* Role Selector Pills */}
      <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-50 p-1 dark:bg-slate-800">
        <button
          type="button"
          onClick={() => form.setValue("role", "customer")}
          className={`flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-bold transition-all ${
            selectedRole === "customer"
              ? "bg-white text-slate-900 shadow-xs dark:bg-slate-700 dark:text-white"
              : "text-slate-500 hover:text-slate-800 dark:text-slate-400"
          }`}
        >
          <User className="h-3.5 w-3.5 text-snip-teal" />
          <span>Client / Customer</span>
        </button>

        <button
          type="button"
          onClick={() => form.setValue("role", "salon_owner")}
          className={`flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-bold transition-all ${
            selectedRole === "salon_owner"
              ? "bg-white text-slate-900 shadow-xs dark:bg-slate-700 dark:text-white"
              : "text-slate-500 hover:text-slate-800 dark:text-slate-400"
          }`}
        >
          <Store className="h-3.5 w-3.5 text-snip-teal" />
          <span>Salon Owner</span>
        </button>
      </div>

      {/* Full Name */}
      <div>
        <div className="relative">
          <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
            <User className="h-4 w-4" />
          </div>
          <input
            id="full_name"
            type="text"
            placeholder="Full name"
            className="flex h-11 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm text-slate-800 transition placeholder:text-slate-400 focus:border-snip-teal focus:outline-none focus:ring-2 focus:ring-snip-teal/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder:text-slate-500"
            {...form.register("full_name")}
          />
        </div>
        {form.formState.errors.full_name ? (
          <p className="mt-1 pl-1 text-xs text-rose-500">
            {form.formState.errors.full_name.message}
          </p>
        ) : null}
      </div>

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
            className="flex h-11 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm text-slate-800 transition placeholder:text-slate-400 focus:border-snip-teal focus:outline-none focus:ring-2 focus:ring-snip-teal/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder:text-slate-500"
            {...form.register("email")}
          />
        </div>
        {form.formState.errors.email ? (
          <p className="mt-1 pl-1 text-xs text-rose-500">
            {form.formState.errors.email.message}
          </p>
        ) : null}
      </div>

      {/* Phone (Optional) */}
      <div>
        <div className="relative">
          <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
            <Phone className="h-4 w-4" />
          </div>
          <input
            id="phone"
            type="tel"
            placeholder="Phone number (optional)"
            className="flex h-11 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm text-slate-800 transition placeholder:text-slate-400 focus:border-snip-teal focus:outline-none focus:ring-2 focus:ring-snip-teal/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder:text-slate-500"
            {...form.register("phone")}
          />
        </div>
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
            autoComplete="new-password"
            placeholder="Password (min. 6 characters)"
            className="flex h-11 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-11 text-sm text-slate-800 transition placeholder:text-slate-400 focus:border-snip-teal focus:outline-none focus:ring-2 focus:ring-snip-teal/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder:text-slate-500"
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
      </div>

      {/* Submit Button */}
      <button
        type="submit"
        disabled={loading}
        className="group mt-2 flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-[#14B8A6] font-bold text-white shadow-sm transition-all hover:bg-[#0D9488] active:scale-[0.99] disabled:opacity-60"
      >
        {loading ? (
          <>
            <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
            <span>Creating account...</span>
          </>
        ) : (
          <>
            <span>Create account</span>
            <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
          </>
        )}
      </button>

      {/* Divider */}
      <div className="relative my-3">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-slate-200 dark:border-slate-800" />
        </div>
        <div className="relative flex justify-center text-xs">
          <span className="bg-white px-3 text-slate-400 dark:bg-slate-900 dark:text-slate-500">
            Already have an account?
          </span>
        </div>
      </div>

      {/* Sign In Link */}
      <div className="text-center">
        <Link
          href="/login"
          className="inline-flex items-center gap-1 text-sm font-bold text-snip-teal hover:underline transition-colors"
        >
          <span>Sign In</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </form>
  );
}
