import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, ServiceCategory, UserActivityType } from "@/types/database";

export interface LogActivityParams {
  activityType: UserActivityType;
  salonId?: string | null;
  serviceId?: string | null;
  category?: ServiceCategory | null;
  metadata?: Record<string, unknown>;
}

/**
 * Logs a user activity event to Supabase.
 * Gracefully ignores errors for unauthenticated users or transient network issues.
 */
export async function logUserActivity(
  supabase: SupabaseClient<any>,
  params: LogActivityParams,
): Promise<string | null> {
  try {
    const { data, error } = await supabase.rpc("log_user_activity", {
      p_activity_type: params.activityType,
      p_salon_id: params.salonId ?? null,
      p_service_id: params.serviceId ?? null,
      p_category: params.category ?? null,
      p_metadata: params.metadata ?? {},
    });

    if (error) {
      // In development or if user is unauthenticated, silence non-critical tracking errors
      return null;
    }

    return data as string | null;
  } catch {
    return null;
  }
}
