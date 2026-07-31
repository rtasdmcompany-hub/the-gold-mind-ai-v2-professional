import { NextResponse } from "next/server";
import { writeAudit } from "@/server/cloud/audit";
import { applySecurityHeaders } from "@/server/cloud/security-headers";
import { sendTransactionalEmail } from "@/server/accounts/mailer";

/** POST /api/contact — public commercial inquiry intake (no Core involvement). */
export async function POST(req: Request) {
  const form = await req.formData();
  const name = String(form.get("name") || "").slice(0, 120);
  const email = String(form.get("email") || "").slice(0, 180).toLowerCase();
  const message = String(form.get("message") || "").slice(0, 4000);
  if (!name || !email || !message) {
    return applySecurityHeaders(
      NextResponse.json({ ok: false, error: "MISSING_FIELDS" }, { status: 400 })
    );
  }

  const supportInbox = (
    process.env.SUPPORT_INBOX_EMAIL ||
    process.env.RESEND_FROM_EMAIL ||
    ""
  ).trim();

  let emailSent = false;
  if (supportInbox) {
    const subject = `Commercial inquiry — ${name}`;
    const text = `From: ${name} <${email}>\n\n${message}`;
    const html = `<p>From: <strong>${name}</strong> &lt;${email}&gt;</p><p>${message.replace(/\n/g, "<br/>")}</p>`;
    const sent = await sendTransactionalEmail({ to: supportInbox, subject, html, text });
    emailSent = sent.ok;
  }

  writeAudit({
    user: email,
    action: "support_action",
    ip: req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "public",
    result: "success",
    detail: `contact form · ${name} · emailSent=${emailSent} · ${message.slice(0, 80)}`,
  });
  return applySecurityHeaders(NextResponse.redirect(new URL("/contact?sent=1", req.url), 303));
}
