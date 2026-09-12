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
import { ImageUploader } from "@/components/ui/image-uploader";
import { createClient } from "@/lib/supabase/client";

const schema = z.object({
  full_name: z.string().min(2, "Name is required"),
  phone: z.string().optional(),
  city: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export default function CustomerProfilePage() {
  const [userId, setUserId] = useState<string | null>(null);
  const [avatarUrl, setAvatarUrl] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { full_name: "", phone: "", city: "" },
  });

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;
      setUserId(user.id);

      const { data } = await supabase
        .from("profiles")
        .select("full_name, phone, city, avatar_url")
        .eq("id", user.id)
        .maybeSingle();

      if (data) {
        setAvatarUrl(data.avatar_url ?? "");
        form.reset({
          full_name: data.full_name ?? "",
          phone: data.phone ?? "",
          city: data.city ?? "",
        });
      }
      setLoading(false);
    }
    load();
  }, [form]);

  async function onSubmit(values: FormValues) {
    if (!userId) return;
    setSaving(true);
    try {
      const supabase = createClient();
      const { error } = await supabase
        .from("profiles")
        .update({
          full_name: values.full_name,
          phone: values.phone || null,
          city: values.city || null,
          avatar_url: avatarUrl || null,
        })
        .eq("id", userId);

      if (error) throw error;
      toast.success("Profile updated successfully!");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to save profile");
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <p className="text-sm text-snip-muted">Loading profile...</p>;

  return (
    <div className="mx-auto max-w-xl space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-snip-charcoal">
          Customer Profile
        </h2>
        <p className="text-sm text-snip-muted">
          Manage your personal details and photo.
        </p>
      </div>

      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <CardHeader>
          <CardTitle className="text-base font-bold text-snip-charcoal">
            Personal Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Avatar uploader */}
            <div>
              <label className="block text-xs font-semibold text-snip-charcoal mb-2">
                Profile Photo
              </label>
              <ImageUploader
                value={avatarUrl}
                onChange={setAvatarUrl}
                onRemove={() => setAvatarUrl("")}
                bucket="avatars"
                folder={userId ?? "users"}
                variant="avatar"
                description="Square image up to 5MB"
                maxSizeMB={5}
              />
            </div>

            <div>
              <Label htmlFor="full_name">Full Name</Label>
              <Input
                id="full_name"
                {...form.register("full_name")}
                className="mt-1"
              />
            </div>

            <div>
              <Label htmlFor="phone">Phone / WhatsApp</Label>
              <Input id="phone" {...form.register("phone")} className="mt-1" />
            </div>

            <div>
              <Label htmlFor="city">City / Neighborhood</Label>
              <Input id="city" {...form.register("city")} className="mt-1" />
            </div>

            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : "Save Changes"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
