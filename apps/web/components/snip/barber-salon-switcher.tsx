"use client";

import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";

type Membership = { salonId: string; salonName: string; barberId: string };

export function BarberSalonSwitcher({
  memberships,
  activeSalonId,
}: {
  memberships: Membership[];
  activeSalonId: string;
}) {
  const router = useRouter();

  if (memberships.length <= 1) {
    return memberships[0] ? (
      <p className="text-xs text-snip-muted">Salon: {memberships[0].salonName}</p>
    ) : null;
  }

  async function switchSalon(salonId: string) {
    if (salonId === activeSalonId) return;
    const supabase = createClient();
    const { error } = await supabase.rpc("set_active_barber_salon", {
      p_salon_id: salonId,
    });
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Switched salon");
    router.refresh();
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="text-xs font-semibold text-snip-muted">Working at:</span>
      {memberships.map((m) => (
        <button
          key={m.salonId}
          type="button"
          onClick={() => switchSalon(m.salonId)}
          className={cn(
            "rounded-full border px-3 py-1 text-xs font-semibold transition",
            m.salonId === activeSalonId
              ? "border-snip-teal bg-snip-teal text-white"
              : "border-snip-border bg-white text-snip-charcoal hover:border-snip-teal/50",
          )}
        >
          {m.salonName}
        </button>
      ))}
    </div>
  );
}
