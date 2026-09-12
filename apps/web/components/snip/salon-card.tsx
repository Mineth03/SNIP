import Link from "next/link";
import { MapPin, Navigation, Star } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { FavoriteButton } from "@/components/snip/favorite-button";
import type { Salon } from "@/types/database";

export function SalonCard({
  salon,
  href,
}: {
  salon: Pick<
    Salon,
    | "id"
    | "name"
    | "slug"
    | "city"
    | "address"
    | "description"
    | "cover_url"
    | "logo_url"
    | "verification_status"
  > & {
    avg_rating?: number;
    review_count?: number;
    distance_km?: number | null;
  };
  href?: string;
}) {
  const link = href ?? `/salons/${salon.slug}`;
  const rating = Number(salon.avg_rating ?? 0);
  const reviews = Number(salon.review_count ?? 0);
  const dist = salon.distance_km != null ? Number(salon.distance_km) : null;

  return (
    <div className="group relative">
      <Link href={link} className="block">
        <Card className="overflow-hidden transition hover:-translate-y-0.5 hover:shadow-snip">
          <div className="relative h-40 bg-linear-to-br from-snip-teal/20 via-snip-primary/10 to-snip-bg-muted">
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

            {dist != null ? (
              <span className="absolute bottom-2.5 left-2.5 inline-flex items-center gap-1 rounded-full bg-white/95 px-2.5 py-0.5 text-[11px] font-bold text-snip-teal shadow-xs backdrop-blur-xs border border-snip-teal/25">
                <Navigation className="h-3 w-3" />
                {dist < 1 ? `${Math.round(dist * 1000)} m away` : `${dist.toFixed(1)} km away`}
              </span>
            ) : null}
          </div>
          <div className="space-y-2 p-4">
            <div className="flex items-start justify-between gap-2">
              <h3 className="font-semibold text-snip-charcoal group-hover:text-snip-teal line-clamp-1">
                {salon.name}
              </h3>
              <span className="inline-flex shrink-0 items-center gap-1 text-xs text-snip-muted">
                <Star
                  className={`h-3.5 w-3.5 ${
                    rating > 0 ? "fill-amber-400 text-amber-400" : "text-snip-muted"
                  }`}
                />
                {rating > 0 ? rating.toFixed(1) : "New"}
                {reviews > 0 ? ` (${reviews})` : ""}
              </span>
            </div>
            <p className="line-clamp-2 text-sm text-snip-muted">
              {salon.description ?? "Premium salon experience on SNIP."}
            </p>
            <p className="flex items-center gap-1.5 text-xs text-snip-muted">
              <MapPin className="h-3.5 w-3.5 shrink-0" />
              <span className="truncate">
                {[salon.address, salon.city].filter(Boolean).join(", ") || "City TBA"}
              </span>
            </p>
          </div>
        </Card>
      </Link>
      {salon.id ? (
        <div className="absolute top-2.5 right-2.5 z-10">
          <FavoriteButton salonId={salon.id} size="sm" />
        </div>
      ) : null}
    </div>
  );
}
