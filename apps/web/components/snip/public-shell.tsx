import Link from "next/link";
import { Sparkles, ArrowRight, ShieldCheck, Heart } from "lucide-react";
import { Button } from "@/components/ui/button";
import { SnipLogo } from "@/components/snip/snip-logo";
import { ThemeToggle } from "@/components/snip/theme-toggle";

export function PublicHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-snip-border/80 bg-white/90 backdrop-blur-md transition-all">
      <div className="snip-container flex h-16 items-center justify-between gap-4">
        {/* Brand Monogram & Name */}
        <Link href="/" className="flex items-center transition hover:opacity-95">
          <SnipLogo size={48} />
        </Link>

        {/* Navigation items */}
        <nav className="hidden items-center gap-7 text-sm font-semibold text-snip-muted md:flex">
          <Link
            href="/explore"
            className="transition hover:text-snip-charcoal"
          >
            Explore Salons
          </Link>
          <Link
            href="/#how-it-works"
            className="transition hover:text-snip-charcoal"
          >
            How It Works
          </Link>
          <Link
            href="/#for-owners"
            className="transition hover:text-snip-charcoal"
          >
            For Salon Owners
          </Link>
          <Link
            href="/#reviews"
            className="transition hover:text-snip-charcoal"
          >
            Reviews
          </Link>
        </nav>

        {/* Auth / Action buttons & Theme Toggle */}
        <div className="flex items-center gap-2">
          <ThemeToggle />
          <Link href="/login">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="text-xs font-semibold text-snip-charcoal hover:bg-snip-bg"
            >
              Sign In
            </Button>
          </Link>
          <Link href="/explore">
            <Button
              type="button"
              size="sm"
              className="rounded-full shadow-snip-sm px-4 text-xs font-bold gap-1.5"
            >
              <Sparkles className="h-3.5 w-3.5" />
              <span>Book Appointment</span>
            </Button>
          </Link>
        </div>
      </div>
    </header>
  );
}

export function PublicFooter() {
  return (
    <footer className="border-t border-snip-border bg-white text-snip-charcoal">
      <div className="snip-container grid gap-10 py-14 sm:grid-cols-2 md:grid-cols-5">
        {/* Brand Column */}
        <div className="space-y-4 md:col-span-2">
          <Link href="/" className="inline-block transition hover:opacity-95">
            <SnipLogo variant="stacked" size={68} />
          </Link>
          <p className="max-w-sm text-sm leading-relaxed text-snip-muted">
            The smart salon booking and management platform. Discover verified
            salons, book top stylists in real-time, and check in instantly with
            contactless QR tickets.
          </p>
          <div className="flex items-center gap-2 text-xs font-semibold text-snip-teal">
            <ShieldCheck className="h-4 w-4" />
            <span>100% Verified Quality Salons & Stylists</span>
          </div>
        </div>

        {/* Explore Column */}
        <div className="space-y-3">
          <p className="text-xs font-bold uppercase tracking-wider text-snip-charcoal">
            Clients
          </p>
          <div className="space-y-2 text-sm text-snip-muted">
            <Link href="/explore" className="block hover:text-snip-teal transition-colors">
              Explore Salons
            </Link>
            <Link href="/explore?category=hair" className="block hover:text-snip-teal transition-colors">
              Haircuts & Styling
            </Link>
            <Link href="/explore?category=beard" className="block hover:text-snip-teal transition-colors">
              Beard & Grooming
            </Link>
            <Link href="/customer/bookings" className="block hover:text-snip-teal transition-colors">
              My Appointments
            </Link>
            <Link href="/customer/favorites" className="block hover:text-snip-teal transition-colors">
              Saved Favorites
            </Link>
          </div>
        </div>

        {/* Salons Column */}
        <div className="space-y-3">
          <p className="text-xs font-bold uppercase tracking-wider text-snip-charcoal">
            Salon Owners
          </p>
          <div className="space-y-2 text-sm text-snip-muted">
            <Link
              href="/register?role=salon_owner"
              className="block hover:text-snip-teal transition-colors font-medium text-snip-charcoal"
            >
              List Your Salon →
            </Link>
            <Link href="/owner" className="block hover:text-snip-teal transition-colors">
              Owner Dashboard
            </Link>
            <Link href="/owner/staff" className="block hover:text-snip-teal transition-colors">
              Stylist & Staff Management
            </Link>
            <Link href="/owner/qr" className="block hover:text-snip-teal transition-colors">
              QR Check-in Station
            </Link>
            <Link href="/owner/services" className="block hover:text-snip-teal transition-colors">
              Custom Services Menu
            </Link>
          </div>
        </div>

        {/* Portals & Support Column */}
        <div className="space-y-3">
          <p className="text-xs font-bold uppercase tracking-wider text-snip-charcoal">
            Platform & Help
          </p>
          <div className="space-y-2 text-sm text-snip-muted">
            <Link href="/barber" className="block hover:text-snip-teal transition-colors">
              Barber Portal
            </Link>
            <Link href="/admin" className="block hover:text-snip-teal transition-colors">
              Admin Portal
            </Link>
            <span className="block text-xs pt-1">
              Contact:{" "}
              <a href="mailto:support@snip.lk" className="text-snip-teal hover:underline font-medium">
                support@snip.lk
              </a>
            </span>
            <span className="block text-xs text-snip-muted">Colombo, Sri Lanka</span>
          </div>
        </div>
      </div>

      <div className="border-t border-snip-border/80 bg-snip-bg py-5 text-center text-xs text-snip-muted">
        <div className="snip-container flex flex-col items-center justify-between gap-2 sm:flex-row">
          <p>© {new Date().getFullYear()} SNIP Technologies. All rights reserved.</p>
          <p className="flex items-center gap-1 text-[11px]">
            Designed with <Heart className="h-3 w-3 fill-rose-500 text-rose-500 inline" /> for salons & guests.
          </p>
        </div>
      </div>
    </footer>
  );
}
