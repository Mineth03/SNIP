"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Users } from "lucide-react";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";
import type { Barber } from "@/types/database";

const schema = z.object({
  display_name: z.string().min(2),
  bio: z.string().optional(),
  specializations: z.string().optional(),
  invited_email: z.email().optional().or(z.literal("")),
});

type FormValues = z.infer<typeof schema>;

export default function OwnerStaffPage() {
  const [salonId, setSalonId] = useState<string | null>(null);
  const [salonName, setSalonName] = useState("your salon");
  const [staff, setStaff] = useState<Barber[]>([]);
  const [loading, setLoading] = useState(true);
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      display_name: "",
      bio: "",
      specializations: "",
      invited_email: "",
    },
  });

  async function load() {
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;
    const { data: salon } = await supabase
      .from("salons")
      .select("id, name")
      .eq("owner_id", user.id)
      .limit(1)
      .maybeSingle();
    if (!salon) {
      setLoading(false);
      return;
    }
    setSalonId(salon.id);
    setSalonName(salon.name);
    const { data } = await supabase
      .from("barbers")
      .select("*")
      .eq("salon_id", salon.id)
      .order("display_name");
    setStaff((data as Barber[]) ?? []);
    setLoading(false);
  }

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- client mount data fetch
    void load();
  }, []);

  async function onSubmit(values: FormValues) {
    if (!salonId) {
      toast.error("Create your salon first");
      return;
    }
    const supabase = createClient();
    const { error } = await supabase.from("barbers").insert({
      salon_id: salonId,
      display_name: values.display_name,
      bio: values.bio || null,
      specializations: values.specializations
        ? values.specializations.split(",").map((s) => s.trim()).filter(Boolean)
        : [],
      is_active: true,
    });
    if (error) {
      toast.error(error.message);
      return;
    }

    if (values.invited_email) {
      await fetch("/api/emails", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          to: values.invited_email,
          template: "staff_invite",
          data: {
            salonName,
            ctaUrl: `${window.location.origin}/register`,
          },
        }),
      }).catch(() => undefined);
    }

    toast.success("Staff member added");
    form.reset();
    await load();
  }

  if (loading) return <p className="text-sm text-snip-muted">Loading staff...</p>;
  if (!salonId) {
    return (
      <EmptyState
        title="No salon yet"
        actionLabel="Create salon"
        actionHref="/owner/salon"
      />
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Staff</h2>
        <p className="text-sm text-snip-muted">
          Manage stylists and invite them to SNIP.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Add staff</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="grid gap-4 md:grid-cols-2">
            <div>
              <Label htmlFor="display_name">Display name</Label>
              <Input id="display_name" {...form.register("display_name")} />
            </div>
            <div>
              <Label htmlFor="invited_email">Invite email (optional)</Label>
              <Input id="invited_email" type="email" {...form.register("invited_email")} />
            </div>
            <div className="md:col-span-2">
              <Label htmlFor="specializations">Specializations (comma separated)</Label>
              <Input id="specializations" {...form.register("specializations")} />
            </div>
            <div className="md:col-span-2">
              <Label htmlFor="bio">Bio</Label>
              <Textarea id="bio" {...form.register("bio")} />
            </div>
            <div>
              <Button type="submit">Add staff</Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {staff.length === 0 ? (
        <EmptyState icon={Users} title="No staff yet" description="Add your first stylist." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {staff.map((member) => (
            <Card key={member.id}>
              <CardContent className="flex items-start gap-3 p-5">
                <Avatar name={member.display_name} src={member.avatar_url} />
                <div>
                  <p className="font-semibold text-snip-charcoal">{member.display_name}</p>
                  <p className="text-sm text-snip-muted">
                    {member.specializations?.join(", ") || "Stylist"}
                  </p>
                  {member.bio ? (
                    <p className="mt-2 text-sm text-snip-muted">{member.bio}</p>
                  ) : null}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
