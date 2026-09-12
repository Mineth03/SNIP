import type { NavItem } from "@/components/snip/sidebar";

export const customerNav: NavItem[] = [
  { href: "/customer", label: "Home", icon: "LayoutDashboard" },
  { href: "/customer/bookings", label: "Bookings", icon: "ClipboardList" },
  { href: "/customer/favorites", label: "Favorites", icon: "Heart" },
  { href: "/customer/profile", label: "Profile", icon: "UserRound" },
];

export const ownerNav: NavItem[] = [
  { href: "/owner", label: "Dashboard", icon: "LayoutDashboard" },
  { href: "/owner/bookings", label: "Bookings", icon: "ClipboardList" },
  { href: "/owner/calendar", label: "Calendar", icon: "CalendarDays" },
  { href: "/owner/services", label: "Services", icon: "Sparkles" },
  { href: "/owner/staff", label: "Staff", icon: "Users" },
  { href: "/owner/salon", label: "Salon", icon: "Store" },
  { href: "/owner/gallery", label: "Gallery", icon: "Images" },
  { href: "/owner/walk-in", label: "Walk-in", icon: "MapPinned" },
  { href: "/owner/qr", label: "QR Check-in", icon: "QrCode" },
  { href: "/owner/notifications", label: "Notifications", icon: "Bell" },
  { href: "/owner/settings", label: "Settings", icon: "Settings" },
];

export const barberNav: NavItem[] = [
  { href: "/barber", label: "Dashboard", icon: "LayoutDashboard" },
  { href: "/barber/appointments", label: "Appointments", icon: "ClipboardList" },
  { href: "/barber/schedule", label: "Schedule", icon: "CalendarDays" },
  { href: "/barber/scan", label: "Scan QR", icon: "ScanLine" },
  { href: "/barber/profile", label: "Profile", icon: "UserRound" },
];

export const adminNav: NavItem[] = [
  { href: "/admin", label: "Dashboard", icon: "LayoutDashboard" },
  { href: "/admin/users", label: "Users", icon: "UserCog" },
  { href: "/admin/salons", label: "Salons", icon: "Store" },
  { href: "/admin/bookings", label: "Bookings", icon: "ClipboardList" },
  { href: "/admin/services", label: "Services", icon: "Scissors" },
  { href: "/admin/verification", label: "Verification", icon: "ShieldCheck" },
  { href: "/admin/reports", label: "Reports", icon: "FileBarChart" },
  { href: "/admin/notifications", label: "Notifications", icon: "Bell" },
  { href: "/admin/settings", label: "Settings", icon: "Settings" },
];
