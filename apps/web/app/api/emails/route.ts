import { NextResponse } from "next/server";
import { z } from "zod";
import {
  sendTemplatedEmail,
  type EmailTemplate,
} from "@/lib/email/resend";

const schema = z.object({
  to: z.email(),
  template: z.enum([
    "welcome",
    "booking_confirmation",
    "booking_cancelled",
    "salon_approved",
    "salon_rejected",
    "staff_invite",
  ]),
  data: z.record(z.string(), z.string()).default({}),
});

export async function POST(request: Request) {
  try {
    const body = schema.parse(await request.json());
    const result = await sendTemplatedEmail({
      to: body.to,
      template: body.template as EmailTemplate,
      data: body.data,
    });
    return NextResponse.json({ ok: true, ...result });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to send email";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
