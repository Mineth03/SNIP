import Link from "next/link";
import Image from "next/image";
import {
  CalendarCheck2,
  CheckCircle2,
  CreditCard,
  Heart,
  MapPinned,
  QrCode,
  Scissors,
  ShieldCheck,
  Sparkles,
  TrendingUp,
  Users,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { SnipLogo } from "@/components/snip/snip-logo";

const features = [
  {
    icon: ShieldCheck,
    title: "Trusted Salons",
    subtitle: "Quality you count on",
  },
  {
    icon: CalendarCheck2,
    title: "Easy Booking",
    subtitle: "Just in a few taps",
  },
  {
    icon: CreditCard,
    title: "Secure Payments",
    subtitle: "Safe & hassle-free",
  },
  {
    icon: TrendingUp,
    title: "Grow Your Business",
    subtitle: "Built for salon success",
  },
];

const steps = [
  {
    icon: MapPinned,
    title: "Discover Salons",
    body: "Browse top-rated verified salons near you with real reviews, services, and live pricing.",
  },
  {
    icon: CalendarCheck2,
    title: "Book in Minutes",
    body: "Choose your preferred stylist, select services, and pick an instant time slot that fits your schedule.",
  },
  {
    icon: QrCode,
    title: "Smart QR Check-In",
    body: "Arrive stress-free. Present your digital QR ticket at the front desk for instant contactless check-in.",
  },
];

export default function LandingPage() {
  return (
    <div className="flex flex-col">
      {/* Hero Section */}
      <section className="snip-gradient-hero relative overflow-hidden border-b border-snip-border">
        <div className="snip-container grid items-center gap-12 py-16 lg:grid-cols-12 lg:py-24">
          {/* Left Column */}
          <div className="space-y-8 lg:col-span-7">
            <div className="inline-flex items-center gap-2 rounded-full border border-snip-teal/30 bg-snip-primary/10 px-4 py-1.5 text-xs font-semibold text-snip-teal">
              <Sparkles className="h-3.5 w-3.5" />
              <span>Smart Salon Booking & Management</span>
            </div>

            <div className="space-y-4">
              <h1 className="text-4xl font-extrabold tracking-tight text-snip-charcoal sm:text-5xl lg:text-6xl">
                Your Next{" "}
                <span className="text-snip-teal underline decoration-snip-teal/40 decoration-wavy decoration-2">
                  Great Look
                </span>{" "}
                is a Few Clicks Away
              </h1>
              <p className="max-w-xl text-lg text-snip-muted">
                Book appointments, manage your salon and grow your business —
                all in one place.
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-4">
              <Link href="/explore">
                <Button size="lg" className="px-8 shadow-md">
                  Book a Salon
                </Button>
              </Link>
              <Link href="/register?role=salon_owner">
                <Button size="lg" variant="outline" className="px-8">
                  For Salon Owners
                </Button>
              </Link>
            </div>

            {/* 4 Trust Features Row */}
            <div className="grid grid-cols-2 gap-4 pt-6 sm:grid-cols-4 sm:gap-6 border-t border-snip-border/80">
              {features.map((item) => (
                <div key={item.title} className="space-y-1">
                  <div className="flex h-9 w-9 items-center justify-center rounded-full bg-snip-primary/10 text-snip-teal">
                    <item.icon className="h-4 w-4" />
                  </div>
                  <div className="text-sm font-bold text-snip-charcoal">
                    {item.title}
                  </div>
                  <div className="text-xs text-snip-muted">{item.subtitle}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Right Column: Hero Visual Card */}
          <div className="relative lg:col-span-5">
            {/* Ambient Teal Glow */}
            <div className="absolute -inset-4 rounded-3xl bg-gradient-to-tr from-snip-teal/20 via-snip-primary/10 to-transparent blur-2xl" />

            {/* Main Visual Frame */}
            <div className="relative overflow-hidden rounded-3xl border border-snip-border bg-white p-3 shadow-snip">
              <div className="relative h-96 w-full overflow-hidden rounded-2xl bg-gradient-to-br from-teal-50 to-slate-100 sm:h-[460px]">
                {/* Visual Image */}
                <img
                  src="https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1000&q=80"
                  alt="Happy woman with fresh salon look"
                  className="h-full w-full object-cover object-center"
                />

                {/* Floating Handwritten Style Badge: Top Left */}
                <div className="absolute left-4 top-4 rounded-full border border-white/80 bg-white/90 px-4 py-2 shadow-lg backdrop-blur-md">
                  <span className="font-serif italic text-snip-charcoal text-sm font-semibold flex items-center gap-1.5">
                    Good Hair, Brighter Days <Heart className="h-3.5 w-3.5 text-pink-500 fill-pink-500 inline" />
                  </span>
                </div>

                {/* Floating Badge: Bottom Right */}
                <div className="absolute bottom-4 right-4 rounded-full border border-white/80 bg-white/95 px-4 py-2 shadow-lg backdrop-blur-md">
                  <span className="font-serif italic text-snip-teal text-sm font-bold flex items-center gap-1.5">
                    Look Good, Feel Great ♡
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How it Works */}
      <section className="bg-white py-20 border-b border-snip-border">
        <div className="snip-container">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-extrabold tracking-tight text-snip-charcoal sm:text-4xl">
              Beauty Business, Beautifully Simple
            </h2>
            <p className="mt-3 text-base text-snip-muted sm:text-lg">
              Designed with precision for clients who love looking their best
              and salon teams that strive for excellence.
            </p>
          </div>

          <div className="mt-14 grid gap-8 md:grid-cols-3">
            {steps.map((step, idx) => (
              <div
                key={step.title}
                className="group relative rounded-2xl border border-snip-border bg-snip-bg p-8 transition-all hover:border-snip-teal/50 hover:shadow-snip-sm"
              >
                <div className="flex items-center justify-between">
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-snip-primary text-white shadow-snip-sm group-hover:scale-105 transition-transform">
                    <step.icon className="h-6 w-6" />
                  </div>
                  <span className="text-xs font-bold text-snip-muted uppercase tracking-wider">
                    Step 0{idx + 1}
                  </span>
                </div>
                <h3 className="mt-6 text-xl font-bold text-snip-charcoal">
                  {step.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-snip-muted">
                  {step.body}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Design System & Brand Identity Showcase (matching inspiration) */}
      <section className="bg-snip-bg py-16 border-b border-snip-border">
        <div className="snip-container">
          <div className="mb-8">
            <span className="text-xs font-bold tracking-widest text-snip-teal uppercase">
              Brand Identity
            </span>
            <h2 className="text-2xl font-bold text-snip-charcoal">
              SNIP Design System & Guidelines
            </h2>
          </div>

          <div className="grid gap-6 md:grid-cols-12">
            {/* Colors Card */}
            <div className="rounded-2xl border border-snip-border bg-white p-6 md:col-span-4 shadow-snip-sm">
              <h3 className="text-sm font-semibold uppercase tracking-wider text-snip-muted mb-4">
                Brand Colors
              </h3>
              <div className="grid grid-cols-4 gap-2">
                <div className="text-center">
                  <div className="h-12 w-full rounded-lg bg-[#14B8A6] shadow-inner mb-2" />
                  <span className="text-[11px] font-bold block text-snip-charcoal">
                    #14B8A6
                  </span>
                  <span className="text-[10px] text-snip-muted">Primary</span>
                </div>
                <div className="text-center">
                  <div className="h-12 w-full rounded-lg bg-[#1F2937] shadow-inner mb-2" />
                  <span className="text-[11px] font-bold block text-snip-charcoal">
                    #1F2937
                  </span>
                  <span className="text-[10px] text-snip-muted">Secondary</span>
                </div>
                <div className="text-center">
                  <div className="h-12 w-full rounded-lg bg-[#F3F4F6] border border-snip-border mb-2" />
                  <span className="text-[11px] font-bold block text-snip-charcoal">
                    #F3F4F6
                  </span>
                  <span className="text-[10px] text-snip-muted">Light</span>
                </div>
                <div className="text-center">
                  <div className="h-12 w-full rounded-lg bg-[#F8FAFC] border border-snip-border mb-2" />
                  <span className="text-[11px] font-bold block text-snip-charcoal">
                    #F8FAFC
                  </span>
                  <span className="text-[10px] text-snip-muted">Neutral</span>
                </div>
              </div>
            </div>

            {/* Typography Card */}
            <div className="rounded-2xl border border-snip-border bg-white p-6 md:col-span-4 shadow-snip-sm">
              <h3 className="text-sm font-semibold uppercase tracking-wider text-snip-muted mb-2">
                Typography
              </h3>
              <div className="flex items-baseline gap-4">
                <span className="text-4xl font-extrabold text-snip-charcoal">
                  Aa
                </span>
                <div>
                  <h4 className="text-lg font-bold text-snip-charcoal">Inter</h4>
                  <p className="text-xs text-snip-muted">
                    Clean • Modern • Friendly
                  </p>
                </div>
              </div>
              <div className="mt-4 space-y-1 text-xs border-t border-snip-border pt-3">
                <div className="font-bold text-snip-charcoal">Heading 1 & Heading 2</div>
                <div className="text-snip-muted">Body Text & Captions</div>
              </div>
            </div>

            {/* UI Elements Showcase */}
            <div className="rounded-2xl border border-snip-border bg-white p-6 md:col-span-4 shadow-snip-sm">
              <h3 className="text-sm font-semibold uppercase tracking-wider text-snip-muted mb-3">
                UI Elements
              </h3>
              <div className="flex flex-wrap items-center gap-2">
                <Button size="sm">Primary Button</Button>
                <Button size="sm" variant="secondary">
                  Secondary
                </Button>
                <Link
                  href="/explore"
                  className="text-xs font-semibold text-snip-teal underline decoration-2 underline-offset-4"
                >
                  Text Link →
                </Link>
              </div>
            </div>
          </div>

          {/* Dark Tagline Banner */}
          <div className="mt-6 rounded-2xl bg-snip-charcoal p-6 text-white shadow-snip sm:p-8 flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-4">
              <SnipLogo size={40} showTagline light />
              <div>
                <p className="text-xs uppercase tracking-widest text-snip-teal font-bold">
                  Empowering Salons • Beautifying Lives
                </p>
                <h3 className="text-xl font-bold">Same Passion, A Smarter Way ♡</h3>
              </div>
            </div>
            <div className="flex gap-3">
              <Link href="/explore">
                <Button className="bg-snip-primary text-white hover:bg-snip-primary-hover">
                  Find a Salon
                </Button>
              </Link>
              <Link href="/register">
                <Button variant="outline" className="border-white/20 text-white bg-transparent hover:bg-white/10">
                  Join SNIP Today
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
