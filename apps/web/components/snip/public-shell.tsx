import Link from "next/link";
import { Button } from "@/components/ui/button";

export function PublicHeader() {
  return (
    <header className="sticky top-0 z-30 border-b border-snip-border/80 bg-white/85 backdrop-blur">
      <div className="snip-container flex h-16 items-center justify-between gap-4">
        <Link href="/" className="text-xl font-bold tracking-tight text-snip-charcoal">
          SNIP
        </Link>
        <nav className="hidden items-center gap-6 text-sm font-medium text-snip-muted md:flex">
          <Link href="/explore" className="hover:text-snip-charcoal">
            Explore
          </Link>
          <Link href="/register?role=salon_owner" className="hover:text-snip-charcoal">
            For salons
          </Link>
          <Link href="/login" className="hover:text-snip-charcoal">
            Sign in
          </Link>
        </nav>
        <div className="flex items-center gap-2">
          <Link href="/login" className="md:hidden">
            <Button type="button" variant="ghost" size="sm">
              Sign in
            </Button>
          </Link>
          <Link href="/explore">
            <Button type="button" size="sm">
              Find a Salon
            </Button>
          </Link>
        </div>
      </div>
    </header>
  );
}

export function PublicFooter() {
  return (
    <footer className="border-t border-snip-border bg-white">
      <div className="snip-container grid gap-8 py-12 md:grid-cols-4">
        <div className="md:col-span-2">
          <div className="text-xl font-bold text-snip-charcoal">SNIP</div>
          <p className="mt-3 max-w-md text-sm leading-relaxed text-snip-muted">
            Smart salon booking and management for modern beauty businesses and
            the customers who love them.
          </p>
        </div>
        <div>
          <p className="text-sm font-semibold text-snip-charcoal">Product</p>
          <div className="mt-3 space-y-2 text-sm text-snip-muted">
            <Link href="/explore" className="block hover:text-snip-charcoal">
              Explore salons
            </Link>
            <Link
              href="/register?role=salon_owner"
              className="block hover:text-snip-charcoal"
            >
              List your salon
            </Link>
            <Link href="/login" className="block hover:text-snip-charcoal">
              Sign in
            </Link>
          </div>
        </div>
        <div>
          <p className="text-sm font-semibold text-snip-charcoal">Company</p>
          <div className="mt-3 space-y-2 text-sm text-snip-muted">
            <span className="block">Support: hello@snip.app</span>
            <span className="block">Built for salons & guests</span>
          </div>
        </div>
      </div>
      <div className="border-t border-snip-border py-4 text-center text-xs text-snip-muted">
        © {new Date().getFullYear()} SNIP. All rights reserved.
      </div>
    </footer>
  );
}
