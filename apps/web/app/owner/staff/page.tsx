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
  invited_email: z.string().email("Enter a valid email"),
});

type FormValues = z.infer<typeof schema>;

type MemberRow = Barber & {
  pending_email?: string | null;
};

export default function OwnerStaffPage() {
  const [salonId, setSalonId] = useState<string | null>(null);
  const [salonName, setSalonName] = useState("your salon");
  const [staff, setStaff] = useState<MemberRow[]>([]);
  const [pending, setPending] = useState<
    { id: string; invited_email: string | null; invitation_token: string | null }[]
  >([]);
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

    const [{ data: barbers }, { data: members }] = await Promise.all([
      supabase
        .from("barbers")
        .select("*")
        .eq("salon_id", salon.id)
        .order("display_name"),
      supabase
        .from("salon_members")
        .select("id, invited_email, invitation_token, invitation_accepted_at, is_active, profile_id")
        .eq("salon_id", salon.id)
        .eq("member_role", "barber"),
    ]);

    setStaff((barbers as Barber[]) ?? []);
    setPending(
      (members ?? [])
        .filter((m) => !m.invitation_accepted_at && m.is_active)
        .map((m) => ({
          id: m.id as string,
          invited_email: m.invited_email as string | null,
          invitation_token: m.invitation_token as string | null,
        })),
    );
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
    const { data, error } = await supabase.rpc("invite_barber_to_salon", {
      p_salon_id: salonId,
      p_email: values.invited_email,
      p_display_name: values.display_name,
    });

    if (error) {
      toast.error(error.message);
      return;
    }

    const invite = data as {
      invitation_token?: string;
      barber_id?: string;
      email?: string;
    };

    if (invite.barber_id && (values.bio || values.specializations)) {
      await supabase
        .from("barbers")
        .update({
          bio: values.bio || null,
          specializations: values.specializations
            ? values.specializations.split(",").map((s) => s.trim()).filter(Boolean)
            : [],
        })
        .eq("id", invite.barber_id);
    }

    if (invite.invitation_token && invite.email) {
      await fetch("/api/emails", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          to: invite.email,
          template: "staff_invite",
          data: {
            salonName,
            ctaUrl: `${window.location.origin}/invite/barber?token=${invite.invitation_token}`,
          },
        }),
      }).catch(() => undefined);
    }

    toast.success("Invitation sent");
    form.reset();
    await load();
  }

  async function removeBarber(barberId: string) {
    if (!salonId) return;
    if (!window.confirm("Remove this barber from your salon?")) return;
    const supabase = createClient();
    const { error } = await supabase.rpc("remove_barber_from_salon", {
      p_salon_id: salonId,
      p_barber_id: barberId,
    });
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Staff member removed");
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
          Invite stylists by email. They join with their SNIP account and can leave or
          join other salons later.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Invite staff</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="grid gap-4 md:grid-cols-2">
            <div>
              <Label htmlFor="display_name">Display name</Label>
              <Input id="display_name" {...form.register("display_name")} />
            </div>
            <div>
              <Label htmlFor="invited_email">Invite email</Label>
              <Input id="invited_email" type="email" {...form.register("invited_email")} />
              {form.formState.errors.invited_email ? (
                <p className="mt-1 text-xs text-snip-danger">
                  {form.formState.errors.invited_email.message}
                </p>
              ) : null}
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
              <Button type="submit">Send invite</Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {pending.length > 0 ? (
        <Card>
          <CardHeader>
            <CardTitle>Pending invites</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {pending.map((row) => (
              <div
                key={row.id}
                className="flex items-center justify-between rounded-lg border border-snip-border px-3 py-2 text-sm"
              >
                <span>{row.invited_email}</span>
                <span className="text-xs text-amber-600">Awaiting accept</span>
              </div>
            ))}
          </CardContent>
        </Card>
      ) : null}

      {staff.filter((s) => s.is_active).length === 0 ? (
        <EmptyState icon={Users} title="No active staff yet" description="Invite your first stylist." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {staff
            .filter((s) => s.is_active)
            .map((member) => (
              <Card key={member.id}>
                <CardContent className="flex items-start gap-3 p-5">
                  <Avatar name={member.display_name} src={member.avatar_url} />
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold text-snip-charcoal">{member.display_name}</p>
                    <p className="text-sm text-snip-muted">
                      {member.specializations?.join(", ") || "Stylist"}
                    </p>
                    <p className="mt-1 text-[11px] text-snip-muted">
                      {member.profile_id ? "Linked account" : "Catalog only / unlinked"}
                    </p>
                    {member.bio ? (
                      <p className="mt-2 text-sm text-snip-muted">{member.bio}</p>
                    ) : null}
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="mt-3"
                      onClick={() => removeBarber(member.id)}
                    >
                      Remove
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
        </div>
      )}
    </div>
  );
}
