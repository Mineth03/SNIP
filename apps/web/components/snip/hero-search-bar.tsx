"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, LocateFixed, MapPin, Search } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { getCurrentUserCoordinates } from "@/lib/location";

export function HeroSearchBar() {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [city, setCity] = useState("");
  const [locating, setLocating] = useState(false);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const params = new URLSearchParams();
    if (query.trim()) params.set("q", query.trim());
    if (city.trim()) params.set("city", city.trim());
    router.push(`/explore?${params.toString()}`);
  }

  async function handleNearMe() {
    setLocating(true);
    try {
      const coords = await getCurrentUserCoordinates();
      toast.success("Location found! Showing salons near you.");
      const params = new URLSearchParams();
      if (query.trim()) params.set("q", query.trim());
      params.set("lat", coords.latitude.toFixed(5));
      params.set("lng", coords.longitude.toFixed(5));
      router.push(`/explore?${params.toString()}`);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to get current location.");
    } finally {
      setLocating(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-2xl border border-snip-border bg-white p-2.5 shadow-snip sm:p-3 space-y-2 sm:space-y-0"
    >
      <div className="grid gap-2 sm:grid-cols-[1.4fr_1fr_auto_auto]">
        <div className="relative flex items-center">
          <Search className="pointer-events-none absolute left-3.5 h-4 w-4 text-snip-muted" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search haircut, fade, color, salon..."
            className="h-11 w-full rounded-xl bg-snip-bg pl-10 pr-3 text-xs font-medium text-snip-charcoal placeholder:text-snip-muted/80 focus:bg-white focus:outline-none focus:ring-2 focus:ring-snip-teal"
          />
        </div>

        <div className="relative flex items-center">
          <MapPin className="pointer-events-none absolute left-3.5 h-4 w-4 text-snip-muted" />
          <input
            type="text"
            value={city}
            onChange={(e) => setCity(e.target.value)}
            placeholder="City (e.g. Colombo)"
            className="h-11 w-full rounded-xl bg-snip-bg pl-10 pr-3 text-xs font-medium text-snip-charcoal placeholder:text-snip-muted/80 focus:bg-white focus:outline-none focus:ring-2 focus:ring-snip-teal"
          />
        </div>

        <Button
          type="button"
          variant="outline"
          onClick={handleNearMe}
          disabled={locating}
          title="Use current GPS location"
          className="h-11 rounded-xl px-3.5 text-xs font-bold text-snip-teal border-snip-teal/30 hover:bg-snip-teal/10 gap-1.5"
        >
          <LocateFixed className={`h-4 w-4 ${locating ? "animate-spin" : ""}`} />
          <span className="hidden md:inline">
            {locating ? "Locating..." : "Near Me"}
          </span>
        </Button>

        <Button
          type="submit"
          size="lg"
          className="h-11 rounded-xl px-6 text-xs font-bold gap-1.5 shadow-snip-sm"
        >
          <span>Find Salons</span>
          <ArrowRight className="h-3.5 w-3.5" />
        </Button>
      </div>
    </form>
  );
}
