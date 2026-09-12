// Supabase Edge Function: send-email via Resend
// Secrets: RESEND_API_KEY, RESEND_FROM_EMAIL
// Deploy: supabase functions deploy send-email

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type EmailPayload = {
  to: string;
  subject: string;
  html: string;
  template?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("RESEND_API_KEY");
    const from = Deno.env.get("RESEND_FROM_EMAIL") ?? "SNIP <onboarding@resend.dev>";

    if (!apiKey) {
      return new Response(JSON.stringify({ error: "RESEND_API_KEY not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = (await req.json()) as EmailPayload;
    if (!body.to || !body.subject || !body.html) {
      return new Response(JSON.stringify({ error: "to, subject, and html are required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: [body.to],
        subject: body.subject,
        html: wrapSnipEmail(body.html),
      }),
    });

    const data = await res.json();
    if (!res.ok) {
      return new Response(JSON.stringify({ error: data }), {
        status: res.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

function wrapSnipEmail(content: string): string {
  return `<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;background:#F3F4F6;font-family:Inter,Arial,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background:#F3F4F6;padding:32px 16px;">
      <tr>
        <td align="center">
          <table width="560" cellpadding="0" cellspacing="0" style="background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.05);">
            <tr>
              <td style="background:#0F172A;padding:24px 32px;">
                <div style="color:#FFFFFF;font-size:24px;font-weight:700;letter-spacing:0.04em;">SNIP</div>
                <div style="color:#1488A6;font-size:12px;margin-top:4px;letter-spacing:0.08em;">BOOK • MANAGE • GROW</div>
              </td>
            </tr>
            <tr>
              <td style="padding:32px;color:#0F172A;font-size:15px;line-height:1.6;">
                ${content}
              </td>
            </tr>
            <tr>
              <td style="padding:16px 32px 28px;color:#64748B;font-size:12px;border-top:1px solid #E5E7EB;">
                You’re receiving this email from SNIP. Please do not reply with sensitive information.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}
