import Link from "next/link";
import { Clock } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency, formatDuration } from "@/lib/utils";
import type { Service } from "@/types/database";

export function ServiceCard({
  service,
  bookHref,
}: {
  service: Pick<
    Service,
    "id" | "name" | "description" | "category" | "price" | "duration_minutes"
  >;
  bookHref?: string;
}) {
  return (
    <Card>
      <CardContent className="flex flex-col gap-4 p-5 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="font-semibold text-snip-charcoal">{service.name}</h3>
            <Badge variant="outline" className="capitalize">
              {service.category}
            </Badge>
          </div>
          {service.description ? (
            <p className="text-sm text-snip-muted">{service.description}</p>
          ) : null}
          <div className="flex items-center gap-3 text-sm text-snip-muted">
            <span className="font-semibold text-snip-charcoal">
              {formatCurrency(service.price)}
            </span>
            <span className="inline-flex items-center gap-1">
              <Clock className="h-3.5 w-3.5" />
              {formatDuration(service.duration_minutes)}
            </span>
          </div>
        </div>
        {bookHref ? (
          <Link href={bookHref}>
            <Button type="button">Book</Button>
          </Link>
        ) : null}
      </CardContent>
    </Card>
  );
}
