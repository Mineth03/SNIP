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
import { ImageUploader } from "@/components/ui/image-uploader";
import { createClient } from "@/lib/supabase/client";
import type { Salon, SalonVerificationStatus } from "@/types/database";

const schema = z.object({
  name: z.string().min(2, "Salon name is required"),
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
  const [coverUrl, setCoverUrl] = useState<string>("");
  const [logoUrl, setLogoUrl] = useState<string>("");

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
        setCoverUrl(row.cover_url ?? "");
        setLogoUrl(row.logo_url ?? "");
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
            cover_url: coverUrl || null,
            logo_url: logoUrl || null,
          })
          .eq("id", salon.id)
          .select("*")
          .maybeSingle();
        if (error) throw error;
        setSalon(data as Salon);
        toast.success("Salon details saved!");
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
            cover_url: coverUrl || null,
            logo_url: logoUrl || null,
            verification_status: "draft",
            is_active: true,
          })
          .select("*")
          .maybeSingle();
        if (error) throw error;
        setSalon(data as Salon);
        toast.success("Salon created successfully!");
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
        <h2 className="text-2xl font-bold tracking-tight text-snip-charcoal">
          Salon Profile
        </h2>
        {salon ? (
          <StatusBadge
            status={salon.verification_status as SalonVerificationStatus}
            kind="verification"
          />
        ) : null}
      </div>

      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <CardHeader>
          <CardTitle className="text-base font-bold text-snip-charcoal">
            {salon ? "Edit Salon Information & Branding" : "Create Your Salon"}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Cover Banner */}
            <div>
              <ImageUploader
                value={coverUrl}
                onChange={setCoverUrl}
                onRemove={() => setCoverUrl("")}
                bucket="salon-images"
                folder={salon ? `salons/${salon.id}` : "covers"}
                label="Salon Cover Banner"
                description="High resolution cover banner (16:9 or 21:9)"
                variant="cover"
                maxSizeMB={10}
              />
            </div>

            {/* Logo */}
            <div>
              <label className="block text-xs font-semibold text-snip-charcoal mb-2">
                Salon Logo
              </label>
              <ImageUploader
                value={logoUrl}
                onChange={setLogoUrl}
                onRemove={() => setLogoUrl("")}
                bucket="salon-images"
                folder={salon ? `salons/${salon.id}` : "logos"}
                variant="avatar"
                description="Square logo (PNG or JPG up to 5MB)"
                maxSizeMB={5}
              />
            </div>

            <div>
              <Label htmlFor="name">Salon Name</Label>
              <Input id="name" {...form.register("name")} className="mt-1" />
            </div>

            <div>
              <Label htmlFor="description">About the Salon</Label>
              <Textarea
                id="description"
                rows={3}
                {...form.register("description")}
                className="mt-1"
                placeholder="Share your story, specialty services, and vibe..."
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <Label htmlFor="email">Public Business Email</Label>
                <Input id="email" {...form.register("email")} className="mt-1" />
              </div>
              <div>
                <Label htmlFor="phone">Phone / WhatsApp</Label>
                <Input id="phone" {...form.register("phone")} className="mt-1" />
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-3">
              <div className="sm:col-span-2">
                <Label htmlFor="address">Address</Label>
                <Input id="address" {...form.register("address")} className="mt-1" />
              </div>
              <div>
                <Label htmlFor="city">City</Label>
                <Input id="city" {...form.register("city")} className="mt-1" />
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-3 pt-2">
              <Button type="submit" disabled={saving}>
                {saving ? "Saving..." : salon ? "Save Changes" : "Create Salon"}
              </Button>
              {salon &&
              ["draft", "rejected"].includes(salon.verification_status) ? (
                <Button
                  type="button"
                  variant="outline"
                  onClick={submitForVerification}
                >
                  Submit for Verification
                </Button>
              ) : null}
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
