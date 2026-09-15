"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createClient } from "@/lib/supabase/client";

const schema = z.object({
  name: z.string().min(2, "Salon name is required"),
  city: z.string().optional(),
  phone: z.string().optional(),
  address: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export function BecomeOwnerCard({ alreadyOwner }: { alreadyOwner?: boolean }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { name: "", city: "", phone: "", address: "" },
  });

  if (alreadyOwner) return null;

  async function onSubmit(values: FormValues) {
    setLoading(true);
    try {
      const supabase = createClient();
      const { error } = await supabase.rpc("become_salon_owner", {
        p_name: values.name,
        p_city: values.city || null,
        p_phone: values.phone || null,
        p_address: values.address || null,
      });
      if (error) throw error;
      toast.success("You’re now a salon owner!");
      router.push("/owner");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to create salon");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
      <CardHeader>
        <CardTitle className="text-base font-bold text-snip-charcoal">
          Become a salon owner
        </CardTitle>
      </CardHeader>
      <CardContent>
        <p className="mb-4 text-xs text-snip-muted">
          List your salon on SNIP without creating a new account. You’ll keep your
          customer profile and can switch views anytime.
        </p>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3">
          <div>
            <Label htmlFor="salon_name">Salon name</Label>
            <Input id="salon_name" {...form.register("name")} />
            {form.formState.errors.name ? (
              <p className="mt-1 text-xs text-snip-danger">
                {form.formState.errors.name.message}
              </p>
            ) : null}
          </div>
          <div>
            <Label htmlFor="salon_city">City (optional)</Label>
            <Input id="salon_city" {...form.register("city")} />
          </div>
          <div>
            <Label htmlFor="salon_phone">Phone (optional)</Label>
            <Input id="salon_phone" {...form.register("phone")} />
          </div>
          <div>
            <Label htmlFor="salon_address">Address (optional)</Label>
            <Input id="salon_address" {...form.register("address")} />
          </div>
          <Button type="submit" disabled={loading} className="w-full">
            {loading ? "Creating..." : "Create salon & switch to Owner"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
