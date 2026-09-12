import { Resend } from "resend";
import {
  bookingCancelledHtml,
  bookingConfirmationHtml,
  salonApprovedHtml,
  salonRejectedHtml,
  staffInviteHtml,
  welcomeHtml,
} from "@/lib/email/templates";

function getResend() {
  const key = process.env.RESEND_API_KEY;
  if (!key) return null;
  return new Resend(key);
}

const from = process.env.RESEND_FROM_EMAIL ?? "SNIP <onboarding@resend.dev>";

export type EmailTemplate =
  | "welcome"
  | "booking_confirmation"
  | "booking_cancelled"
  | "salon_approved"
  | "salon_rejected"
  | "staff_invite";

export type EmailPayload = {
  to: string;
  template: EmailTemplate;
  data: Record<string, string>;
};

export async function sendTemplatedEmail({ to, template, data }: EmailPayload) {
  const resend = getResend();
  if (!resend) {
    console.warn("[email] RESEND_API_KEY missing — skipping send", {
      to,
      template,
    });
    return { skipped: true as const };
  }

  const content = renderTemplate(template, data);

  const result = await resend.emails.send({
    from,
    to,
    subject: content.subject,
    html: content.html,
  });

  if (result.error) {
    throw new Error(result.error.message);
  }

  return { skipped: false as const, id: result.data?.id };
}

function renderTemplate(template: EmailTemplate, data: Record<string, string>) {
  switch (template) {
    case "welcome":
      return {
        subject: `Welcome to SNIP, ${data.name ?? "there"}`,
        html: welcomeHtml(data),
      };
    case "booking_confirmation":
      return {
        subject: "Your SNIP booking is confirmed",
        html: bookingConfirmationHtml(data),
      };
    case "booking_cancelled":
      return {
        subject: "Your SNIP booking was cancelled",
        html: bookingCancelledHtml(data),
      };
    case "salon_approved":
      return {
        subject: "Your salon is verified on SNIP",
        html: salonApprovedHtml(data),
      };
    case "salon_rejected":
      return {
        subject: "Salon verification update",
        html: salonRejectedHtml(data),
      };
    case "staff_invite":
      return {
        subject: `You're invited to join ${data.salonName ?? "a salon"} on SNIP`,
        html: staffInviteHtml(data),
      };
    default:
      throw new Error(`Unknown email template: ${template}`);
  }
}
