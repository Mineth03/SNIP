"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { LocateFixed, MapPin, Search, Sparkles, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { getCurrentUserCoordinates, SRI_LANKA_CITY_COORDINATES } from "@/lib/location";
import type { ServiceCategory } from "@/types/database";

const categories: { id: ServiceCategory | "all"; label: string }[] = [
  { id: "all", label: "All Treatments" },
  { id: "hair", label: "Haircuts & Styling" },
  { id: "beard", label: "Beard & Grooming" },
  { id: "color", label: "Coloring" },
  { id: "facial", label: "Facial" },
  { id: "massage", label: "Head Spa" },
  { id: "nails", label: "Nails" },
];

export function ExploreSearchFilters() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const currentQ = searchParams.get("q") ?? "";
  const currentCity = searchParams.get("city") ?? "";
  const currentCat = searchParams.get("category") ?? "all";
  const currentLat = searchParams.get("lat");
  const currentLng = searchParams.get("lng");
  const isNearMe = Boolean(currentLat && currentLng);

  const [query, setQuery] = useState(currentQ);
  const [city, setCity] = useState(currentCity);
  const [locating, setLocating] = useState(false);

  function applyFilters(updates: Record<string, string | null>) {
    const next = new URLSearchParams(searchParams.toString());
    for (const [key, val] of Object.entries(updates)) {
      if (val === null || val === "" || val === "all") {
        next.delete(key);
      } else {
        next.set(key, val);
      }
    }
    router.push(`/explore?${next.toString()}`);
  }

  async function handleNearMe() {
    setLocating(true);
    try {
      const coords = await getCurrentUserCoordinates();
      toast.success("Location detected! Showing nearby salons.");
      applyFilters({
        lat: coords.latitude.toFixed(5),
        lng: coords.longitude.toFixed(5),
        city: null, // Clear explicit text city filter when GPS is active
      });
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Could not determine location.");
    } finally {
      setLocating(false);
    }
  }

  function handleCityPreset(cityName: string) {
    const coords = SRI_LANKA_CITY_COORDINATES[cityName.toLowerCase()];
    if (coords) {
      setCity(cityName);
      applyFilters({
        city: cityName,
        lat: coords.latitude.toFixed(5),
        lng: coords.longitude.toFixed(5),
      });
    } else {
      setCity(cityName);
      applyFilters({
        city: cityName,
        lat: null,
        lng: null,
      });
    }
  }

  function handleClearLocation() {
    setCity("");
    applyFilters({
      lat: null,
      lng: null,
      city: null,
    });
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    applyFilters({
      q: query.trim() || null,
      city: city.trim() || null,
    });
  }

  return (
    <div className="space-y-4">
      {/* Search Input Bar */}
      <form
        onSubmit={handleSubmit}
        className="grid gap-2.5 rounded-2xl border border-snip-border bg-white p-3 shadow-snip-sm md:grid-cols-[1.5fr_1fr_auto]"
      >
        <div className="relative flex items-center">
          <Search className="pointer-events-none absolute left-3.5 h-4 w-4 text-snip-muted" />
          <Input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by salon name, style or service..."
            className="h-11 pl-10 text-xs bg-snip-bg focus:bg-white"
          />
        </div>

        <div className="relative flex items-center">
          <MapPin className="pointer-events-none absolute left-3.5 h-4 w-4 text-snip-muted" />
          <Input
            value={city}
            onChange={(e) => setCity(e.target.value)}
            placeholder="City or area (e.g. Colombo 05)"
            className="h-11 pl-10 text-xs bg-snip-bg focus:bg-white"
          />
          {city && (
            <button
              type="button"
              onClick={handleClearLocation}
              className="absolute right-3 text-snip-muted hover:text-snip-charcoal"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          )}
        </div>

        <div className="flex items-center gap-2">
          <Button
            type="submit"
            className="h-11 rounded-xl px-6 text-xs font-bold"
          >
            Search
          </Button>

          <Button
            type="button"
            variant={isNearMe ? "primary" : "outline"}
            onClick={handleNearMe}
            disabled={locating}
            className={`h-11 rounded-xl px-4 text-xs font-bold gap-1.5 transition-all ${
              isNearMe
                ? "bg-snip-teal text-white shadow-snip-sm"
                : "text-snip-teal border-snip-teal/30 hover:bg-snip-teal/10"
            }`}
          >
            <LocateFixed
              className={`h-4 w-4 ${locating ? "animate-spin" : ""}`}
            />
            <span className="hidden sm:inline">
              {locating ? "Locating..." : isNearMe ? "Near Me ✓" : "Near Me"}
            </span>
          </Button>
        </div>
      </form>

      {/* Active Location Banner if GPS is on */}
      {isNearMe && (
        <div className="flex items-center justify-between rounded-xl bg-snip-primary/10 border border-snip-teal/30 px-4 py-2.5 text-xs text-snip-teal font-medium">
          <span className="flex items-center gap-2">
            <LocateFixed className="h-4 w-4 shrink-0 animate-pulse" />
            <span>
              Showing salons ordered by distance from your current location
            </span>
          </span>
          <button
            type="button"
            onClick={handleClearLocation}
            className="text-snip-charcoal hover:underline font-semibold text-[11px]"
          >
            Reset Location
          </button>
        </div>
      )}

      {/* City Chips & Category Pills */}
      <div className="flex flex-wrap items-center gap-2 pt-1">
        <span className="text-[11px] font-bold text-snip-muted uppercase tracking-wider mr-1">
          City:
        </span>
        {["Colombo", "Kandy", "Galle", "Negombo"].map((cName) => {
          const active = city.toLowerCase() === cName.toLowerCase();
          return (
            <button
              key={cName}
              type="button"
              onClick={() => handleCityPreset(cName)}
              className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                active
                  ? "bg-snip-charcoal text-white shadow-xs"
                  : "bg-white border border-snip-border text-snip-muted hover:border-snip-charcoal hover:text-snip-charcoal"
              }`}
            >
              {cName}
            </button>
          );
        })}
      </div>

      {/* Category Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
        {categories.map((cat) => {
          const active = currentCat === cat.id;
          return (
            <button
              key={cat.id}
              type="button"
              onClick={() => applyFilters({ category: cat.id })}
              className={`shrink-0 rounded-full px-4 py-1.5 text-xs font-semibold transition ${
                active
                  ? "bg-snip-teal text-white shadow-snip-sm"
                  : "bg-white border border-snip-border text-snip-charcoal hover:bg-snip-bg"
              }`}
            >
              {cat.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
