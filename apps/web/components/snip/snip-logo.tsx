import React from "react";
import { cn } from "@/lib/utils";

interface SnipLogoProps {
  size?: number;
  showText?: boolean;
  showTagline?: boolean;
  className?: string;
  light?: boolean;
}

export function SnipLogo({
  size = 32,
  showText = true,
  showTagline = false,
  className,
  light = false,
}: SnipLogoProps) {
  return (
    <div className={cn("inline-flex items-center gap-2.5", className)}>
      <svg
        width={size}
        height={size}
        viewBox="0 0 40 40"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="shrink-0"
      >
        {/* Top-left loop */}
        <circle
          cx="14"
          cy="12"
          r="7"
          stroke="#14B8A6"
          strokeWidth="3.5"
          fill="none"
        />
        {/* Bottom-right loop */}
        <circle
          cx="26"
          cy="28"
          r="7"
          stroke="#14B8A6"
          strokeWidth="3.5"
          fill="none"
        />
        {/* Diagonal blade 1 */}
        <path
          d="M18 14L31 8"
          stroke="#14B8A6"
          strokeWidth="3.5"
          strokeLinecap="round"
        />
        {/* Diagonal blade 2 */}
        <path
          d="M22 26L9 32"
          stroke="#14B8A6"
          strokeWidth="3.5"
          strokeLinecap="round"
        />
        {/* Pivot dot */}
        <circle cx="20" cy="20" r="2.5" fill="#14B8A6" />
      </svg>
      {showText && (
        <div className="flex flex-col">
          <span
            className={cn(
              "font-black tracking-wider leading-none",
              light ? "text-white" : "text-snip-charcoal",
            )}
            style={{ fontSize: `${size * 0.7}px` }}
          >
            SNIP
          </span>
          {showTagline && (
            <span
              className="font-semibold text-snip-teal tracking-widest mt-0.5 leading-none"
              style={{ fontSize: `${Math.max(size * 0.22, 9)}px` }}
            >
              BOOK • MANAGE • GROW
            </span>
          )}
        </div>
      )}
    </div>
  );
}
