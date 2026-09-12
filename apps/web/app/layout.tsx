import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { AppToaster } from "@/components/providers/app-toaster";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "SNIP — Smart Salon Booking",
    template: "%s · SNIP",
  },
  description:
    "SNIP is a smart salon booking and management system for customers, owners, barbers, and admins.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${inter.variable} h-full antialiased`}>
      <body className="min-h-full bg-snip-bg font-sans text-snip-charcoal">
        {children}
        <AppToaster />
      </body>
    </html>
  );
}
