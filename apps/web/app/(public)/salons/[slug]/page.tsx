import Link from "next/link";
import { notFound } from "next/navigation";
import { MapPin, Phone } from "lucide-react";
import { ServiceCard } from "@/components/snip/service-card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { createClient } from "@/lib/supabase/server";
import type { Barber, Salon, Service } from "@/types/database";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  return { title: slug.replace(/-/g, " ") };
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

  const [{ data: services }, { data: barbers }] = await Promise.all([
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
  ]);

  return (
    <div>
      <div className="relative h-56 bg-gradient-to-br from-snip-teal via-snip-primary to-snip-charcoal md:h-72">
        {salonRow.cover_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={salonRow.cover_url}
            alt=""
            className="h-full w-full object-cover opacity-80"
          />
        ) : null}
        <div className="absolute inset-0 bg-gradient-to-t from-snip-charcoal/70 to-transparent" />
        <div className="snip-container absolute inset-x-0 bottom-0 pb-8">
          <div className="flex flex-wrap items-end justify-between gap-4 text-white">
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-3xl font-bold tracking-tight md:text-4xl">
                  {salonRow.name}
                </h1>
                {salonRow.verification_status === "verified" ? (
                  <Badge variant="success">Verified</Badge>
                ) : null}
              </div>
              <p className="mt-2 flex items-center gap-1.5 text-sm text-white/80">
                <MapPin className="h-4 w-4" />
                {[salonRow.address, salonRow.city].filter(Boolean).join(", ") ||
                  "Location coming soon"}
              </p>
            </div>
            <Link href={`/salons/${salonRow.slug}/book`}>
              <Button type="button" size="lg">
                Book now
              </Button>
            </Link>
          </div>
        </div>
      </div>

      <div className="snip-container grid gap-8 py-10 lg:grid-cols-[1fr_320px]">
        <div className="space-y-8">
          <section className="rounded-lg border border-snip-border bg-white p-6 shadow-snip-sm">
            <h2 className="text-lg font-semibold text-snip-charcoal">About</h2>
            <p className="mt-3 text-sm leading-relaxed text-snip-muted">
              {salonRow.description ??
                "This salon is ready for bookings on SNIP."}
            </p>
          </section>

          <section className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-snip-charcoal">
                Services
              </h2>
              <Link href={`/salons/${salonRow.slug}/book`}>
                <Button type="button" variant="soft" size="sm">
                  Start booking
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
        </div>

        <aside className="space-y-4">
          <div className="rounded-lg border border-snip-border bg-white p-5 shadow-snip-sm">
            <h3 className="font-semibold text-snip-charcoal">Contact</h3>
            <div className="mt-3 space-y-2 text-sm text-snip-muted">
              {salonRow.phone ? (
                <p className="flex items-center gap-2">
                  <Phone className="h-4 w-4" />
                  {salonRow.phone}
                </p>
              ) : (
                <p>Phone not listed</p>
              )}
              {salonRow.email ? <p>{salonRow.email}</p> : null}
            </div>
          </div>
          <div className="rounded-lg border border-snip-border bg-white p-5 shadow-snip-sm">
            <h3 className="font-semibold text-snip-charcoal">Team</h3>
            <div className="mt-3 space-y-3">
              {(barbers as Barber[] | null)?.length ? (
                (barbers as Barber[]).map((barber) => (
                  <div key={barber.id} className="text-sm">
                    <p className="font-medium text-snip-charcoal">
                      {barber.display_name}
                    </p>
                    <p className="text-snip-muted">
                      {barber.specializations?.join(", ") || "Stylist"}
                    </p>
                  </div>
                ))
              ) : (
                <p className="text-sm text-snip-muted">Team details coming soon.</p>
              )}
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
