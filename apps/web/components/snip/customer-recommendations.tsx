import Link from "next/link";
import { Sparkles, MapPin, Star, History, ArrowRight } from "lucide-react";
import { FavoriteButton } from "@/components/snip/favorite-button";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import type { RecommendedSalon, UserRecentActivity } from "@/types/database";

interface CustomerRecommendationsProps {
  recommendations: RecommendedSalon[];
  recentActivities?: UserRecentActivity[];
}

export function CustomerRecommendations({
  recommendations,
  recentActivities = [],
}: CustomerRecommendationsProps) {
  if (!recommendations || recommendations.length === 0) {
    return null;
  }

  return (
    <div className="space-y-6">
      {/* Recent Activity Mini-Ticker if present */}
      {recentActivities.length > 0 && (
        <div className="rounded-2xl border border-snip-border bg-white p-4 shadow-snip-sm">
          <div className="mb-2.5 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-snip-muted">
            <History className="h-3.5 w-3.5 text-snip-teal" />
            <span>Based on your recent activity</span>
          </div>
          <div className="flex flex-wrap gap-2">
            {recentActivities.map((act) => {
              const label =
                act.activity_type === "book_appointment"
                  ? `Booked ${act.service_name ?? "Appointment"} at ${act.salon_name ?? "Salon"}`
                  : act.activity_type === "view_salon"
                    ? `Viewed ${act.salon_name ?? "Salon"}`
                    : act.activity_type === "favorite_salon"
                      ? `Saved ${act.salon_name ?? "Salon"}`
                      : act.activity_type === "review_salon"
                        ? `Reviewed ${act.salon_name ?? "Salon"}`
                        : `Searched in ${act.category ?? "Services"}`;

              const targetUrl = act.salon_slug
                ? `/salons/${act.salon_slug}`
                : "/explore";

              return (
                <Link
                  key={act.id}
                  href={targetUrl}
                  className="group flex items-center gap-1.5 rounded-full border border-snip-border bg-snip-bg px-3 py-1 text-xs font-medium text-snip-charcoal transition hover:border-snip-teal/50 hover:bg-snip-primary/10 hover:text-snip-teal"
                >
                  <span className="h-1.5 w-1.5 rounded-full bg-snip-teal" />
                  <span>{label}</span>
                </Link>
              );
            })}
          </div>
        </div>
      )}

      {/* Recommended Section */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="space-y-0.5">
            <div className="flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-snip-teal" />
              <h3 className="text-lg font-bold text-snip-charcoal">
                Recommended For You
              </h3>
            </div>
            <p className="text-xs text-snip-muted">
              Personalized based on your styling preferences, past bookings, and location
            </p>
          </div>
          <Link
            href="/explore"
            className="flex items-center gap-1 text-xs font-bold text-snip-teal transition hover:underline"
          >
            <span>Explore all</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {recommendations.map((salon) => {
            const rating = Number(salon.avg_rating ?? 0);
            const reviews = Number(salon.review_count ?? 0);
            const dist =
              salon.distance_km != null ? Number(salon.distance_km) : null;

            return (
              <div key={salon.id} className="group relative">
                <Link href={`/salons/${salon.slug}`} className="block">
                  <Card className="overflow-hidden border-snip-border bg-white transition hover:-translate-y-0.5 hover:shadow-snip">
                    {/* Cover image & badges */}
                    <div className="relative h-36 bg-linear-to-br from-snip-teal/20 via-snip-primary/10 to-snip-bg-muted">
                      {salon.cover_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={salon.cover_url}
                          alt=""
                          className="h-full w-full object-cover transition group-hover:scale-[1.02]"
                        />
                      ) : null}

                      {/* Distance badge */}
                      {dist !== null && (
                        <div className="absolute bottom-2.5 left-2.5 flex items-center gap-1 rounded-full bg-snip-charcoal/80 px-2.5 py-1 text-[11px] font-semibold text-white backdrop-blur-xs">
                          <MapPin className="h-3 w-3 text-snip-teal" />
                          <span>
                            {dist < 1
                              ? `${Math.round(dist * 1000)} m away`
                              : `${dist.toFixed(1)} km away`}
                          </span>
                        </div>
                      )}
                    </div>

                    <div className="p-4 space-y-2.5">
                      {/* Personalization reason pill */}
                      <div className="inline-flex items-center gap-1.5 rounded-md bg-snip-primary/15 px-2.5 py-1 text-[11px] font-bold text-snip-teal">
                        <Sparkles className="h-3 w-3 shrink-0" />
                        <span className="line-clamp-1">
                          {salon.recommendation_reason}
                        </span>
                      </div>

                      <div className="flex items-start justify-between gap-2">
                        <h4 className="font-bold text-snip-charcoal line-clamp-1 group-hover:text-snip-teal transition">
                          {salon.name}
                        </h4>
                        <div className="flex items-center gap-1 shrink-0 text-xs font-bold text-snip-charcoal">
                          <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                          <span>{rating > 0 ? rating.toFixed(1) : "New"}</span>
                          {reviews > 0 && (
                            <span className="text-snip-muted text-[11px] font-normal">
                              ({reviews})
                            </span>
                          )}
                        </div>
                      </div>

                      <div className="flex items-center justify-between text-xs text-snip-muted pt-1 border-t border-snip-border/60">
                        <span className="line-clamp-1">
                          {salon.city ?? salon.address ?? "Sri Lanka"}
                        </span>
                        <span className="font-semibold text-snip-teal group-hover:underline">
                          Book now →
                        </span>
                      </div>
                    </div>
                  </Card>
                </Link>

                {/* Favorite Button */}
                <div className="absolute right-3 top-3 z-10">
                  <FavoriteButton salonId={salon.id} />
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
