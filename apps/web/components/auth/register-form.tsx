"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createClient } from "@/lib/supabase/client";
import { getRoleHome } from "@/lib/auth/roles";
import type { UserRole } from "@/types/database";

const schema = z.object({
  full_name: z.string().min(2, "Enter your full name"),
  email: z.email("Enter a valid email"),
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

        toast.success("Account created");
        router.push(getRoleHome(values.role));
        router.refresh();
        return;
      }

      toast.success("Check your email to confirm your account");
      router.push("/login");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to register");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <Label htmlFor="full_name">Full name</Label>
        <Input id="full_name" {...form.register("full_name")} />
        {form.formState.errors.full_name ? (
          <p className="mt-1 text-xs text-snip-danger">
            {form.formState.errors.full_name.message}
          </p>
        ) : null}
      </div>
      <div>
        <Label htmlFor="email">Email</Label>
        <Input id="email" type="email" {...form.register("email")} />
        {form.formState.errors.email ? (
          <p className="mt-1 text-xs text-snip-danger">
            {form.formState.errors.email.message}
          </p>
        ) : null}
      </div>
      <div>
        <Label htmlFor="phone">Phone (optional)</Label>
        <Input id="phone" type="tel" {...form.register("phone")} />
      </div>
      <div>
        <Label htmlFor="password">Password</Label>
        <Input id="password" type="password" {...form.register("password")} />
        {form.formState.errors.password ? (
          <p className="mt-1 text-xs text-snip-danger">
            {form.formState.errors.password.message}
          </p>
        ) : null}
      </div>
      <div>
        <Label>I am joining as</Label>
        <div className="grid grid-cols-2 gap-2">
          {(
            [
              ["customer", "Customer"],
              ["salon_owner", "Salon owner"],
            ] as const
          ).map(([value, label]) => (
            <button
              key={value}
              type="button"
              onClick={() => form.setValue("role", value)}
              className={`rounded-md border px-3 py-2.5 text-sm font-medium transition ${
                form.watch("role") === value
                  ? "border-snip-primary bg-snip-primary/10 text-snip-teal"
                  : "border-snip-border text-snip-muted hover:bg-snip-bg-muted"
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>
      <Button type="submit" className="w-full" disabled={loading}>
        {loading ? "Creating account..." : "Create account"}
      </Button>
      <p className="text-center text-sm text-snip-muted">
        Already have an account?{" "}
        <Link href="/login" className="font-semibold text-snip-teal">
          Sign in
        </Link>
      </p>
    </form>
  );
}
