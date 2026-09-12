"use client";

import { useEffect, useState } from "react";
import { Images, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ImageUploader } from "@/components/ui/image-uploader";
import { createClient } from "@/lib/supabase/client";
import { deleteImageFromSupabase } from "@/lib/supabase/storage";
import type { SalonGallery } from "@/types/database";

export default function OwnerGalleryPage() {
  const [salonId, setSalonId] = useState<string | null>(null);
  const [items, setItems] = useState<SalonGallery[]>([]);
  const [loading, setLoading] = useState(true);
  const [newImageUrl, setNewImageUrl] = useState("");
  const [caption, setCaption] = useState("");
  const [submitting, setSubmitting] = useState(false);

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
    void load();
  }, []);

  async function handleAddImage(e: React.FormEvent) {
    e.preventDefault();
    if (!salonId || !newImageUrl) {
      toast.error("Please upload or provide an image");
      return;
    }

    setSubmitting(true);
    try {
      const supabase = createClient();
      const { error } = await supabase.from("salon_gallery").insert({
        salon_id: salonId,
        image_url: newImageUrl,
        caption: caption.trim() || null,
        sort_order: items.length,
      });

      if (error) throw error;

      toast.success("Photo added to gallery!");
      setNewImageUrl("");
      setCaption("");
      await load();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to add image");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDeleteImage(item: SalonGallery) {
    if (!confirm("Are you sure you want to delete this photo?")) return;
    try {
      const supabase = createClient();
      const { error } = await supabase
        .from("salon_gallery")
        .delete()
        .eq("id", item.id);

      if (error) throw error;

      // Clean up from storage bucket
      void deleteImageFromSupabase("salon-images", item.image_url);

      toast.success("Photo deleted");
      setItems((prev) => prev.filter((i) => i.id !== item.id));
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to delete photo");
    }
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
        <h2 className="text-2xl font-bold tracking-tight text-snip-charcoal">
          Salon Gallery
        </h2>
        <p className="text-sm text-snip-muted">
          Upload interior, exterior, and showcase cuts to attract more clients.
        </p>
      </div>

      {/* Upload New Image Card */}
      <Card className="rounded-2xl border border-snip-border shadow-snip-sm">
        <CardHeader>
          <CardTitle className="text-base font-bold text-snip-charcoal">
            Upload Showcase Photo
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleAddImage} className="space-y-4">
            <div className="grid gap-6 md:grid-cols-2">
              <div>
                <ImageUploader
                  value={newImageUrl}
                  onChange={setNewImageUrl}
                  onRemove={() => setNewImageUrl("")}
                  bucket="salon-images"
                  folder={`salons/${salonId}`}
                  label="Select or Drag Image"
                  description="JPG, PNG, or WebP up to 10MB"
                  variant="card"
                  maxSizeMB={10}
                />
              </div>

              <div className="flex flex-col justify-between space-y-4">
                <div>
                  <Label htmlFor="caption" className="text-xs font-semibold text-snip-muted">
                    Photo Caption (optional)
                  </Label>
                  <Input
                    id="caption"
                    value={caption}
                    onChange={(e) => setCaption(e.target.value)}
                    placeholder="e.g. Modern fade styling station"
                    className="mt-1"
                  />
                  <p className="mt-1 text-[11px] text-snip-muted">
                    Add a short descriptive note for prospective clients.
                  </p>
                </div>

                <Button
                  type="submit"
                  disabled={submitting || !newImageUrl}
                  className="gap-2 w-full sm:w-auto"
                >
                  <Plus className="h-4 w-4" />
                  {submitting ? "Saving..." : "Add to Gallery"}
                </Button>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Gallery Showcase Grid */}
      {items.length === 0 ? (
        <EmptyState
          icon={Images}
          title="Gallery is empty"
          description="Upload your salon's first showcase photo above."
        />
      ) : (
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {items.map((item) => (
            <Card
              key={item.id}
              className="group overflow-hidden rounded-2xl border border-snip-border shadow-snip-sm transition-all hover:shadow-snip"
            >
              <div className="relative aspect-[16/10] overflow-hidden bg-slate-100">
                <img
                  src={item.image_url}
                  alt={item.caption ?? "Salon photo"}
                  className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                />
                <button
                  type="button"
                  onClick={() => handleDeleteImage(item)}
                  aria-label="Delete photo"
                  className="absolute right-2 top-2 rounded-full bg-black/60 p-2 text-white opacity-0 transition-opacity hover:bg-red-600 group-hover:opacity-100"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
              {item.caption && (
                <CardContent className="p-3 text-xs font-medium text-snip-charcoal">
                  {item.caption}
                </CardContent>
              )}
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
