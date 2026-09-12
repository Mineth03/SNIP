import Link from "next/link";
import {
  CalendarCheck2,
  CheckCircle2,
  Clock,
  Heart,
  MapPin,
  QrCode,
  Scissors,
  Search,
  ShieldCheck,
  Sparkles,
  Star,
  TrendingUp,
  UserCheck,
  Users,
  ChevronRight,
  ArrowRight,
  Smartphone,
  Award,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { SnipLogo } from "@/components/snip/snip-logo";
import { SalonCard } from "@/components/snip/salon-card";
import { HeroSearchBar } from "@/components/snip/hero-search-bar";
import { createClient } from "@/lib/supabase/server";
import type { Salon, ServiceCategory } from "@/types/database";

// Popular treatment categories
const categories: {
  id: ServiceCategory;
  name: string;
  desc: string;
  icon: typeof Scissors;
  badge?: string;
}[] = [
  {
    id: "hair",
    name: "Haircut & Styling",
    desc: "Modern fades, cuts & blowouts",
    icon: Scissors,
    badge: "Popular",
  },
  {
    id: "beard",
    name: "Beard & Grooming",
    desc: "Precision trims, shaping & hot towel",
    icon: Sparkles,
  },
  {
    id: "color",
    name: "Hair Coloring",
    desc: "Highlights, balayage & tints",
    icon: Award,
  },
  {
    id: "facial",
    name: "Facials & Cleanse",
    desc: "Rejuvenating skin therapy",
    icon: CheckCircle2,
  },
  {
    id: "massage",
    name: "Head & Scalp Spa",
    desc: "Relaxing deep-tissue treatments",
    icon: Clock,
  },
  {
    id: "nails",
    name: "Nails & Care",
    desc: "Manicures, pedicures & detail",
    icon: Heart,
  },
];

// 3 Simple steps
const steps = [
  {
    number: "01",
    title: "Discover Top Salons",
    subtitle: "Explore verified salons with real customer ratings, transparent service menus, and upfront prices.",
    icon: Search,
    highlight: "100% Verified Quality",
  },
  {
    number: "02",
    title: "Choose Stylist & Slot",
    subtitle: "Select your favorite barber or stylist and pick a guaranteed real-time slot that fits your schedule.",
    icon: CalendarCheck2,
    highlight: "Zero Double-Booking",
  },
  {
    number: "03",
    title: "Instant QR Check-In",
    subtitle: "Arrive at the salon, show your digital QR ticket, and walk straight in without waiting at the desk.",
    icon: QrCode,
    highlight: "Contactless & Fast",
  },
];

// Real-world client & owner reviews
const testimonials = [
  {
    name: "James Perera",
    role: "Regular Client",
    avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80",
    rating: 5,
    salon: "The Modern Cut, Colombo 05",
    quote:
      "The QR ticket is pure magic. I walked in, Kamal scanned my phone in 2 seconds, and my haircut started immediately. No awkward waiting around!",
  },
  {
    name: "Alex Fernando",
    role: "Salon Owner",
    avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80",
    rating: 5,
    salon: "The Modern Cut",
    quote:
      "SNIP turned our chaotic phone bookings into an organized, automated machine. No-shows dropped drastically, and our clients love the sleek experience.",
  },
  {
    name: "Dilini Senanayake",
    role: "Beauty Enthusiast",
    avatar: "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=150&q=80",
    rating: 5,
    salon: "Glow & Co. Salon",
    quote:
      "Finding verified salons with honest prices used to take hours on Instagram. With SNIP, I booked my hair coloring in under a minute with zero stress.",
  },
];

// FAQs
const faqs = [
  {
    question: "Do I have to pay online when making a booking?",
    answer:
      "No! You can book with zero upfront payment and pay directly at the salon desk after your appointment is complete. Both cash and card are accepted at verified salons.",
  },
  {
    question: "How does the digital QR Ticket check-in work?",
    answer:
      "Once you confirm your booking, you receive a personal QR Ticket with a unique ticket code. When you arrive at the salon, simply show your screen to the reception or barber — a quick scan marks you as checked in and notifies your stylist immediately.",
  },
  {
    question: "Can I choose a specific barber or stylist?",
    answer:
      "Yes! When booking, you can browse available stylists, view their specializations and bios, or choose 'Any Available Stylist' for maximum time slot flexibility.",
  },
  {
    question: "How can I register my salon on SNIP?",
    answer:
      "Salon owners can register in less than 2 minutes by clicking 'For Salon Owners'. You can set up your service menu, add your barbers, configure opening hours, and start receiving verified bookings right away.",
  },
];

export default async function LandingPage() {
  const supabase = await createClient();

  // Load featured salons
  const { data: rawSalons } = await supabase
    .from("salons")
    .select("id, name, slug, address, city, description, cover_url, logo_url, verification_status, avg_rating, review_count")
    .eq("is_active", true)
    .order("avg_rating", { ascending: false })
    .limit(3);

  const salons = (rawSalons as Salon[]) ?? [];

  return (
    <div className="flex flex-col overflow-hidden">
      {/* 1. HERO SECTION */}
      <section className="snip-gradient-hero relative overflow-hidden border-b border-snip-border pt-12 pb-16 lg:pt-20 lg:pb-24">
        {/* Soft background ambient glows */}
        <div className="pointer-events-none absolute -top-40 left-1/2 h-125 w-200 -translate-x-1/2 rounded-full bg-linear-to-tr from-snip-teal/15 via-snip-primary/10 to-transparent blur-3xl" />

        <div className="snip-container relative z-10 grid items-center gap-12 lg:grid-cols-12 lg:gap-8">
          {/* Left Column: Headline & Search */}
          <div className="space-y-8 lg:col-span-7">
            {/* Pill Tagline */}
            <div className="inline-flex items-center gap-2 rounded-full border border-snip-teal/30 bg-snip-primary/10 px-4 py-1.5 text-xs font-bold text-snip-teal shadow-snip-sm">
              <Sparkles className="h-3.5 w-3.5" />
              <span>Smart Salon Booking & Contactless QR Check-In</span>
            </div>

            {/* Main Headline */}
            <div className="space-y-4">
              <h1 className="text-4xl font-extrabold tracking-tight text-snip-charcoal sm:text-5xl lg:text-6xl leading-[1.1]">
                Your Next{" "}
                <span className="relative inline-block text-snip-teal">
                  Great Look
                  <svg
                    className="absolute -bottom-2 left-0 w-full text-snip-teal/30"
                    viewBox="0 0 250 12"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      d="M3 9C60 3 190 3 247 9"
                      stroke="currentColor"
                      strokeWidth="5"
                      strokeLinecap="round"
                    />
                  </svg>
                </span>{" "}
                is Just a Tap Away.
              </h1>
              <p className="max-w-xl text-base text-snip-muted sm:text-lg leading-relaxed">
                Book appointments at top-rated verified salons, choose your favorite
                stylist, and walk straight in with effortless digital QR check-in.
              </p>
            </div>

            {/* Interactive Hero Search Form */}
            <HeroSearchBar />

            {/* Quick Trust Badges */}
            <div className="flex flex-wrap items-center gap-6 pt-2 text-xs font-semibold text-snip-muted">
              <span className="flex items-center gap-1.5">
                <ShieldCheck className="h-4 w-4 text-emerald-500" />
                Verified Salons
              </span>
              <span className="flex items-center gap-1.5">
                <Clock className="h-4 w-4 text-snip-teal" />
                Instant Confirmation
              </span>
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-snip-teal" />
                Pay Directly at Salon
              </span>
            </div>
          </div>

          {/* Right Column: Interactive App Preview Showcase */}
          <div className="relative lg:col-span-5">
            {/* Ambient Teal Card Shadow */}
            <div className="absolute -inset-4 rounded-3xl bg-linear-to-tr from-snip-teal/30 via-snip-primary/15 to-transparent blur-2xl" />

            {/* Main Visual Card */}
            <div className="relative overflow-hidden rounded-3xl border border-snip-border bg-white p-3 shadow-snip">
              <div className="relative h-96 w-full overflow-hidden rounded-2xl bg-linear-to-br from-teal-50 to-slate-100 sm:h-115">
                {/* Clean Salon Visual */}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src="https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1000&q=80"
                  alt="Modern salon customer getting a stylish haircut"
                  className="h-full w-full object-cover object-center"
                />

                {/* Floating Badge 1: Verified Top Salon (Top-Left) */}
                <div className="absolute left-3 top-3 rounded-2xl border border-white/80 bg-white/95 p-3 shadow-lg backdrop-blur-md">
                  <div className="flex items-center gap-2">
                    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-snip-teal/15 text-snip-teal font-bold text-xs">
                      ★
                    </div>
                    <div>
                      <div className="flex items-center gap-1 text-xs font-bold text-snip-charcoal">
                        <span>The Modern Cut</span>
                        <CheckCircle2 className="h-3 w-3 text-snip-teal" />
                      </div>
                      <div className="flex items-center gap-1 text-[11px] text-snip-muted">
                        <span className="font-bold text-amber-500">4.9</span>
                        <span>(320+ reviews)</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Floating Badge 2: Digital QR Ticket (Bottom-Right) */}
                <div className="absolute bottom-3 right-3 rounded-2xl border border-white/80 bg-white/95 p-3.5 shadow-xl backdrop-blur-md">
                  <div className="flex items-center gap-3">
                    <div className="rounded-xl border border-snip-border bg-white p-1.5 shadow-inner">
                      <QrCode className="h-8 w-8 text-snip-charcoal" />
                    </div>
                    <div>
                      <div className="text-[10px] font-bold uppercase tracking-wider text-snip-teal">
                        Fast Check-in
                      </div>
                      <div className="text-xs font-extrabold text-snip-charcoal">
                        Ticket: SNIP784629
                      </div>
                      <div className="mt-0.5 inline-flex items-center gap-1 rounded-full bg-emerald-100/80 px-2 py-0.5 text-[10px] font-bold text-emerald-700">
                        <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                        Confirmed
                      </div>
                    </div>
                  </div>
                </div>

                {/* Floating Pill: Bottom-Left */}
                <div className="absolute bottom-3 left-3 rounded-full border border-white/80 bg-white/90 px-3 py-1.5 shadow-md backdrop-blur-md">
                  <span className="text-xs font-bold text-snip-charcoal flex items-center gap-1.5">
                    Look Good, Feel Great <Heart className="h-3 w-3 fill-rose-500 text-rose-500 inline" />
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 2. STATS & PROOF BANNER */}
      <section className="border-b border-snip-border bg-white py-8">
        <div className="snip-container">
          <div className="grid grid-cols-2 gap-6 md:grid-cols-4">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-snip-primary/10 text-snip-teal">
                <ShieldCheck className="h-6 w-6" />
              </div>
              <div>
                <div className="text-xl font-extrabold text-snip-charcoal">100%</div>
                <div className="text-xs text-snip-muted">Verified Salons</div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-snip-primary/10 text-snip-teal">
                <Star className="h-6 w-6" />
              </div>
              <div>
                <div className="text-xl font-extrabold text-snip-charcoal">4.9 / 5.0</div>
                <div className="text-xs text-snip-muted">Client Satisfaction</div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-snip-primary/10 text-snip-teal">
                <QrCode className="h-6 w-6" />
              </div>
              <div>
                <div className="text-xl font-extrabold text-snip-charcoal">0 mins</div>
                <div className="text-xs text-snip-muted">Wait with QR Pass</div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-snip-primary/10 text-snip-teal">
                <Award className="h-6 w-6" />
              </div>
              <div>
                <div className="text-xl font-extrabold text-snip-charcoal">Pay at Salon</div>
                <div className="text-xs text-snip-muted">Zero Upfront Fees</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 3. POPULAR SERVICES CATEGORIES */}
      <section className="bg-snip-bg py-16 border-b border-snip-border">
        <div className="snip-container space-y-10">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div>
              <span className="text-xs font-bold uppercase tracking-widest text-snip-teal">
                Treatments & Services
              </span>
              <h2 className="text-2xl font-bold tracking-tight text-snip-charcoal sm:text-3xl mt-1">
                Explore Popular Categories
              </h2>
              <p className="text-sm text-snip-muted mt-1">
                Choose the service you need and discover master barbers and stylists near you.
              </p>
            </div>
            <Link
              href="/explore"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-snip-teal hover:underline"
            >
              Browse all treatments <ArrowRight className="h-3.5 w-3.5" />
            </Link>
          </div>

          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            {categories.map((cat) => {
              const IconComp = cat.icon;
              return (
                <Link
                  key={cat.id}
                  href={`/explore?category=${cat.id}`}
                  className="group relative flex flex-col justify-between rounded-2xl border border-snip-border bg-white p-5 transition hover:-translate-y-1 hover:border-snip-teal/50 hover:shadow-snip"
                >
                  <div>
                    <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-snip-bg text-snip-charcoal group-hover:bg-snip-teal group-hover:text-white transition-colors">
                      <IconComp className="h-5 w-5" />
                    </div>
                    {cat.badge && (
                      <span className="absolute top-3 right-3 rounded-full bg-snip-primary/10 px-2 py-0.5 text-[10px] font-bold text-snip-teal">
                        {cat.badge}
                      </span>
                    )}
                    <h3 className="mt-4 text-sm font-bold text-snip-charcoal group-hover:text-snip-teal transition-colors">
                      {cat.name}
                    </h3>
                    <p className="mt-1 text-[11px] text-snip-muted leading-tight">
                      {cat.desc}
                    </p>
                  </div>
                  <span className="mt-4 text-[11px] font-bold text-snip-teal opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-0.5">
                    Explore <ChevronRight className="h-3 w-3" />
                  </span>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      {/* 4. FEATURED / TOP-RATED SALONS */}
      {salons.length > 0 && (
        <section className="bg-white py-16 border-b border-snip-border">
          <div className="snip-container space-y-8">
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
              <div>
                <span className="text-xs font-bold uppercase tracking-widest text-snip-teal">
                  Hand-Picked Excellence
                </span>
                <h2 className="text-2xl font-bold tracking-tight text-snip-charcoal sm:text-3xl mt-1">
                  Top-Rated Salons on SNIP
                </h2>
                <p className="text-sm text-snip-muted mt-1">
                  Verified quality, transparent prices, and instant time slot bookings.
                </p>
              </div>
              <Link href="/explore">
                <Button variant="soft" size="sm" className="rounded-full gap-1">
                  View All Salons <ChevronRight className="h-4 w-4" />
                </Button>
              </Link>
            </div>

            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {salons.map((salon) => (
                <SalonCard key={salon.id} salon={salon} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* 5. HOW IT WORKS */}
      <section id="how-it-works" className="bg-snip-bg py-20 border-b border-snip-border">
        <div className="snip-container space-y-14">
          <div className="mx-auto max-w-2xl text-center space-y-3">
            <span className="text-xs font-bold uppercase tracking-widest text-snip-teal">
              The Seamless Journey
            </span>
            <h2 className="text-3xl font-extrabold tracking-tight text-snip-charcoal sm:text-4xl">
              Beauty Business, Beautifully Simple
            </h2>
            <p className="text-base text-snip-muted leading-relaxed">
              Designed from the ground up to eliminate waiting in line, phone tag,
              and appointment uncertainty.
            </p>
          </div>

          <div className="grid gap-8 md:grid-cols-3">
            {steps.map((step) => {
              const IconComp = step.icon;
              return (
                <div
                  key={step.number}
                  className="group relative rounded-2xl border border-snip-border bg-white p-8 transition hover:-translate-y-1 hover:border-snip-teal/50 hover:shadow-snip"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-snip-primary text-white shadow-snip-sm group-hover:scale-105 transition-transform">
                      <IconComp className="h-6 w-6" />
                    </div>
                    <span className="font-mono text-2xl font-black text-snip-border">
                      {step.number}
                    </span>
                  </div>

                  <h3 className="mt-6 text-xl font-bold text-snip-charcoal">
                    {step.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-snip-muted">
                    {step.subtitle}
                  </p>

                  <div className="mt-6 inline-flex items-center gap-1.5 rounded-full bg-snip-bg px-3 py-1 text-xs font-semibold text-snip-charcoal border border-snip-border">
                    <CheckCircle2 className="h-3.5 w-3.5 text-snip-teal" />
                    <span>{step.highlight}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* 6. FOR SALON OWNERS SECTION */}
      <section id="for-owners" className="bg-white py-20 border-b border-snip-border">
        <div className="snip-container">
          <div className="grid items-center gap-12 lg:grid-cols-12">
            {/* Left: Content */}
            <div className="space-y-6 lg:col-span-6">
              <div className="inline-flex items-center gap-2 rounded-full border border-snip-teal/30 bg-snip-primary/10 px-4 py-1.5 text-xs font-bold text-snip-teal">
                <TrendingUp className="h-3.5 w-3.5" />
                <span>Built For Growth & Efficiency</span>
              </div>

              <h2 className="text-3xl font-extrabold tracking-tight text-snip-charcoal sm:text-4xl leading-tight">
                Fill Empty Chairs. Eliminate No-Shows. Grow Your Salon.
              </h2>

              <p className="text-base text-snip-muted leading-relaxed">
                SNIP equips salon owners and barbers with world-class tools to
                manage daily queues, staff schedules, and client relationships — all
                from one intuitive dashboard.
              </p>

              <div className="space-y-3 pt-2">
                <div className="flex items-start gap-3">
                  <div className="mt-1 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-snip-teal/15 text-snip-teal">
                    <CheckCircle2 className="h-3.5 w-3.5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-snip-charcoal">
                      Smart QR Desk Scanner
                    </h4>
                    <p className="text-xs text-snip-muted">
                      Check in clients in 2 seconds using your phone camera or tablet scanner.
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="mt-1 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-snip-teal/15 text-snip-teal">
                    <CheckCircle2 className="h-3.5 w-3.5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-snip-charcoal">
                      Stylist & Staff Scheduling
                    </h4>
                    <p className="text-xs text-snip-muted">
                      Assign custom working hours, breaks, and service capabilities to individual barbers.
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="mt-1 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-snip-teal/15 text-snip-teal">
                    <CheckCircle2 className="h-3.5 w-3.5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-snip-charcoal">
                      Real-Time Appointment Stream
                    </h4>
                    <p className="text-xs text-snip-muted">
                      Never double-book again with automated conflict checks and instant notifications.
                    </p>
                  </div>
                </div>
              </div>

              <div className="pt-4 flex flex-wrap items-center gap-4">
                <Link href="/register?role=salon_owner">
                  <Button size="lg" className="rounded-full shadow-snip px-8 text-xs font-bold gap-2">
                    <span>List Your Salon Today</span>
                    <ArrowRight className="h-4 w-4" />
                  </Button>
                </Link>
                <Link href="/owner">
                  <Button variant="outline" size="lg" className="rounded-full text-xs font-bold">
                    View Demo Dashboard
                  </Button>
                </Link>
              </div>
            </div>

            {/* Right: Owner Visual Preview */}
            <div className="relative lg:col-span-6">
              <div className="overflow-hidden rounded-3xl border border-snip-border bg-snip-bg p-4 shadow-snip sm:p-6 space-y-4">
                <div className="flex items-center justify-between border-b border-snip-border pb-4">
                  <div className="flex items-center gap-3">
                    <SnipLogo size={32} showText={false} />
                    <div>
                      <div className="text-xs font-bold text-snip-charcoal">The Modern Cut</div>
                      <div className="text-[11px] text-snip-muted">Owner Management Portal</div>
                    </div>
                  </div>
                  <span className="rounded-full bg-emerald-100 px-2.5 py-0.5 text-[11px] font-bold text-emerald-800">
                    Live Realtime
                  </span>
                </div>

                {/* Mock Queue Items */}
                <div className="space-y-2.5">
                  <div className="flex items-center justify-between rounded-xl bg-white p-3 border border-snip-border shadow-sm">
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-full bg-snip-teal/15 text-snip-teal font-bold text-xs flex items-center justify-center">
                        JP
                      </div>
                      <div>
                        <div className="text-xs font-bold text-snip-charcoal">James Perera</div>
                        <div className="text-[11px] text-snip-muted">Men&apos;s Haircut • Kamal Perera</div>
                      </div>
                    </div>
                    <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-bold text-emerald-600 border border-emerald-100">
                      In Progress
                    </span>
                  </div>

                  <div className="flex items-center justify-between rounded-xl bg-white p-3 border border-snip-border shadow-sm">
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-full bg-snip-charcoal/10 text-snip-charcoal font-bold text-xs flex items-center justify-center">
                        SR
                      </div>
                      <div>
                        <div className="text-xs font-bold text-snip-charcoal">Sahan Rodrigo</div>
                        <div className="text-[11px] text-snip-muted">Beard Styling • 10:30 AM</div>
                      </div>
                    </div>
                    <span className="rounded-full bg-blue-50 px-2.5 py-1 text-[11px] font-bold text-blue-600 border border-blue-100">
                      Checked In
                    </span>
                  </div>

                  <div className="flex items-center justify-between rounded-xl bg-white p-3 border border-snip-border shadow-sm">
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-full bg-slate-100 text-slate-600 font-bold text-xs flex items-center justify-center">
                        NW
                      </div>
                      <div>
                        <div className="text-xs font-bold text-snip-charcoal">Nuwan Wickrama</div>
                        <div className="text-[11px] text-snip-muted">Hair Wash & Cut • 11:15 AM</div>
                      </div>
                    </div>
                    <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-bold text-slate-600">
                      Confirmed
                    </span>
                  </div>
                </div>

                <div className="pt-2 text-center">
                  <span className="text-[11px] font-semibold text-snip-muted">
                    ⚡ Instant updates sync across barber phones and front desk screens.
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 7. CLIENT TESTIMONIALS */}
      <section id="reviews" className="bg-snip-bg py-20 border-b border-snip-border">
        <div className="snip-container space-y-12">
          <div className="mx-auto max-w-2xl text-center space-y-2">
            <span className="text-xs font-bold uppercase tracking-widest text-snip-teal">
              Loved by Thousands
            </span>
            <h2 className="text-3xl font-extrabold tracking-tight text-snip-charcoal sm:text-4xl">
              Real Stories from Satisfied Clients
            </h2>
            <p className="text-sm text-snip-muted">
              See what salon guests and team owners say about their experience with SNIP.
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-3">
            {testimonials.map((t) => (
              <div
                key={t.name}
                className="flex flex-col justify-between rounded-2xl border border-snip-border bg-white p-6 shadow-snip-sm"
              >
                <div className="space-y-4">
                  {/* Star Rating */}
                  <div className="flex items-center gap-1">
                    {Array.from({ length: t.rating }).map((_, i) => (
                      <Star
                        key={i}
                        className="h-4 w-4 fill-amber-400 text-amber-400"
                      />
                    ))}
                  </div>

                  <p className="text-xs leading-relaxed text-snip-charcoal italic">
                    &ldquo;{t.quote}&rdquo;
                  </p>
                </div>

                <div className="mt-6 flex items-center gap-3 border-t border-snip-border pt-4">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={t.avatar}
                    alt={t.name}
                    className="h-10 w-10 rounded-full object-cover border border-snip-border"
                  />
                  <div>
                    <h4 className="text-xs font-bold text-snip-charcoal">
                      {t.name}
                    </h4>
                    <p className="text-[11px] text-snip-muted">{t.role}</p>
                    <p className="text-[10px] text-snip-teal font-semibold">
                      {t.salon}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 8. FAQ ACCORDION */}
      <section className="bg-white py-20 border-b border-snip-border">
        <div className="snip-container max-w-3xl space-y-10">
          <div className="text-center space-y-2">
            <span className="text-xs font-bold uppercase tracking-widest text-snip-teal">
              Got Questions?
            </span>
            <h2 className="text-3xl font-extrabold tracking-tight text-snip-charcoal">
              Frequently Asked Questions
            </h2>
          </div>

          <div className="space-y-4">
            {faqs.map((faq, idx) => (
              <div
                key={idx}
                className="rounded-2xl border border-snip-border bg-snip-bg p-5"
              >
                <h3 className="text-sm font-bold text-snip-charcoal">
                  {faq.question}
                </h3>
                <p className="mt-2 text-xs leading-relaxed text-snip-muted">
                  {faq.answer}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 9. BOTTOM CTA BANNER */}
      <section className="bg-snip-bg py-16">
        <div className="snip-container">
          <div className="relative overflow-hidden rounded-3xl bg-slate-900 border border-slate-800 p-8 sm:p-14 text-white shadow-xl">
            {/* Background Ambient Glow */}
            <div className="absolute top-0 right-0 h-64 w-64 rounded-full bg-snip-teal/20 blur-3xl pointer-events-none" />
            <div className="absolute bottom-0 left-0 h-64 w-64 rounded-full bg-snip-primary/15 blur-3xl pointer-events-none" />

            <div className="relative z-10 mx-auto max-w-2xl text-center space-y-6">
              <div className="flex justify-center">
                <SnipLogo variant="stacked" size={88} light={true} />
              </div>

              <h2 className="text-3xl font-extrabold tracking-tight sm:text-4xl text-white">
                Ready for Your Next Great Look?
              </h2>

              <p className="text-sm text-slate-300 leading-relaxed max-w-lg mx-auto">
                Join thousands of happy clients booking effortless appointments
                every day. Discover verified salons in your city now.
              </p>

              <div className="flex flex-wrap items-center justify-center gap-4 pt-2">
                <Link href="/explore">
                  <Button
                    size="lg"
                    className="rounded-full bg-snip-primary hover:bg-snip-primary-hover text-white px-8 text-xs font-bold shadow-lg"
                  >
                    Find a Salon Near Me
                  </Button>
                </Link>
                <Link href="/register?role=salon_owner">
                  <Button
                    variant="outline"
                    size="lg"
                    className="rounded-full border-white/20 text-white bg-transparent hover:bg-white/10 px-8 text-xs font-bold"
                  >
                    List Your Salon
                  </Button>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
