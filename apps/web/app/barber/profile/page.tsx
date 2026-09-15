"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
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
import { RoleSwitcher } from "@/components/snip/role-switcher";
import { BarberSalonSwitcher } from "@/components/snip/barber-salon-switcher";
import { createClient } from "@/lib/supabase/client";
import type { AppCapability } from "@/lib/auth/roles";
import type { UserRole } from "@/types/database";

const schema = z.object({
  full_name: z.string().min(2, "Name is required"),
  phone: z.string().optional(),
  bio: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export default function BarberProfilePage() {
  const router = useRouter();
  const [userId, setUserId] = useState<string | null>(null);
  const [avatarUrl, setAvatarUrl] = useState<string>("");
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [capabilities, setCapabilities] = useState<AppCapability[]>(["customer"]);
  const [activeRole, setActiveRole] = useState<UserRole>("barber");
  const [activeSalonId, setActiveSalonId] = useState<string | null>(null);
  const [barberId, setBarberId] = useState<string | null>(null);
  const [memberships, setMemberships] = useState<
    { salonId: string; salonName: string; barberId: string }[]
  >([]);

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

      const [{ data: profile }, { data: barbers }, { data: caps }] = await Promise.all([
        supabase
          .from("profiles")
          .select("full_name, phone, avatar_url, active_role, role, active_barber_salon_id")
          .eq("id", user.id)
          .maybeSingle(),
        supabase
          .from("barbers")
          .select("id, bio, salon_id, salons(name)")
          .eq("profile_id", user.id)
          .eq("is_active", true),
        supabase.rpc("user_capabilities", { p_uid: user.id }),
      ]);

      const list =
        barbers?.map((b) => {
          const salon = b.salons as unknown as { name: string } | null;
          return {
            salonId: b.salon_id as string,
            salonName: salon?.name ?? "Salon",
            barberId: b.id as string,
            bio: b.bio as string | null,
          };
        }) ?? [];

      setMemberships(
        list.map(({ salonId, salonName, barberId }) => ({
          salonId,
          salonName,
          barberId,
        })),
      );

      const preferred =
        list.find((m) => m.salonId === profile?.active_barber_salon_id) ?? list[0];
      setActiveSalonId(preferred?.salonId ?? null);
      setBarberId(preferred?.barberId ?? null);

      if (profile?.avatar_url) setAvatarUrl(profile.avatar_url);
      setActiveRole((profile?.active_role ?? profile?.role ?? "barber") as UserRole);
      if (Array.isArray(caps)) setCapabilities(caps as AppCapability[]);

      form.reset({
        full_name: profile?.full_name ?? "",
        phone: profile?.phone ?? "",
        bio: preferred?.bio ?? "",
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

      if (barberId) {
        await supabase
          .from("barbers")
          .update({ bio: values.bio || null })
          .eq("id", barberId);
      }

      toast.success("Barber profile updated!");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to save profile");
    } finally {
      setSaving(false);
    }
  }

  async function resign() {
    if (!activeSalonId) return;
    if (
      !window.confirm(
        "Resign from this salon? Your account stays active — you can join another salon later.",
      )
    ) {
      return;
    }
    const supabase = createClient();
    const { error } = await supabase.rpc("resign_from_salon", {
      p_salon_id: activeSalonId,
    });
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("You left this salon");
    router.push("/customer/profile");
    router.refresh();
  }

  if (loading) return <p className="text-sm text-snip-muted">Loading profile...</p>;

  return (
    <div className="mx-auto max-w-xl space-y-6">
      <div className="space-y-2">
        <h2 className="text-2xl font-bold tracking-tight text-snip-charcoal">
          Stylist Profile
        </h2>
        <p className="text-sm text-snip-muted">
          Your profile, salon memberships, and role switcher.
        </p>
        {activeSalonId ? (
          <BarberSalonSwitcher
            memberships={memberships}
            activeSalonId={activeSalonId}
          />
        ) : null}
      </div>

      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <CardContent className="p-5">
          <RoleSwitcher capabilities={capabilities} activeRole={activeRole} />
        </CardContent>
      </Card>

      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <CardHeader>
          <CardTitle className="text-base font-bold text-snip-charcoal">
            Stylist Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <div>
              <label className="mb-2 block text-xs font-semibold text-snip-charcoal">
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
              <Input id="full_name" {...form.register("full_name")} />
            </div>
            <div>
              <Label htmlFor="phone">Phone</Label>
              <Input id="phone" {...form.register("phone")} />
            </div>
            <div>
              <Label htmlFor="bio">Bio (active salon)</Label>
              <Textarea id="bio" {...form.register("bio")} />
            </div>

            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : "Save Changes"}
            </Button>
          </form>
        </CardContent>
      </Card>

      {activeSalonId ? (
        <Card className="rounded-2xl border border-rose-200 bg-rose-50/40">
          <CardContent className="space-y-3 p-5">
            <h3 className="text-sm font-bold text-snip-charcoal">Leave this salon</h3>
            <p className="text-xs text-snip-muted">
              Resign from your active salon membership. Other salon jobs and your
              customer account stay intact.
            </p>
            <Button type="button" variant="outline" onClick={resign}>
              Resign from active salon
            </Button>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
