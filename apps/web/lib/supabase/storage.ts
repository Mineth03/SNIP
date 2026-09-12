import { createClient } from "@/lib/supabase/client";

export type StorageBucket =
  | "avatars"
  | "salon-images"
  | "service-images"
  | "barber-portfolios";

export interface UploadImageOptions {
  file: File;
  bucket: StorageBucket;
  folder?: string;
  maxSizeMB?: number;
}

export async function uploadImageToSupabase({
  file,
  bucket,
  folder,
  maxSizeMB = 5,
}: UploadImageOptions): Promise<string> {
  // 1. Validate file size
  const maxBytes = maxSizeMB * 1024 * 1024;
  if (file.size > maxBytes) {
    throw new Error(`Image size exceeds the maximum allowed limit of ${maxSizeMB}MB`);
  }

  // 2. Validate MIME type
  const allowedTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];
  if (!allowedTypes.includes(file.type)) {
    throw new Error("Only JPG, PNG, and WebP images are supported");
  }

  const supabase = createClient();

  // 3. Generate unique file path
  const ext = file.name.split(".").pop()?.toLowerCase() || "jpg";
  const uniqueName = `${Date.now()}-${crypto.randomUUID().slice(0, 8)}.${ext}`;
  const filePath = folder ? `${folder.replace(/\/+$/, "")}/${uniqueName}` : uniqueName;

  // 4. Upload file to Supabase Storage
  const { error: uploadError } = await supabase.storage
    .from(bucket)
    .upload(filePath, file, {
      cacheControl: "3600",
      upsert: true,
      contentType: file.type,
    });

  if (uploadError) {
    throw new Error(`Upload failed: ${uploadError.message}`);
  }

  // 5. Get public URL
  const { data } = supabase.storage.from(bucket).getPublicUrl(filePath);
  if (!data?.publicUrl) {
    throw new Error("Failed to generate public URL for uploaded image");
  }

  return data.publicUrl;
}

export async function deleteImageFromSupabase(
  bucket: StorageBucket,
  publicUrlOrPath: string,
): Promise<void> {
  const supabase = createClient();

  let filePath = publicUrlOrPath;
  if (publicUrlOrPath.startsWith("http")) {
    const parts = publicUrlOrPath.split(`/${bucket}/`);
    if (parts.length > 1) {
      filePath = parts[1];
    }
  }

  const { error } = await supabase.storage.from(bucket).remove([filePath]);
  if (error) {
    console.error(`Error deleting image from ${bucket}:`, error.message);
  }
}
