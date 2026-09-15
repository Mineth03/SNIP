import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import type { UserRole } from "@/types/database";
import {
  canAccessPathWithCapabilities,
  getActiveRoleHome,
  type AppCapability,
} from "@/lib/auth/roles";

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => {
            request.cookies.set(name, value);
          });
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) => {
            supabaseResponse.cookies.set(name, value, options);
          });
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const pathname = request.nextUrl.pathname;
  const isAuthRoute =
    pathname.startsWith("/login") ||
    pathname.startsWith("/register") ||
    pathname.startsWith("/forgot-password") ||
    pathname.startsWith("/reset-password");

  const isProtected =
    pathname.startsWith("/customer") ||
    pathname.startsWith("/owner") ||
    pathname.startsWith("/barber") ||
    pathname.startsWith("/admin");

  if (!user && isProtected) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }

  if (user) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("role, active_role")
      .eq("id", user.id)
      .maybeSingle();

    const activeRole = ((profile as { active_role?: UserRole; role?: UserRole } | null)
      ?.active_role ??
      (profile as { role?: UserRole } | null)?.role ??
      "customer") as UserRole;

    let capabilities: AppCapability[] = ["customer"];
    const { data: caps } = await supabase.rpc("user_capabilities", {
      p_uid: user.id,
    });
    if (Array.isArray(caps)) {
      capabilities = caps as AppCapability[];
    } else {
      // Fallback before migration is applied
      if (activeRole === "admin" || (profile as { role?: string } | null)?.role === "admin") {
        capabilities = ["customer", "salon_owner", "barber", "admin"];
      } else if (activeRole === "salon_owner" || (profile as { role?: string } | null)?.role === "salon_owner") {
        capabilities = ["customer", "salon_owner"];
      } else if (activeRole === "barber" || (profile as { role?: string } | null)?.role === "barber") {
        capabilities = ["customer", "barber"];
      }
    }

    if (isAuthRoute) {
      const url = request.nextUrl.clone();
      url.pathname = getActiveRoleHome(
        capabilities.includes(activeRole as AppCapability) ? activeRole : "customer",
      );
      url.search = "";
      return NextResponse.redirect(url);
    }

    if (!canAccessPathWithCapabilities(pathname, capabilities)) {
      const url = request.nextUrl.clone();
      url.pathname = getActiveRoleHome(
        capabilities.includes(activeRole as AppCapability) ? activeRole : "customer",
      );
      url.search = "";
      return NextResponse.redirect(url);
    }
  }

  return supabaseResponse;
}
