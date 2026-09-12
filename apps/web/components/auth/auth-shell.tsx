"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { SnipLogo } from "@/components/snip/snip-logo";
import { ThemeToggle } from "@/components/snip/theme-toggle";

interface AuthShellProps {
  children: React.ReactNode;
  title: string;
  subtitle: string;
  mode?: "login" | "register" | "reset";
}

export function AuthShell({ children, title, subtitle }: AuthShellProps) {
  return (
    <div className="relative min-h-screen w-full overflow-hidden bg-[#F8FAFB] text-slate-800 transition-colors duration-200 dark:bg-[#0B1120] dark:text-slate-100 flex flex-col justify-center">
      {/* Full Background Wallpaper (Light and Dark Mode) */}
      <div className="fixed inset-0 z-0 pointer-events-none select-none">
        {/* Light Mode Full Background */}
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/login-back-light.png"
          alt="SNIP Salon Experience"
          className="h-full w-full object-cover object-left-bottom dark:hidden"
        />
        {/* Dark Mode Full Background */}
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/login-back-dark.png"
          alt="SNIP Salon Experience"
          className="hidden h-full w-full object-cover object-left-bottom dark:block"
        />
      </div>

      {/* Floating Header Controls: Back to Home + Theme Toggle */}
      <div className="absolute top-4 left-4 sm:top-6 sm:left-8 z-30">
        <Link
          href="/"
          className="group inline-flex items-center gap-2 rounded-full border border-slate-200/80 bg-white/85 px-3.5 py-1.5 text-xs font-semibold text-slate-700 shadow-xs backdrop-blur-md transition hover:border-snip-teal/60 hover:bg-white hover:text-snip-teal dark:border-slate-800 dark:bg-slate-900/85 dark:text-slate-200 dark:hover:bg-slate-800 dark:hover:text-snip-teal"
        >
          <ArrowLeft className="h-3.5 w-3.5 transition-transform group-hover:-translate-x-0.5" />
          <span>Back to Home</span>
        </Link>
      </div>

      <div className="absolute top-4 right-4 sm:top-6 sm:right-8 z-30">
        <ThemeToggle />
      </div>

      {/* Main Screen Layout Container */}
      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 py-8 sm:px-6 lg:px-12 flex items-center min-h-screen">
        <div className="grid w-full grid-cols-1 items-center lg:grid-cols-12 gap-8">
          {/* Left Column: Slogan on top left */}
          <div className="hidden lg:col-span-6 lg:flex lg:flex-col lg:justify-between self-stretch pt-6 pb-4 z-10 pointer-events-none">
            {/* Top-Left Slogan */}
            <div className="pl-2 pt-2">
              <h1 className="text-3xl xl:text-4xl font-extrabold tracking-[0.24em] text-[#3D4754] uppercase leading-[1.2] dark:text-white font-sans drop-shadow-xs">
                BEAUTY<br />
                FITS A<br />
                BUSIER YOU
              </h1>
              {/* Teal Accent Bar */}
              <div className="h-[2.5px] w-9 rounded-full bg-snip-teal my-3" />
              {/* Tagline */}
              <div className="flex items-center gap-2.5 text-xs font-semibold tracking-[0.28em] uppercase text-slate-500 dark:text-slate-300">
                <span>BOOK</span>
                <span className="text-snip-teal text-xs">•</span>
                <span>MANAGE</span>
                <span className="text-snip-teal text-xs">•</span>
                <span>GROW</span>
              </div>
            </div>

            {/* Spacer allowing background artwork to remain visible */}
            <div className="h-64 xl:h-72" />
          </div>

          {/* Right Column: Centered Glass/White Auth Card */}
          <div className="w-full lg:col-span-6 flex justify-center lg:justify-end z-20">
            <div className="relative w-full max-w-[430px] rounded-[32px] border border-slate-100/90 bg-white/95 p-7 sm:p-9 shadow-[0_20px_50px_rgba(0,0,0,0.06)] backdrop-blur-xl dark:border-slate-800/80 dark:bg-slate-900/95 dark:shadow-[0_20px_50px_rgba(0,0,0,0.5)]">
              {/* Header inside card */}
              <div className="mb-6 flex flex-col items-center text-center">
                <Link href="/" className="mb-3 transition hover:opacity-90">
                  <SnipLogo variant="stacked" size={76} />
                </Link>
                <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-[25px]">
                  {title}
                </h2>
                <p className="mt-1.5 text-xs text-slate-500 dark:text-slate-400 sm:text-sm leading-relaxed max-w-xs">
                  {subtitle}
                </p>
              </div>

              {/* Form Component */}
              {children}
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Right Handwritten Calligraphy Quote */}
      <div className="pointer-events-none absolute bottom-4 right-6 hidden select-none md:block lg:bottom-6 lg:right-10 z-20">
        <div
          className="text-right text-lg lg:text-xl font-normal text-slate-400/90 dark:text-teal-400/80 -rotate-6 transform leading-tight"
          style={{ fontFamily: "'Dancing Script', 'Caveat', 'Brush Script MT', cursive, serif" }}
        >
          Self care<br />
          <span className="italic">looks good</span><br />
          <span className="italic ml-2">on you</span>
        </div>
        <div className="h-[2px] w-9 rounded-full bg-snip-teal/80 ml-auto mt-1 -rotate-6" />
      </div>
    </div>
  );
}
