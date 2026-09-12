const brand = {
  primary: "#14B8A6",
  teal: "#1488A6",
  charcoal: "#0F172A",
  muted: "#64748B",
  border: "#E5E7EB",
  bg: "#F8FAFC",
};

function shell(title: string, body: string) {
  return `<!DOCTYPE html>
<html>
<head><meta charset="utf-8" /><title>${title}</title></head>
<body style="margin:0;padding:0;background:${brand.bg};font-family:Inter,Arial,sans-serif;color:${brand.charcoal};">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:32px 16px;">
    <tr><td align="center">
      <table role="presentation" width="560" cellspacing="0" cellpadding="0" style="background:#fff;border:1px solid ${brand.border};border-radius:16px;overflow:hidden;">
        <tr><td style="background:linear-gradient(135deg,${brand.teal},${brand.primary});padding:24px 28px;">
          <div style="font-size:22px;font-weight:700;color:#fff;letter-spacing:-0.02em;">SNIP</div>
          <div style="font-size:13px;color:rgba(255,255,255,0.85);margin-top:4px;">Smart Salon Booking</div>
        </td></tr>
        <tr><td style="padding:28px;">${body}</td></tr>
        <tr><td style="padding:16px 28px 28px;font-size:12px;color:${brand.muted};border-top:1px solid ${brand.border};">
          You’re receiving this because of activity on SNIP.
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

export function welcomeHtml(data: Record<string, string>) {
  return shell(
    "Welcome to SNIP",
    `<h1 style="margin:0 0 12px;font-size:22px;">Welcome, ${data.name ?? "there"}</h1>
     <p style="margin:0 0 16px;color:${brand.muted};line-height:1.6;">Your SNIP account is ready. Discover salons, book in minutes, and manage your beauty appointments in one place.</p>
     <a href="${data.ctaUrl ?? "#"}" style="display:inline-block;background:${brand.primary};color:#fff;text-decoration:none;padding:12px 18px;border-radius:10px;font-weight:600;">Get started</a>`,
  );
}

export function bookingConfirmationHtml(data: Record<string, string>) {
  return shell(
    "Booking confirmed",
    `<h1 style="margin:0 0 12px;font-size:22px;">Booking confirmed</h1>
     <p style="margin:0 0 16px;color:${brand.muted};line-height:1.6;">
       Your appointment at <strong>${data.salonName ?? "the salon"}</strong> for
       <strong>${data.serviceName ?? "your service"}</strong> is confirmed for
       <strong>${data.when ?? ""}</strong>.
     </p>
     <p style="margin:0;color:${brand.muted};">Show your QR check-in ticket when you arrive.</p>`,
  );
}

export function bookingCancelledHtml(data: Record<string, string>) {
  return shell(
    "Booking cancelled",
    `<h1 style="margin:0 0 12px;font-size:22px;">Booking cancelled</h1>
     <p style="margin:0 0 16px;color:${brand.muted};line-height:1.6;">
       Your appointment at <strong>${data.salonName ?? "the salon"}</strong>
       on <strong>${data.when ?? ""}</strong> has been cancelled.
     </p>
     <p style="margin:0;color:${brand.muted};">${data.reason ? `Reason: ${data.reason}` : "You can book again anytime."}</p>`,
  );
}

export function salonApprovedHtml(data: Record<string, string>) {
  return shell(
    "Salon approved",
    `<h1 style="margin:0 0 12px;font-size:22px;">You’re live on SNIP</h1>
     <p style="margin:0 0 16px;color:${brand.muted};line-height:1.6;">
       <strong>${data.salonName ?? "Your salon"}</strong> has been verified and is now discoverable to customers.
     </p>
     <a href="${data.ctaUrl ?? "#"}" style="display:inline-block;background:${brand.primary};color:#fff;text-decoration:none;padding:12px 18px;border-radius:10px;font-weight:600;">Open dashboard</a>`,
  );
}

export function salonRejectedHtml(data: Record<string, string>) {
  return shell(
    "Salon verification",
    `<h1 style="margin:0 0 12px;font-size:22px;">Verification update</h1>
     <p style="margin:0 0 16px;color:${brand.muted};line-height:1.6;">
       We couldn’t verify <strong>${data.salonName ?? "your salon"}</strong> yet.
     </p>
     <p style="margin:0;color:${brand.muted};">${data.reason ?? "Please update your salon details and resubmit."}</p>`,
  );
}

export function staffInviteHtml(data: Record<string, string>) {
  return shell(
    "Staff invitation",
    `<h1 style="margin:0 0 12px;font-size:22px;">You’re invited</h1>
     <p style="margin:0 0 16px;color:${brand.muted};line-height:1.6;">
       Join <strong>${data.salonName ?? "a salon"}</strong> on SNIP as staff.
     </p>
     <a href="${data.ctaUrl ?? "#"}" style="display:inline-block;background:${brand.primary};color:#fff;text-decoration:none;padding:12px 18px;border-radius:10px;font-weight:600;">Accept invite</a>`,
  );
}
