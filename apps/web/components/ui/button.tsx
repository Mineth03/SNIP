import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-full text-sm font-semibold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-snip-primary/40 disabled:pointer-events-none disabled:opacity-50 cursor-pointer",
  {
    variants: {
      variant: {
        primary:
          "bg-snip-primary text-white shadow-snip-sm hover:bg-snip-primary-hover",
        secondary:
          "bg-snip-bg-muted text-snip-charcoal border border-snip-border shadow-snip-sm hover:bg-snip-border",
        dark:
          "bg-snip-charcoal text-white shadow-snip-sm hover:bg-snip-charcoal/90",
        outline:
          "border border-snip-border bg-white text-snip-charcoal hover:bg-snip-bg-muted",
        ghost: "text-snip-charcoal hover:bg-snip-bg-muted",
        danger: "bg-snip-danger text-white hover:bg-red-600",
        soft: "bg-snip-primary/10 text-snip-teal hover:bg-snip-primary/15",
      },
      size: {
        sm: "h-8 px-3.5 text-xs",
        md: "h-10 px-5",
        lg: "h-12 px-7 text-base font-bold",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  },
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => (
    <button
      ref={ref}
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    />
  ),
);
Button.displayName = "Button";

export { buttonVariants };
