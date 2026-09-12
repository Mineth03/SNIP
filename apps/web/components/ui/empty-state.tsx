import type { LucideIcon } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function EmptyState({
  icon: Icon,
  title,
  description,
  actionLabel,
  actionHref,
  onAction,
  className,
}: {
  icon?: LucideIcon;
  title: string;
  description?: string;
  actionLabel?: string;
  actionHref?: string;
  onAction?: () => void;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "flex flex-col items-center justify-center rounded-lg border border-dashed border-snip-border bg-white px-6 py-14 text-center",
        className,
      )}
    >
      {Icon ? (
        <div className="mb-4 rounded-full bg-snip-bg-muted p-3 text-snip-muted">
          <Icon className="h-6 w-6" />
        </div>
      ) : null}
      <h3 className="text-base font-semibold text-snip-charcoal">{title}</h3>
      {description ? (
        <p className="mt-2 max-w-md text-sm text-snip-muted">{description}</p>
      ) : null}
      {actionLabel && actionHref ? (
        <Link href={actionHref} className="mt-5">
          <Button type="button">{actionLabel}</Button>
        </Link>
      ) : null}
      {actionLabel && onAction && !actionHref ? (
        <Button type="button" className="mt-5" onClick={onAction}>
          {actionLabel}
        </Button>
      ) : null}
    </div>
  );
}
