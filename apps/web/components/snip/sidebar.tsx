"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Bell,
  CalendarDays,
  ClipboardList,
  FileBarChart,
  Heart,
  Images,
  LayoutDashboard,
  type LucideIcon,
  MapPinned,
  QrCode,
  ScanLine,
  Scissors,
  Settings,
  ShieldCheck,
  Sparkles,
  Store,
  UserCog,
  UserRound,
  Users,
} from "lucide-react";
import { SnipLogo } from "@/components/snip/snip-logo";
import { cn } from "@/lib/utils";

const ICON_MAP: Record<string, LucideIcon> = {
  Bell,
  CalendarDays,
  ClipboardList,
  FileBarChart,
  Heart,
  Images,
  LayoutDashboard,
  MapPinned,
  QrCode,
  ScanLine,
  Scissors,
  Settings,
  ShieldCheck,
  Sparkles,
  Store,
  UserCog,
  UserRound,
  Users,
};

export type NavItem = {
  href: string;
  label: string;
  icon: string | LucideIcon;
};

export function Sidebar({
  items,
  title = "SNIP",
  subtitle,
  dark = false,
  footer,
}: {
  items: NavItem[];
  title?: string;
  subtitle?: string;
  dark?: boolean;
  footer?: React.ReactNode;
}) {
  const pathname = usePathname();

  return (
    <aside
      className={cn(
        "flex h-full w-64 shrink-0 flex-col border-r",
        dark
          ? "border-slate-800 bg-slate-900 text-white"
          : "border-snip-border bg-white text-snip-charcoal",
      )}
    >
      <div className="border-b border-inherit px-5 py-4">
        <Link href="/" className="flex items-center gap-3 transition hover:opacity-90">
          <SnipLogo size={32} light={dark ? true : undefined} showText={false} />
          <div>
            <div className="text-base font-bold tracking-tight">{title}</div>
            {subtitle ? (
              <div
                className={cn(
                  "text-[11px] font-medium",
                  dark ? "text-white/60" : "text-snip-muted",
                )}
              >
                {subtitle}
              </div>
            ) : null}
          </div>
        </Link>
      </div>
      <nav className="flex-1 space-y-1 overflow-y-auto p-3">
        {items.map((item) => {
          const active =
            pathname === item.href || pathname.startsWith(`${item.href}/`);
          const Icon =
            typeof item.icon === "string"
              ? (ICON_MAP[item.icon] ?? LayoutDashboard)
              : item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition",
                dark
                  ? active
                    ? "bg-white/10 text-white"
                    : "text-white/70 hover:bg-white/5 hover:text-white"
                  : active
                    ? "bg-snip-primary/10 text-snip-teal"
                    : "text-snip-muted hover:bg-snip-bg-muted hover:text-snip-charcoal",
              )}
            >
              <Icon className="h-4 w-4" />
              {item.label}
            </Link>
          );
        })}
      </nav>
      {footer ? <div className="border-t border-inherit p-4">{footer}</div> : null}
    </aside>
  );
}
