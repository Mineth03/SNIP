"use client";

import React, { useEffect, useState } from "react";
import { useTheme } from "next-themes";
import { cn } from "@/lib/utils";

export type SnipLogoVariant = "horizontal" | "stacked" | "icon";

interface SnipLogoProps {
  /**
   * Layout variant:
   * - "horizontal" (default): Wide logo banner, ideal for navbars, topbars, and headers.
   * - "stacked": Square emblem, ideal for footers, centered hero, and auth forms.
   * - "icon": Icon view.
   */
  variant?: SnipLogoVariant;
  /**
   * The height of the logo in pixels.
   * Defaults to 44 for horizontal, 60 for stacked.
   */
  size?: number;
  /**
   * Maintained for backwards-compatibility.
   */
  showText?: boolean;
  /**
   * Maintained for backwards-compatibility.
   */
  showTagline?: boolean;
  /**
   * Additional Tailwind / CSS classes.
   */
  className?: string;
  /**
   * Optional manual override.
   * When true, explicitly forces the white & teal original dark mode asset.
   * When false, explicitly forces the dark charcoal & teal original main asset.
   * When undefined, automatically follows the current active theme (light or dark).
   */
  light?: boolean;
}

export function SnipLogo({
  variant = "horizontal",
  size,
  className,
  light,
}: SnipLogoProps) {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const isDark = light !== undefined ? light : (mounted && resolvedTheme === "dark");

  const effectiveHeight = size ?? (variant === "stacked" ? 64 : 44);

  // If stacked, use the square logos (SNIP-main-logo / SNIP-dark-mode-logo)
  // If horizontal, use the wide logos (long-logo-original / long-logo-dark-mode)
  const logoSrc = variant === "stacked"
    ? (isDark ? "/SNIP-dark-mode-logo.png" : "/SNIP-main-logo.png")
    : (isDark ? "/long-logo-dark-mode.png" : "/long-logo-original.png");

  return (
    <div
      className={cn("inline-flex items-center justify-center shrink-0 select-none", className)}
      style={{ height: effectiveHeight, width: "auto" }}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={logoSrc}
        alt="SNIP — Book • Manage • Grow"
        style={{ height: `${effectiveHeight}px`, width: "auto" }}
        className="object-contain pointer-events-none transition-opacity duration-200"
      />
    </div>
  );
}
