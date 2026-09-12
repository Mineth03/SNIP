import Link from "next/link";
import { MapPin, Star } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import type { Salon } from "@/types/database";

export function SalonCard({
  salon,
  href,
}: {
  salon: Pick<
    Salon,
    | "name"
    | "slug"
    | "city"
    | "address"
    | "description"
    | "cover_url"
    | "logo_url"
    | "verification_status"
  >;
  href?: string;
}) {
  const link = href ?? `/salons/${salon.slug}`;

  return (
    <Link href={link} className="group block">
      <Card className="overflow-hidden transition hover:-translate-y-0.5 hover:shadow-snip">
        <div className="relative h-40 bg-gradient-to-br from-snip-teal/20 via-snip-primary/10 to-snip-bg-muted">
          {salon.cover_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={salon.cover_url}
              alt=""
              className="h-full w-full object-cover transition group-hover:scale-[1.02]"
            />
          ) : null}
          {salon.verification_status === "verified" ? (
            <Badge variant="success" className="absolute left-3 top-3">
              Verified
            </Badge>
          ) : null}
        </div>
        <div className="space-y-2 p-4">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-semibold text-snip-charcoal group-hover:text-snip-teal">
              {salon.name}
            </h3>
            <span className="inline-flex items-center gap-1 text-xs text-snip-muted">
              <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
              4.8
            </span>
          </div>
          <p className="line-clamp-2 text-sm text-snip-muted">
            {salon.description ?? "Premium salon experience on SNIP."}
          </p>
          <p className="flex items-center gap-1.5 text-xs text-snip-muted">
            <MapPin className="h-3.5 w-3.5" />
            {[salon.address, salon.city].filter(Boolean).join(", ") || "City TBA"}
          </p>
        </div>
      </Card>
    </Link>
  );
}
