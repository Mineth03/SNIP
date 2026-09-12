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
import { ImageUploader } from "@/components/ui/image-uploader";
import { createClient } from "@/lib/supabase/client";

const schema = z.object({
  full_name: z.string().min(2, "Name is required"),
  phone: z.string().optional(),
  bio: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export default function BarberProfilePage() {
  const [userId, setUserId] = useState<string | null>(null);
  const [avatarUrl, setAvatarUrl] = useState<string>("");
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { full_name: "", phone: "", bio: "" },
  });

  useEffect(() => {
    async function load() {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;
      setUserId(user.id);

      const [{ data: profile }, { data: barber }] = await Promise.all([
        supabase
          .from("profiles")
          .select("full_name, phone, avatar_url")
          .eq("id", user.id)
          .maybeSingle(),
        supabase
          .from("barbers")
          .select("bio")
          .eq("profile_id", user.id)
          .maybeSingle(),
      ]);

      if (profile?.avatar_url) {
        setAvatarUrl(profile.avatar_url);
      }

      form.reset({
        full_name: profile?.full_name ?? "",
        phone: profile?.phone ?? "",
        bio: barber?.bio ?? "",
      });
      setLoading(false);
    }
    load();
  }, [form]);

  async function onSubmit(values: FormValues) {
    if (!userId) return;
    setSaving(true);
    try {
      const supabase = createClient();
      const { error: profileError } = await supabase
        .from("profiles")
        .update({
          full_name: values.full_name,
          phone: values.phone || null,
          avatar_url: avatarUrl || null,
        })
        .eq("id", userId);

      if (profileError) throw profileError;

      await supabase
        .from("barbers")
        .update({ bio: values.bio || null })
        .eq("profile_id", userId);

      toast.success("Barber profile updated!");
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
          Stylist Profile
        </h2>
        <p className="text-sm text-snip-muted">
          Your public profile and bio shown to guests during booking.
        </p>
      </div>

      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <CardHeader>
          <CardTitle className="text-base font-bold text-snip-charcoal">
            Stylist Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Avatar uploader */}
            <div>
              <label className="block text-xs font-semibold text-snip-charcoal mb-2">
                Stylist Avatar Photo
              </label>
              <ImageUploader
                value={avatarUrl}
                onChange={setAvatarUrl}
                onRemove={() => setAvatarUrl("")}
                bucket="avatars"
                folder={userId ?? "barbers"}
                variant="avatar"
                description="High quality headshot up to 5MB"
                maxSizeMB={5}
              />
            </div>

            <div>
              <Label htmlFor="full_name">Display Name</Label>
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
              <Label htmlFor="bio">Bio & Specialties</Label>
              <Textarea
                id="bio"
                rows={3}
                {...form.register("bio")}
                className="mt-1"
                placeholder="Years of experience, favorite cutting techniques..."
              />
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
