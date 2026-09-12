"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { StatusBadge } from "@/components/ui/status-badge";
import { createClient } from "@/lib/supabase/client";
import type { Salon, SalonVerificationStatus } from "@/types/database";

const schema = z.object({
  name: z.string().min(2),
  description: z.string().optional(),
  email: z.string().optional(),
  phone: z.string().optional(),
  address: z.string().optional(),
  city: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export default function OwnerSalonPage() {
  const [salon, setSalon] = useState<Salon | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: "",
      description: "",
      email: "",
      phone: "",
      address: "",
      city: "",
    },
  });

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;
      const { data } = await supabase
        .from("salons")
        .select("*")
        .eq("owner_id", user.id)
        .limit(1)
        .maybeSingle();
      if (data) {
        const row = data as Salon;
        setSalon(row);
        form.reset({
          name: row.name,
          description: row.description ?? "",
          email: row.email ?? "",
          phone: row.phone ?? "",
          address: row.address ?? "",
          city: row.city ?? "",
        });
      }
      setLoading(false);
    }
    load();
  }, [form]);

  async function onSubmit(values: FormValues) {
    setSaving(true);
    try {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) throw new Error("Not signed in");

      if (salon) {
        const { data, error } = await supabase
          .from("salons")
          .update({
            name: values.name,
            description: values.description || null,
            email: values.email || null,
            phone: values.phone || null,
            address: values.address || null,
            city: values.city || null,
          })
          .eq("id", salon.id)
          .select("*")
          .maybeSingle();
        if (error) throw error;
        setSalon(data as Salon);
        toast.success("Salon updated");
      } else {
        const { data, error } = await supabase
          .from("salons")
          .insert({
            owner_id: user.id,
            name: values.name,
            description: values.description || null,
            email: values.email || null,
            phone: values.phone || null,
            address: values.address || null,
            city: values.city || null,
            verification_status: "draft",
            is_active: true,
          })
          .select("*")
          .maybeSingle();
        if (error) throw error;
        setSalon(data as Salon);
        toast.success("Salon created");
      }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to save salon");
    } finally {
      setSaving(false);
    }
  }

  async function submitForVerification() {
    if (!salon) return;
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;

    const { error } = await supabase
      .from("salons")
      .update({ verification_status: "pending_verification" })
      .eq("id", salon.id);
    if (error) {
      toast.error(error.message);
      return;
    }

    await supabase.from("salon_verification_requests").insert({
      salon_id: salon.id,
      submitted_by: user.id,
      decision: "submitted",
    });

    setSalon({ ...salon, verification_status: "pending_verification" });
    toast.success("Submitted for verification");
  }

  if (loading) return <p className="text-sm text-snip-muted">Loading salon...</p>;

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div className="flex flex-wrap items-center gap-3">
        <h2 className="text-2xl font-semibold text-snip-charcoal">Salon profile</h2>
        {salon ? (
          <StatusBadge
            status={salon.verification_status as SalonVerificationStatus}
            kind="verification"
          />
        ) : null}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{salon ? "Edit salon" : "Create your salon"}</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div>
              <Label htmlFor="name">Salon name</Label>
              <Input id="name" {...form.register("name")} />
            </div>
            <div>
              <Label htmlFor="description">Description</Label>
              <Textarea id="description" {...form.register("description")} />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <Label htmlFor="email">Email</Label>
                <Input id="email" {...form.register("email")} />
              </div>
              <div>
                <Label htmlFor="phone">Phone</Label>
                <Input id="phone" {...form.register("phone")} />
              </div>
            </div>
            <div>
              <Label htmlFor="address">Address</Label>
              <Input id="address" {...form.register("address")} />
            </div>
            <div>
              <Label htmlFor="city">City</Label>
              <Input id="city" {...form.register("city")} />
            </div>
            <div className="flex flex-wrap gap-2">
              <Button type="submit" disabled={saving}>
                {saving ? "Saving..." : salon ? "Save changes" : "Create salon"}
              </Button>
              {salon &&
              ["draft", "rejected"].includes(salon.verification_status) ? (
                <Button type="button" variant="outline" onClick={submitForVerification}>
                  Submit for verification
                </Button>
              ) : null}
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
