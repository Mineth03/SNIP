"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { Bell, Calendar, Scissors } from "lucide-react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import type { RealtimeChannel } from "@supabase/supabase-js";
import type { Notification } from "@/types/database";

export function RealtimeNotificationListener({
  userId,
  salonId,
  barberId,
}: {
  userId?: string;
  salonId?: string;
  barberId?: string;
}) {
  const router = useRouter();

  useEffect(() => {
    const supabase = createClient();
    let isCancelled = false;
    let notifChannel: RealtimeChannel | null = null;
    let bookingChannel: RealtimeChannel | null = null;

    async function setupSubscriptions() {
      let effectiveUserId = userId;
      if (!effectiveUserId) {
        const {
          data: { user },
        } = await supabase.auth.getUser();
        effectiveUserId = user?.id;
      }

      if (!effectiveUserId || isCancelled) return;

      // 1. Subscribe to user notifications
      const notifTopic = `user-notifs-${effectiveUserId}`;
      // Clean up any stale channel with this topic first
      const existingNotif = supabase
        .getChannels()
        .find((c) => c.topic === `realtime:${notifTopic}`);
      if (existingNotif) {
        await supabase.removeChannel(existingNotif);
      }
      if (isCancelled) return;

      notifChannel = supabase
        .channel(notifTopic)
        .on(
          "postgres_changes",
          {
            event: "INSERT",
            schema: "public",
            table: "notifications",
            filter: `user_id=eq.${effectiveUserId}`,
          },
          (payload) => {
            const notif = payload.new as Notification;
            toast(notif.title, {
              description: notif.message,
              icon: <Bell className="h-4 w-4 text-snip-teal" />,
              duration: 7000,
            });
            router.refresh();
          },
        )
        .subscribe();

      // 2. Subscribe to new bookings for salon owner or barber
      if (salonId) {
        const salonTopic = `salon-bookings-${salonId}`;
        const existingBooking = supabase
          .getChannels()
          .find((c) => c.topic === `realtime:${salonTopic}`);
        if (existingBooking) {
          await supabase.removeChannel(existingBooking);
        }
        if (isCancelled) return;

        bookingChannel = supabase
          .channel(salonTopic)
          .on(
            "postgres_changes",
            {
              event: "*",
              schema: "public",
              table: "bookings",
              filter: `salon_id=eq.${salonId}`,
            },
            (payload) => {
              if (payload.eventType === "INSERT") {
                toast.success("New booking received!", {
                  description: "A customer just scheduled an appointment.",
                  icon: <Scissors className="h-4 w-4 text-snip-teal" />,
                  duration: 6000,
                });
              }
              router.refresh();
            },
          )
          .subscribe();
      } else if (barberId) {
        const barberTopic = `barber-bookings-${barberId}`;
        const existingBooking = supabase
          .getChannels()
          .find((c) => c.topic === `realtime:${barberTopic}`);
        if (existingBooking) {
          await supabase.removeChannel(existingBooking);
        }
        if (isCancelled) return;

        bookingChannel = supabase
          .channel(barberTopic)
          .on(
            "postgres_changes",
            {
              event: "*",
              schema: "public",
              table: "bookings",
              filter: `barber_id=eq.${barberId}`,
            },
            (payload) => {
              if (payload.eventType === "INSERT") {
                toast.info("New appointment assigned to you!", {
                  icon: <Calendar className="h-4 w-4 text-snip-teal" />,
                  duration: 6000,
                });
              }
              router.refresh();
            },
          )
          .subscribe();
      }
    }

    setupSubscriptions();

    return () => {
      isCancelled = true;
      if (notifChannel) {
        supabase.removeChannel(notifChannel);
      }
      if (bookingChannel) {
        supabase.removeChannel(bookingChannel);
      }
    };
  }, [userId, salonId, barberId, router]);

  return null;
}
