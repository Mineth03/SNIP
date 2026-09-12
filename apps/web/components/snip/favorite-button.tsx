"use client";

import { useEffect, useState } from "react";
import { Heart } from "lucide-react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";

interface FavoriteButtonProps {
  salonId: string;
  initialIsFavorite?: boolean;
  className?: string;
  size?: "sm" | "md" | "lg";
}

export function FavoriteButton({
  salonId,
  initialIsFavorite = false,
  className = "",
  size = "md",
}: FavoriteButtonProps) {
  const [isFavorite, setIsFavorite] = useState(initialIsFavorite);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function checkFavorite() {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;

      const { data } = await supabase
        .from("favorites")
        .select("id")
        .eq("user_id", user.id)
        .eq("salon_id", salonId)
        .maybeSingle();

      setIsFavorite(Boolean(data));
    }

    if (initialIsFavorite === false) {
      void checkFavorite();
    }
  }, [salonId, initialIsFavorite]);

  async function handleToggle(e: React.MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      toast.error("Please sign in to save your favorite salons", {
        action: {
          label: "Sign in",
          onClick: () => {
            window.location.href = "/login";
          },
        },
      });
      return;
    }

    setLoading(true);
    const nextState = !isFavorite;
    setIsFavorite(nextState);

    try {
      if (nextState) {
        const { error } = await supabase.from("favorites").insert({
          user_id: user.id,
          salon_id: salonId,
        });
        if (error) throw error;
        toast.success("Added to favorites");
      } else {
        const { error } = await supabase
          .from("favorites")
          .delete()
          .eq("user_id", user.id)
          .eq("salon_id", salonId);
        if (error) throw error;
        toast.info("Removed from favorites");
      }
    } catch (err) {
      setIsFavorite(!nextState);
      toast.error(err instanceof Error ? err.message : "Failed to update favorite");
    } finally {
      setLoading(false);
    }
  }

  const iconSizes = {
    sm: "h-4 w-4",
    md: "h-5 w-5",
    lg: "h-6 w-6",
  };

  return (
    <button
      type="button"
      onClick={handleToggle}
      disabled={loading}
      aria-label={isFavorite ? "Remove from favorites" : "Add to favorites"}
      className={`rounded-full p-2 transition-all hover:scale-110 active:scale-95 ${
        isFavorite
          ? "bg-rose-50 text-rose-500 shadow-sm"
          : "bg-white/80 text-snip-charcoal/70 backdrop-blur-sm hover:text-rose-500 hover:bg-white"
      } ${className}`}
    >
      <Heart
        className={`${iconSizes[size]} transition-colors ${
          isFavorite ? "fill-rose-500 text-rose-500" : ""
        }`}
      />
    </button>
  );
}
