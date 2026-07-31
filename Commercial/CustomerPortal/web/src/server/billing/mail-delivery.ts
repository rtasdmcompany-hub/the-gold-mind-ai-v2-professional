/**
 * Billing lifecycle email delivery — uses Resend when configured.
 * Does not change webhook APIs; fire-and-forget from sync processors.
 * Never touches Trading Engine.
 */
import { sendTransactionalEmail } from "@/server/accounts/mailer";
import { commercialEmailSubject, type EmailTemplate } from "./email";

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** Queue + attempt Resend delivery. Safe to call without awaiting. */
export function deliverBillingEmail(input: {
  to: string;
  template: EmailTemplate;
  body: string;
  subject?: string;
}): void {
  const subject = input.subject || commercialEmailSubject(input.template);
  const text = input.body;
  const html = `<div style="font-family:Segoe UI,Arial,sans-serif;line-height:1.5;color:#111">
    <p style="white-space:pre-wrap">${escapeHtml(text)}</p>
    <p style="color:#666;font-size:12px;margin-top:24px">THE GOLD MIND PROFESSIONAL · RTAS Group of Companies</p>
  </div>`;

  void sendTransactionalEmail({
    to: input.to,
    subject,
    html,
    text,
    template: input.template,
  }).catch((err) => {
    console.warn(`[billing-mail] delivery error → ${input.to}:`, err);
  });
}
