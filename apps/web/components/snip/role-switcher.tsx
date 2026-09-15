"use client";

import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Building2, Scissors, UserRound } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { getActiveRoleHome, roleLabel } from "@/lib/auth/roles";
import type { UserRole } from "@/types/database";
import { cn } from "@/lib/utils";

type Props = {
  capabilities: Array<"customer" | "salon_owner" | "barber" | "admin">;
  activeRole: UserRole;
  className?: string;
};

const HATS: {
  role: UserRole;
  capability: "customer" | "salon_owner" | "barber";
  icon: typeof UserRound;
  description: string;
}[] = [
  {
    role: "customer",
    capability: "customer",
    icon: UserRound,
    description: "Book salons and manage appointments",
  },
  {
    role: "salon_owner",
    capability: "salon_owner",
    icon: Building2,
    description: "Manage your salon, staff, and bookings",
  },
  {
    role: "barber",
    capability: "barber",
    icon: Scissors,
    description: "Chair schedule, check-ins, and clients",
  },
];

export function RoleSwitcher({ capabilities, activeRole, className }: Props) {
  const router = useRouter();

  async function switchTo(role: UserRole) {
    if (role === activeRole) return;
    const supabase = createClient();
    const { error } = await supabase.rpc("set_active_role", { p_role: role });
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success(`Switched to ${roleLabel(role)}`);
    router.push(getActiveRoleHome(role));
    router.refresh();
  }

  return (
    <div className={cn("space-y-3", className)}>
      <div>
        <h3 className="text-sm font-bold text-snip-charcoal">Switch profile view</h3>
        <p className="text-xs text-snip-muted">
          One account can hold multiple roles. Choose which workspace to open.
        </p>
      </div>
      <div className="grid gap-2">
        {HATS.map((hat) => {
          const available = capabilities.includes(hat.capability);
          const Icon = hat.icon;
          const isActive = activeRole === hat.role;
          return (
            <button
              key={hat.role}
              type="button"
              disabled={!available}
              onClick={() => available && switchTo(hat.role)}
              className={cn(
                "flex items-start gap-3 rounded-xl border px-3 py-3 text-left transition",
                isActive
                  ? "border-snip-teal bg-snip-teal/10"
                  : available
                    ? "border-snip-border bg-white hover:border-snip-teal/50 dark:bg-slate-900"
                    : "cursor-not-allowed border-dashed border-snip-border/70 bg-snip-bg opacity-70",
              )}
            >
              <div
                className={cn(
                  "mt-0.5 rounded-lg p-2",
                  isActive ? "bg-snip-teal text-white" : "bg-snip-bg text-snip-muted",
                )}
              >
                <Icon className="h-4 w-4" />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-2">
                  <span className="text-sm font-semibold text-snip-charcoal">
                    {roleLabel(hat.role)}
                  </span>
                  {isActive ? (
                    <span className="text-[10px] font-bold uppercase tracking-wide text-snip-teal">
                      Active
                    </span>
                  ) : null}
                </div>
                <p className="text-xs text-snip-muted">{hat.description}</p>
                {!available ? (
                  <p className="mt-1 text-[11px] text-snip-muted">
                    {hat.role === "salon_owner"
                      ? "Use “Become a salon owner” below to unlock."
                      : hat.role === "barber"
                        ? "Ask a salon owner to invite you to their team."
                        : null}
                  </p>
                ) : null}
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}
