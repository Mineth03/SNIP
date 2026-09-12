"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Images } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createClient } from "@/lib/supabase/client";
import type { SalonGallery } from "@/types/database";

const schema = z.object({
  image_url: z.url("Enter a valid image URL"),
  caption: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export default function OwnerGalleryPage() {
  const [salonId, setSalonId] = useState<string | null>(null);
  const [items, setItems] = useState<SalonGallery[]>([]);
  const [loading, setLoading] = useState(true);
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { image_url: "", caption: "" },
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
      .from("salon_gallery")
      .select("*")
      .eq("salon_id", salon.id)
      .order("sort_order");
    setItems((data as SalonGallery[]) ?? []);
    setLoading(false);
  }

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- client mount data fetch
    void load();
  }, []);

  async function onSubmit(values: FormValues) {
    if (!salonId) return;
    const supabase = createClient();
    const { error } = await supabase.from("salon_gallery").insert({
      salon_id: salonId,
      image_url: values.image_url,
      caption: values.caption || null,
      sort_order: items.length,
    });
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Image added");
    form.reset();
    await load();
  }

  if (loading) return <p className="text-sm text-snip-muted">Loading gallery...</p>;
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
        <h2 className="text-2xl font-semibold text-snip-charcoal">Gallery</h2>
        <p className="text-sm text-snip-muted">Showcase your salon’s best work.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Add image</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="grid gap-4 md:grid-cols-[1fr_1fr_auto]">
            <div>
              <Label htmlFor="image_url">Image URL</Label>
              <Input id="image_url" {...form.register("image_url")} />
            </div>
            <div>
              <Label htmlFor="caption">Caption</Label>
              <Input id="caption" {...form.register("caption")} />
            </div>
            <div className="flex items-end">
              <Button type="submit">Add</Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {items.length === 0 ? (
        <EmptyState icon={Images} title="Gallery is empty" description="Add image URLs to build your showcase." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {items.map((item) => (
            <Card key={item.id} className="overflow-hidden">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={item.image_url} alt={item.caption ?? ""} className="h-44 w-full object-cover" />
              {item.caption ? (
                <CardContent className="p-3 text-sm text-snip-muted">{item.caption}</CardContent>
              ) : null}
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
