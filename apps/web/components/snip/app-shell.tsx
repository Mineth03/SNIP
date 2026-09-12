"use client";

import { useState } from "react";
import { LogOut, X } from "lucide-react";
import { useRouter } from "next/navigation";
import { RealtimeNotificationListener } from "@/components/snip/realtime-notification-listener";
import { Sidebar, type NavItem } from "@/components/snip/sidebar";
import { Topbar } from "@/components/snip/topbar";
import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";

export function AppShell({
  title,
  description,
  items,
  profileName,
  profileAvatar,
  darkSidebar = false,
  brandTitle = "SNIP",
  brandSubtitle,
  children,
  actions,
}: {
  title: string;
  description?: string;
  items: NavItem[];
  profileName: string;
  profileAvatar?: string | null;
  darkSidebar?: boolean;
  brandTitle?: string;
  brandSubtitle?: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  async function signOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  const footer = (
    <Button
      type="button"
      variant={darkSidebar ? "ghost" : "outline"}
      className={cn(
        "w-full justify-start gap-2",
        darkSidebar && "text-white hover:bg-white/10 hover:text-white",
      )}
      onClick={signOut}
    >
      <LogOut className="h-4 w-4" />
      Sign out
    </Button>
  );

  return (
    <div className="flex min-h-screen bg-snip-bg">
      <div className="hidden md:block">
        <Sidebar
          items={items}
          title={brandTitle}
          subtitle={brandSubtitle}
          dark={darkSidebar}
          footer={footer}
        />
      </div>

      {open ? (
        <div className="fixed inset-0 z-40 flex md:hidden">
          <button
            type="button"
            className="absolute inset-0 bg-snip-charcoal/40"
            aria-label="Close menu overlay"
            onClick={() => setOpen(false)}
          />
          <div className="relative z-10 h-full">
            <Sidebar
              items={items}
              title={brandTitle}
              subtitle={brandSubtitle}
              dark={darkSidebar}
              footer={
                <div className="space-y-2">
                  <Button
                    type="button"
                    variant="ghost"
                    className="w-full justify-start"
                    onClick={() => setOpen(false)}
                  >
                    <X className="mr-2 h-4 w-4" />
                    Close
                  </Button>
                  {footer}
                </div>
              }
            />
          </div>
        </div>
      ) : null}

      <RealtimeNotificationListener />
      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar
          title={title}
          description={description}
          profileName={profileName}
          profileAvatar={profileAvatar}
          actions={actions}
          onMenuClick={() => setOpen(true)}
        />
        <main className="flex-1 p-4 md:p-6">{children}</main>
      </div>
    </div>
  );
}
