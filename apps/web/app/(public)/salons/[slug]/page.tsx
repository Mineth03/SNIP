import Link from "next/link";
import { notFound } from "next/navigation";
import { MapPin, Phone, Star, Sparkles, MessageSquare, ImageIcon } from "lucide-react";
import { format } from "date-fns";
import { ServiceCard } from "@/components/snip/service-card";
import { FavoriteButton } from "@/components/snip/favorite-button";
import { TrackSalonView } from "@/components/snip/track-salon-view";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { createClient } from "@/lib/supabase/server";
import type { Barber, Salon, Service, SalonGallery } from "@/types/database";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  return { title: `${slug.replace(/-/g, " ")} | SNIP` };
}

export default async function SalonDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const supabase = await createClient();

  const { data: salon } = await supabase
    .from("salons")
    .select("*")
    .eq("slug", slug)
    .maybeSingle();

  if (!salon) notFound();

  const salonRow = salon as Salon;

  const [
    { data: services },
    { data: barbers },
    { data: gallery },
    { data: reviews },
  ] = await Promise.all([
    supabase
      .from("services")
      .select("*")
      .eq("salon_id", salonRow.id)
      .eq("is_active", true)
      .order("name"),
    supabase
      .from("barbers")
      .select("*")
      .eq("salon_id", salonRow.id)
      .eq("is_active", true)
      .order("display_name"),
    supabase
      .from("salon_gallery")
      .select("*")
      .eq("salon_id", salonRow.id)
      .order("sort_order"),
    supabase
      .from("reviews")
      .select("*, profiles:customer_id(full_name, avatar_url)")
      .eq("salon_id", salonRow.id)
      .order("created_at", { ascending: false }),
  ]);

  const avgRating = Number(salonRow.avg_rating ?? 0);
  const reviewCount = Number(salonRow.review_count ?? 0);
  const reviewList = (reviews as Array<{
    id: string;
    rating: number;
    comment: string | null;
    created_at: string;
    profiles: { full_name: string; avatar_url: string | null } | null;
  }>) ?? [];

  return (
    <div>
      <TrackSalonView salonId={salonRow.id} />

      {/* Hero Banner */}
      <div className="relative h-64 bg-linear-to-br from-snip-teal via-snip-primary to-slate-900 md:h-80">
        {salonRow.cover_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={salonRow.cover_url}
            alt=""
            className="h-full w-full object-cover opacity-85"
          />
        ) : null}
        <div className="absolute inset-0 bg-linear-to-t from-slate-950/90 via-slate-950/40 to-transparent" />
        
        <div className="snip-container absolute inset-x-0 bottom-0 pb-8">
          <div className="flex flex-wrap items-end justify-between gap-4 text-white">
            <div className="space-y-2">
              <div className="flex flex-wrap items-center gap-2.5">
                <h1 className="text-3xl font-extrabold tracking-tight md:text-4xl text-white">
                  {salonRow.name}
                </h1>
                {salonRow.verification_status === "verified" ? (
                  <Badge variant="success" className="bg-emerald-500/90 text-white">
                    Verified
                  </Badge>
                ) : null}
              </div>

              <div className="flex flex-wrap items-center gap-4 text-sm text-white/90">
                <span className="flex items-center gap-1.5 font-medium">
                  <Star
                    className={`h-4 w-4 ${
                      avgRating > 0 ? "fill-amber-400 text-amber-400" : "text-white/60"
                    }`}
                  />
                  <span>
                    {avgRating > 0 ? avgRating.toFixed(1) : "New"}
                  </span>
                  <span className="text-white/70">
                    ({reviewCount} {reviewCount === 1 ? "review" : "reviews"})
                  </span>
                </span>

                <span className="flex items-center gap-1.5 text-white/80">
                  <MapPin className="h-4 w-4 text-snip-teal" />
                  {[salonRow.address, salonRow.city].filter(Boolean).join(", ") ||
                    "Colombo, Sri Lanka"}
                </span>
              </div>
            </div>

            {/* CTAs */}
            <div className="flex items-center gap-3">
              <FavoriteButton salonId={salonRow.id} size="md" />
              <Link href={`/salons/${salonRow.slug}/book`}>
                <Button
                  type="button"
                  size="lg"
                  className="rounded-full shadow-snip-md px-6 text-sm font-bold"
                >
                  <Sparkles className="h-4 w-4 mr-1.5" />
                  Book Now
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </div>

      <div className="snip-container grid gap-8 py-10 lg:grid-cols-[1fr_320px]">
        <div className="space-y-8">
          {/* About Section */}
          <section className="rounded-2xl border border-snip-border bg-white p-6 shadow-snip-sm">
            <h2 className="text-lg font-bold text-snip-charcoal">About the Salon</h2>
            <p className="mt-3 text-sm leading-relaxed text-snip-muted">
              {salonRow.description ??
                "Welcome to a premier salon experience. Book with top stylists and enjoy hassle-free visits on SNIP."}
            </p>
          </section>

          {/* Salon Photo Gallery */}
          {gallery && gallery.length > 0 && (
            <section className="rounded-2xl border border-snip-border bg-white p-6 shadow-snip-sm space-y-4">
              <div className="flex items-center gap-2">
                <ImageIcon className="h-5 w-5 text-snip-teal" />
                <h2 className="text-lg font-bold text-snip-charcoal">Salon Gallery</h2>
              </div>
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
                {(gallery as SalonGallery[]).map((img) => (
                  <div
                    key={img.id}
                    className="group relative aspect-square overflow-hidden rounded-xl bg-snip-bg border border-snip-border"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={img.image_url}
                      alt={img.caption ?? "Salon photo"}
                      className="h-full w-full object-cover transition duration-300 group-hover:scale-105"
                    />
                    {img.caption && (
                      <div className="absolute inset-x-0 bottom-0 bg-linear-to-t from-black/80 p-2 text-center text-xs text-white opacity-0 transition group-hover:opacity-100">
                        {img.caption}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Services Menu */}
          <section className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-bold text-snip-charcoal">
                  Services Menu
                </h2>
                <p className="text-xs text-snip-muted">
                  Choose a treatment to view available time slots
                </p>
              </div>
              <Link href={`/salons/${salonRow.slug}/book`}>
                <Button type="button" variant="soft" size="sm" className="rounded-full">
                  Book service
                </Button>
              </Link>
            </div>
            {(services as Service[] | null)?.length ? (
              <div className="space-y-3">
                {(services as Service[]).map((service) => (
                  <ServiceCard
                    key={service.id}
                    service={service}
                    bookHref={`/salons/${salonRow.slug}/book?service=${service.id}`}
                  />
                ))}
              </div>
            ) : (
              <EmptyState
                title="No services listed yet"
                description="Check back soon or contact the salon directly."
              />
            )}
          </section>

          {/* Customer Reviews Section */}
          <section className="rounded-2xl border border-snip-border bg-white p-6 shadow-snip-sm space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-4 border-b border-snip-border pb-5">
              <div>
                <div className="flex items-center gap-2">
                  <MessageSquare className="h-5 w-5 text-snip-teal" />
                  <h2 className="text-lg font-bold text-snip-charcoal">
                    Client Reviews & Ratings
                  </h2>
                </div>
                <p className="text-xs text-snip-muted mt-1">
                  Verified appointments from real clients on SNIP
                </p>
              </div>

              <div className="flex items-center gap-3 bg-snip-bg px-4 py-2 rounded-2xl border border-snip-border">
                <Star className="h-6 w-6 fill-amber-400 text-amber-400" />
                <div>
                  <div className="text-lg font-extrabold text-snip-charcoal leading-none">
                    {avgRating > 0 ? avgRating.toFixed(1) : "New"}
                  </div>
                  <div className="text-[11px] text-snip-muted">
                    {reviewCount} {reviewCount === 1 ? "review" : "reviews"}
                  </div>
                </div>
              </div>
            </div>

            {reviewList.length > 0 ? (
              <div className="space-y-4">
                {reviewList.map((rev) => (
                  <div
                    key={rev.id}
                    className="rounded-xl border border-snip-border bg-snip-bg/40 p-4 space-y-2"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <div className="h-8 w-8 rounded-full bg-snip-teal/15 text-snip-teal flex items-center justify-center font-bold text-xs uppercase overflow-hidden">
                          {rev.profiles?.avatar_url ? (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img
                              src={rev.profiles.avatar_url}
                              alt=""
                              className="h-full w-full object-cover"
                            />
                          ) : (
                            (rev.profiles?.full_name ?? "Client").slice(0, 2)
                          )}
                        </div>
                        <div>
                          <div className="text-sm font-bold text-snip-charcoal">
                            {rev.profiles?.full_name ?? "Verified Client"}
                          </div>
                          <div className="text-[11px] text-snip-muted">
                            {format(new Date(rev.created_at), "MMM d, yyyy")}
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-0.5">
                        {[1, 2, 3, 4, 5].map((star) => (
                          <Star
                            key={star}
                            className={`h-3.5 w-3.5 ${
                              star <= rev.rating
                                ? "fill-amber-400 text-amber-400"
                                : "text-slate-200"
                            }`}
                          />
                        ))}
                      </div>
                    </div>

                    {rev.comment ? (
                      <p className="text-xs text-snip-charcoal/80 leading-relaxed pl-10">
                        {rev.comment}
                      </p>
                    ) : null}
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-8 text-center text-sm text-snip-muted">
                No reviews yet. Book an appointment and be the first to share your experience!
              </div>
            )}
          </section>
        </div>

        {/* Sidebar Info */}
        <aside className="space-y-6">
          <div className="rounded-2xl border border-snip-border bg-white p-5 shadow-snip-sm space-y-3">
            <h3 className="font-bold text-snip-charcoal">Salon Details</h3>
            <div className="space-y-2 text-xs text-snip-muted">
              {salonRow.phone ? (
                <p className="flex items-center gap-2 text-snip-charcoal font-medium">
                  <Phone className="h-4 w-4 text-snip-teal shrink-0" />
                  {salonRow.phone}
                </p>
              ) : (
                <p>Phone not listed</p>
              )}
              {salonRow.email ? (
                <p className="truncate">{salonRow.email}</p>
              ) : null}
              {salonRow.address ? (
                <p className="pt-1 border-t border-snip-border">
                  {salonRow.address}, {salonRow.city}
                </p>
              ) : null}
            </div>
          </div>

          <div className="rounded-2xl border border-snip-border bg-white p-5 shadow-snip-sm space-y-3">
            <h3 className="font-bold text-snip-charcoal">Stylist Team</h3>
            <div className="space-y-3">
              {(barbers as Barber[] | null)?.length ? (
                (barbers as Barber[]).map((barber) => (
                  <div key={barber.id} className="flex items-center gap-3 text-sm">
                    <div className="h-9 w-9 rounded-full bg-snip-teal/15 text-snip-teal flex items-center justify-center font-bold text-xs uppercase overflow-hidden shrink-0">
                      {barber.avatar_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={barber.avatar_url}
                          alt=""
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        barber.display_name.slice(0, 2)
                      )}
                    </div>
                    <div>
                      <p className="font-bold text-snip-charcoal">
                        {barber.display_name}
                      </p>
                      <p className="text-xs text-snip-muted">
                        {barber.specializations?.join(", ") || "Stylist"}
                      </p>
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-xs text-snip-muted">Team details coming soon.</p>
              )}
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
