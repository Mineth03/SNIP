"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Scissors } from "lucide-react";
import { ServiceCard } from "@/components/snip/service-card";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";
import type { Service, ServiceCategory } from "@/types/database";

const schema = z.object({
  name: z.string().min(2),
  description: z.string().optional(),
  category: z.enum([
    "hair",
    "beard",
    "nails",
    "facial",
    "massage",
    "color",
    "other",
  ]),
  price: z.number().min(0),
  duration_minutes: z.number().min(5).max(480),
});

type FormValues = z.infer<typeof schema>;

export default function OwnerServicesPage() {
  const [salonId, setSalonId] = useState<string | null>(null);
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: "",
      description: "",
      category: "hair",
      price: 499,
      duration_minutes: 30,
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
      .select("id")
      .eq("owner_id", user.id)
      .limit(1)
      .maybeSingle();
    if (!salon) {
      setLoading(false);
      return;
    }
    setSalonId(salon.id);
    const { data } = await supabase
      .from("services")
      .select("*")
      .eq("salon_id", salon.id)
      .order("name");
    setServices((data as Service[]) ?? []);
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
    const { error } = await supabase.from("services").insert({
      salon_id: salonId,
      name: values.name,
      description: values.description || null,
      category: values.category as ServiceCategory,
      price: values.price,
      duration_minutes: values.duration_minutes,
      is_active: true,
    });
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Service added");
    form.reset({
      name: "",
      description: "",
      category: "hair",
      price: 499,
      duration_minutes: 30,
    });
    await load();
  }

  if (loading) {
    return <p className="text-sm text-snip-muted">Loading services...</p>;
  }

  if (!salonId) {
    return (
      <EmptyState
        title="No salon yet"
        description="Create your salon before adding services."
        actionLabel="Create salon"
        actionHref="/owner/salon"
      />
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Services</h2>
        <p className="text-sm text-snip-muted">
          Define what guests can book at your salon.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Add service</CardTitle>
        </CardHeader>
        <CardContent>
          <form
            onSubmit={form.handleSubmit(onSubmit)}
            className="grid gap-4 md:grid-cols-2"
          >
            <div className="md:col-span-2">
              <Label htmlFor="name">Name</Label>
              <Input id="name" {...form.register("name")} />
            </div>
            <div className="md:col-span-2">
              <Label htmlFor="description">Description</Label>
              <Textarea id="description" {...form.register("description")} />
            </div>
            <div>
              <Label htmlFor="category">Category</Label>
              <select
                id="category"
                className="flex h-11 w-full rounded-md border border-snip-border bg-white px-3 text-sm"
                {...form.register("category")}
              >
                {[
                  "hair",
                  "beard",
                  "nails",
                  "facial",
                  "massage",
                  "color",
                  "other",
                ].map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <Label htmlFor="price">Price (LKR)</Label>
              <Input id="price" type="number" {...form.register("price", { valueAsNumber: true })} />
            </div>
            <div>
              <Label htmlFor="duration_minutes">Duration (min)</Label>
              <Input
                id="duration_minutes"
                type="number"
                {...form.register("duration_minutes", { valueAsNumber: true })}
              />
            </div>
            <div className="md:col-span-2">
              <Button type="submit">Add service</Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {services.length === 0 ? (
        <EmptyState
          icon={Scissors}
          title="No services yet"
          description="Add your first service to start accepting bookings."
        />
      ) : (
        <div className="space-y-3">
          {services.map((service) => (
            <ServiceCard key={service.id} service={service} />
          ))}
        </div>
      )}
    </div>
  );
}
