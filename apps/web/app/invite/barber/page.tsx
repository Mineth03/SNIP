"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";

function InviteAcceptInner() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const token = searchParams.get("token") ?? "";
  const [status, setStatus] = useState<"loading" | "ready" | "done" | "error">(
    "loading",
  );
  const [message, setMessage] = useState("");
  const [authed, setAuthed] = useState(false);

  useEffect(() => {
    async function check() {
      if (!token) {
        setStatus("error");
        setMessage("Missing invitation token.");
        return;
      }
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      setAuthed(Boolean(user));
      setStatus("ready");
    }
    void check();
  }, [token]);

  async function accept() {
    const supabase = createClient();
    const { error } = await supabase.rpc("accept_barber_invite", {
      p_token: token,
    });
    if (error) {
      setStatus("error");
      setMessage(error.message);
      toast.error(error.message);
      return;
    }
    setStatus("done");
    toast.success("You’re on the salon team!");
    router.push("/barber");
    router.refresh();
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-snip-bg px-4">
      <Card className="w-full max-w-md rounded-2xl shadow-snip-sm">
        <CardHeader>
          <CardTitle>Salon team invitation</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4 text-sm text-snip-muted">
          {status === "loading" ? <p>Checking invitation...</p> : null}
          {status === "error" ? (
            <>
              <p className="text-snip-danger">{message}</p>
              <Link href="/customer">
                <Button variant="outline" className="w-full">
                  Go to customer home
                </Button>
              </Link>
            </>
          ) : null}
          {status === "ready" && !authed ? (
            <>
              <p>
                Sign in or create a free SNIP customer account with the invited
                email, then return here to join the salon team.
              </p>
              <div className="grid gap-2">
                <Link href={`/login?next=${encodeURIComponent(`/invite/barber?token=${token}`)}`}>
                  <Button className="w-full">Sign in</Button>
                </Link>
                <Link
                  href={`/register?invite=${encodeURIComponent(token)}`}
                >
                  <Button variant="outline" className="w-full">
                    Create account
                  </Button>
                </Link>
              </div>
            </>
          ) : null}
          {status === "ready" && authed ? (
            <>
              <p>
                Accept this invitation to join the salon as a barber. You can keep
                booking as a customer and switch views from your profile.
              </p>
              <Button className="w-full" onClick={accept}>
                Accept invitation
              </Button>
            </>
          ) : null}
          {status === "done" ? <p>Invitation accepted. Redirecting...</p> : null}
        </CardContent>
      </Card>
    </div>
  );
}

export default function InviteBarberPage() {
  return (
    <Suspense fallback={<p className="p-8 text-center text-sm">Loading...</p>}>
      <InviteAcceptInner />
    </Suspense>
  );
}
