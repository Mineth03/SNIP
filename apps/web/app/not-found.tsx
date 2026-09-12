import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 px-4 text-center">
      <p className="text-sm font-semibold uppercase tracking-[0.14em] text-snip-teal">
        404
      </p>
      <h1 className="text-3xl font-bold text-snip-charcoal">Page not found</h1>
      <p className="max-w-md text-snip-muted">
        The page you’re looking for doesn’t exist or may have moved.
      </p>
      <Link href="/">
        <Button type="button">Back to home</Button>
      </Link>
    </div>
  );
}
