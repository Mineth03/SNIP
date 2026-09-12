import { format } from "date-fns";
import { EmptyState } from "@/components/ui/empty-state";
import { Card, CardContent } from "@/components/ui/card";
import { requireRole } from "@/lib/auth/require-role";
import { createClient } from "@/lib/supabase/server";
import type { BarberSchedule } from "@/types/database";

export const metadata = { title: "Schedule" };

export default async function BarberSchedulePage() {
  const profile = await requireRole(["barber", "admin"]);
  const supabase = await createClient();
  const { data: barber } = await supabase
    .from("barbers")
    .select("id, display_name")
    .eq("profile_id", profile.id)
    .maybeSingle();

  if (!barber) {
    return <EmptyState title="Barber profile not linked" />;
  }

  const { data: schedules } = await supabase
    .from("barber_schedules")
    .select("*")
    .eq("barber_id", barber.id)
    .order("day_of_week");

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-snip-charcoal">Schedule</h2>
        <p className="text-sm text-snip-muted">
          Weekly hours for {barber.display_name}. Contact your owner to change them.
        </p>
      </div>
      {!schedules?.length ? (
        <EmptyState title="No schedule configured" description="Ask your salon owner to set working hours." />
      ) : (
        <div className="grid gap-3 sm:grid-cols-2">
          {(schedules as BarberSchedule[]).map((slot) => (
            <Card key={slot.id}>
              <CardContent className="flex items-center justify-between p-4">
                <p className="font-semibold capitalize text-snip-charcoal">
                  {slot.day_of_week}
                </p>
                <p className="text-sm text-snip-muted">
                  {slot.is_working
                    ? `${slot.start_time.slice(0, 5)} – ${slot.end_time.slice(0, 5)}`
                    : "Off"}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
      <p className="text-xs text-snip-muted">
        Today is {format(new Date(), "EEEE")}.
      </p>
    </div>
  );
}
