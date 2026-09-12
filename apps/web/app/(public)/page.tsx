import Link from "next/link";
import {
  CalendarCheck2,
  MapPinned,
  QrCode,
  Scissors,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { Button } from "@/components/ui/button";

const steps = [
  {
    icon: MapPinned,
    title: "Discover salons",
    body: "Browse verified salons near you with services, pricing, and availability.",
  },
  {
    icon: CalendarCheck2,
    title: "Book in minutes",
    body: "Pick a service, stylist, and time slot — confirmation arrives instantly.",
  },
  {
    icon: QrCode,
    title: "Check in with QR",
    body: "Arrive stress-free. Show your ticket and jump into your appointment.",
  },
];

const benefits = [
  {
    icon: Sparkles,
    title: "Premium guest experience",
    body: "Clean booking flows, reminders, and favorites keep guests coming back.",
  },
  {
    icon: Scissors,
    title: "Built for salon teams",
    body: "Owners manage staff, services, walk-ins, and calendars in one place.",
  },
  {
    icon: ShieldCheck,
    title: "Verified & trustworthy",
    body: "Salon verification and role-based access keep the marketplace reliable.",
  },
];

export default function LandingPage() {
  return (
    <>
      <section className="snip-gradient-hero relative overflow-hidden">
        <div className="snip-container grid items-center gap-10 py-16 md:grid-cols-2 md:py-24 lg:py-28">
          <div className="space-y-6">
            <p className="text-sm font-semibold uppercase tracking-[0.14em] text-snip-teal">
              SNIP
            </p>
            <h1 className="max-w-xl text-4xl font-bold tracking-tight text-snip-charcoal sm:text-5xl lg:text-[3.35rem] lg:leading-[1.1]">
              Your next look, just a booking away.
            </h1>
            <p className="max-w-lg text-base leading-relaxed text-snip-muted sm:text-lg">
              SNIP connects customers with trusted salons and gives owners the
              tools to run bookings, staff, and walk-ins without the chaos.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link href="/explore">
                <Button type="button" size="lg">
                  Find a Salon
                </Button>
              </Link>
              <Link href="/register?role=salon_owner">
                <Button type="button" size="lg" variant="outline">
                  List Your Salon
                </Button>
              </Link>
            </div>
          </div>
          <div className="relative">
            <div className="absolute -inset-6 rounded-[28px] bg-gradient-to-br from-snip-teal/20 via-snip-primary/10 to-transparent blur-2xl" />
            <div className="relative overflow-hidden rounded-2xl border border-snip-border bg-white shadow-snip">
              <div className="border-b border-snip-border bg-snip-charcoal px-5 py-4 text-white">
                <div className="text-sm text-white/70">Today at Glow Studio</div>
                <div className="mt-1 text-lg font-semibold">4 appointments ready</div>
              </div>
              <div className="space-y-3 p-5">
                {[
                  ["Signature Haircut", "10:30 AM", "Confirmed"],
                  ["Beard Trim", "11:15 AM", "Checked in"],
                  ["Colour Refresh", "1:00 PM", "Confirmed"],
                ].map(([service, time, status]) => (
                  <div
                    key={service}
                    className="flex items-center justify-between rounded-md border border-snip-border bg-snip-bg px-4 py-3"
                  >
                    <div>
                      <div className="text-sm font-semibold text-snip-charcoal">
                        {service}
                      </div>
                      <div className="text-xs text-snip-muted">{time}</div>
                    </div>
                    <span className="rounded-md bg-snip-primary/10 px-2 py-1 text-xs font-semibold text-snip-teal">
                      {status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="border-y border-snip-border bg-white py-16 md:py-20">
        <div className="snip-container">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-snip-charcoal">
              How SNIP Works
            </h2>
            <p className="mt-3 text-snip-muted">
              From discovery to check-in, every step feels effortless.
            </p>
          </div>
          <div className="mt-10 grid gap-6 md:grid-cols-3">
            {steps.map((step, index) => (
              <div
                key={step.title}
                className="rounded-lg border border-snip-border bg-snip-bg p-6 shadow-snip-sm"
              >
                <div className="mb-4 flex items-center justify-between">
                  <div className="rounded-md bg-snip-primary/10 p-2.5 text-snip-teal">
                    <step.icon className="h-5 w-5" />
                  </div>
                  <span className="text-sm font-semibold text-snip-muted">
                    0{index + 1}
                  </span>
                </div>
                <h3 className="text-lg font-semibold text-snip-charcoal">
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

      <section className="py-16 md:py-20">
        <div className="snip-container">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-snip-charcoal">
              Why teams choose SNIP
            </h2>
            <p className="mt-3 text-snip-muted">
              A premium SaaS experience for guests, owners, and stylists alike.
            </p>
          </div>
          <div className="mt-10 grid gap-6 md:grid-cols-3">
            {benefits.map((item) => (
              <div
                key={item.title}
                className="rounded-lg border border-snip-border bg-white p-6 shadow-snip-sm"
              >
                <div className="mb-4 rounded-md bg-snip-charcoal p-2.5 text-white w-fit">
                  <item.icon className="h-5 w-5" />
                </div>
                <h3 className="text-lg font-semibold text-snip-charcoal">
                  {item.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-snip-muted">
                  {item.body}
                </p>
              </div>
            ))}
          </div>
          <div className="mt-12 flex flex-wrap items-center justify-center gap-3">
            <Link href="/explore">
              <Button type="button" size="lg">
                Explore salons
              </Button>
            </Link>
            <Link href="/register">
              <Button type="button" size="lg" variant="secondary">
                Create free account
              </Button>
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
