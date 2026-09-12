import type { LucideIcon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export function MetricCard({
  label,
  value,
  hint,
  icon: Icon,
  trend,
  className,
}: {
  label: string;
  value: string | number;
  hint?: string;
  icon?: LucideIcon;
  trend?: string;
  className?: string;
}) {
  return (
    <Card className={cn("overflow-hidden", className)}>
      <CardContent className="flex items-start justify-between gap-4 p-5">
        <div className="space-y-2">
          <p className="text-sm text-snip-muted">{label}</p>
          <p className="text-2xl font-semibold tracking-tight text-snip-charcoal">
            {value}
          </p>
          {(hint || trend) && (
            <p className="text-xs text-snip-muted">
              {trend ? <span className="text-snip-success">{trend}</span> : null}
              {trend && hint ? " · " : null}
              {hint}
            </p>
          )}
        </div>
        {Icon ? (
          <div className="rounded-md bg-snip-primary/10 p-2.5 text-snip-teal">
            <Icon className="h-5 w-5" />
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
