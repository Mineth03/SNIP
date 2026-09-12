"use client";

import { useRef, useState } from "react";
import Image from "next/image";
import { ImagePlus, Loader2, Trash2, UploadCloud } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { uploadImageToSupabase, type StorageBucket } from "@/lib/supabase/storage";
import { cn } from "@/lib/utils";

export interface ImageUploaderProps {
  value?: string | null;
  onChange: (url: string) => void;
  onRemove?: () => void;
  bucket: StorageBucket;
  folder?: string;
  label?: string;
  description?: string;
  variant?: "avatar" | "cover" | "card";
  maxSizeMB?: number;
  className?: string;
}

export function ImageUploader({
  value,
  onChange,
  onRemove,
  bucket,
  folder,
  label = "Upload Image",
  description = "PNG, JPG or WebP up to 5MB",
  variant = "card",
  maxSizeMB = 5,
  className,
}: ImageUploaderProps) {
  const [uploading, setUploading] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  async function handleFile(file: File) {
    setUploading(true);
    try {
      const publicUrl = await uploadImageToSupabase({
        file,
        bucket,
        folder,
        maxSizeMB,
      });
      onChange(publicUrl);
      toast.success("Image uploaded successfully!");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to upload image");
    } finally {
      setUploading(false);
    }
  }

  function onFileInputChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) {
      void handleFile(file);
    }
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files?.[0];
    if (file) {
      void handleFile(file);
    }
  }

  if (variant === "avatar") {
    return (
      <div className={cn("flex items-center gap-4", className)}>
        <input
          ref={inputRef}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="hidden"
          onChange={onFileInputChange}
          disabled={uploading}
        />
        <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-full border-2 border-snip-border bg-snip-bg shadow-sm">
          {value ? (
            <img
              src={value}
              alt="Avatar preview"
              className="h-full w-full object-cover"
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-snip-muted">
              <ImagePlus className="h-8 w-8 text-snip-muted/60" />
            </div>
          )}
          {uploading && (
            <div className="absolute inset-0 flex items-center justify-center bg-black/40 text-white">
              <Loader2 className="h-6 w-6 animate-spin text-snip-teal" />
            </div>
          )}
        </div>

        <div className="space-y-1.5">
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={uploading}
            onClick={() => inputRef.current?.click()}
          >
            {value ? "Change Avatar" : "Upload Avatar"}
          </Button>
          <p className="text-xs text-snip-muted">{description}</p>
        </div>
      </div>
    );
  }

  return (
    <div className={cn("space-y-2", className)}>
      {label && <label className="block text-xs font-semibold text-snip-charcoal">{label}</label>}

      <input
        ref={inputRef}
        type="file"
        accept="image/png,image/jpeg,image/webp"
        className="hidden"
        onChange={onFileInputChange}
        disabled={uploading}
      />

      {value ? (
        <div
          className={cn(
            "group relative overflow-hidden rounded-2xl border border-snip-border bg-slate-50",
            variant === "cover" ? "aspect-[21/9]" : "aspect-[16/10]",
          )}
        >
          <img
            src={value}
            alt="Uploaded preview"
            className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
          />
          <div className="absolute inset-0 bg-black/30 opacity-0 transition-opacity group-hover:opacity-100 flex items-center justify-center gap-2">
            <Button
              type="button"
              size="sm"
              variant="secondary"
              onClick={() => inputRef.current?.click()}
              disabled={uploading}
            >
              Replace
            </Button>
            {onRemove && (
              <Button
                type="button"
                size="sm"
                variant="danger"
                onClick={onRemove}
                disabled={uploading}
              >
                <Trash2 className="h-3.5 w-3.5" />
              </Button>
            )}
          </div>
        </div>
      ) : (
        <div
          onClick={() => !uploading && inputRef.current?.click()}
          onDragOver={(e) => {
            e.preventDefault();
            setIsDragging(true);
          }}
          onDragLeave={() => setIsDragging(false)}
          onDrop={handleDrop}
          className={cn(
            "flex cursor-pointer flex-col items-center justify-center rounded-2xl border-2 border-dashed p-6 text-center transition-all",
            variant === "cover" ? "py-10" : "py-8",
            isDragging
              ? "border-snip-primary bg-snip-primary/10"
              : "border-snip-border bg-white hover:border-snip-primary/50 hover:bg-slate-50/70",
            uploading && "pointer-events-none opacity-60",
          )}
        >
          {uploading ? (
            <div className="flex flex-col items-center gap-2">
              <Loader2 className="h-8 w-8 animate-spin text-snip-primary" />
              <p className="text-xs font-semibold text-snip-charcoal">Uploading to Supabase...</p>
            </div>
          ) : (
            <>
              <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-full bg-snip-primary/10 text-snip-teal">
                <UploadCloud className="h-5 w-5" />
              </div>
              <p className="text-xs font-bold text-snip-charcoal">
                Click to upload <span className="font-normal text-snip-muted">or drag & drop</span>
              </p>
              <p className="mt-1 text-[11px] text-snip-muted">{description}</p>
            </>
          )}
        </div>
      )}
    </div>
  );
}
