import { format } from "date-fns";
import { BarberSalonSwitcher } from "@/components/snip/barber-salon-switcher";
import { EmptyState } from "@/components/ui/empty-state";
import { Card, CardContent } from "@/components/ui/card";
import { getActiveBarberContext } from "@/lib/auth/barber-context";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { BarberSchedule } from "@/types/database";

export const metadata = { title: "Schedule" };

export default async function BarberSchedulePage() {
  const profile = await requireRole(["barber", "admin"]);
  const supabase = await createClient();
  const ctx = await getActiveBarberContext(profile);

  if (!ctx) {
    return <EmptyState title="You’re not on a salon team yet" />;
  }

  const { data: schedules } = await supabase
    .from("barber_schedules")
    .select("*")
    .eq("barber_id", ctx.barberId)
    .order("day_of_week");

  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <h2 className="text-2xl font-semibold text-snip-charcoal">Schedule</h2>
        <p className="text-sm text-snip-muted">
          Weekly hours for {ctx.displayName} at {ctx.salonName}. Ask the owner to
          change them.
        </p>
        <BarberSalonSwitcher
          memberships={ctx.memberships}
          activeSalonId={ctx.salonId}
        />
      </div>
      {!schedules?.length ? (
        <EmptyState
          title="No schedule configured"
          description="Ask your salon owner to set working hours."
        />
      ) : (
        <div className="grid gap-3 sm:grid-cols-2">
          {(schedules as BarberSchedule[]).map((slot) => (
            <Card key={slot.id}>
              <CardContent className="p-4">
                <p className="font-semibold capitalize text-snip-charcoal">
                  {slot.day_of_week}
                </p>
                <p className="text-sm text-snip-muted">
                  {format(new Date(`1970-01-01T${slot.start_time}`), "h:mm a")} –{" "}
                  {format(new Date(`1970-01-01T${slot.end_time}`), "h:mm a")}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
