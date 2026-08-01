import { randomInt } from "crypto";
import { brand } from "@/lib/brand";

export type BrandedMailContent = {
  subject: string;
  html: string;
  text: string;
};

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Transactional email layout — original THE GOLD MIND look.
 * Card + branded header + optional code panel + CTA button.
 * Inspired by modern verification mails; not a copy of any third-party brand.
 */
function renderBrandedEmail(input: {
  title: string;
  intro: string;
  code?: string;
  codeHint?: string;
  ctaLabel: string;
  ctaUrl: string;
  footnote: string;
}): BrandedMailContent["html"] {
  const product = escapeHtml(brand.productName);
  const brandName = escapeHtml(brand.brandName);
  const title = escapeHtml(input.title);
  const intro = escapeHtml(input.intro);
  const footnote = escapeHtml(input.footnote);
  const ctaLabel = escapeHtml(input.ctaLabel);
  const ctaUrl = escapeHtml(input.ctaUrl);
  const support = escapeHtml(brand.emails.support);
  const codeBlock = input.code
    ? `
      <tr>
        <td style="padding:8px 32px 8px;">
          <p style="margin:0 0 10px;font-family:Arial,Helvetica,sans-serif;font-size:13px;line-height:1.5;color:#6b7280;">
            ${escapeHtml(input.codeHint || "Your verification code")}
          </p>
          <div style="background:#f3f0e8;border-radius:12px;padding:18px 16px;text-align:center;">
            <span style="font-family:Consolas,'Courier New',monospace;font-size:32px;font-weight:700;letter-spacing:0.35em;color:#8a6a12;display:inline-block;padding-left:0.35em;">
              ${escapeHtml(input.code)}
            </span>
          </div>
        </td>
      </tr>`
    : "";

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title}</title>
</head>
<body style="margin:0;padding:0;background:#ececec;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#ececec;padding:28px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e5e5e5;">
          <tr>
            <td style="background:linear-gradient(105deg,#111111 0%,#2a2110 45%,#c4a035 100%);padding:22px 24px;text-align:center;">
              <p style="margin:0;font-family:Georgia,'Times New Roman',serif;font-size:18px;font-weight:700;letter-spacing:0.04em;color:#f7e7a8;">
                ${brandName}
              </p>
              <p style="margin:6px 0 0;font-family:Arial,Helvetica,sans-serif;font-size:11px;letter-spacing:0.12em;text-transform:uppercase;color:rgba(255,255,255,0.78);">
                ${product}
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:28px 32px 8px;">
              <h1 style="margin:0 0 12px;font-family:Arial,Helvetica,sans-serif;font-size:24px;line-height:1.25;color:#111111;">
                ${title}
              </h1>
              <p style="margin:0;font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:1.6;color:#4b5563;">
                ${intro}
              </p>
            </td>
          </tr>
          ${codeBlock}
          <tr>
            <td style="padding:20px 32px 8px;" align="center">
              <a href="${ctaUrl}" style="display:inline-block;background:#111111;color:#f7e7a8;font-family:Arial,Helvetica,sans-serif;font-size:15px;font-weight:700;text-decoration:none;padding:14px 28px;border-radius:10px;border:1px solid #c4a035;">
                ${ctaLabel}
              </a>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 32px 8px;">
              <p style="margin:0;font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:1.5;color:#9ca3af;word-break:break-all;">
                Or open this link:<br />
                <a href="${ctaUrl}" style="color:#8a6a12;">${ctaUrl}</a>
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 32px 28px;">
              <p style="margin:0;font-family:Arial,Helvetica,sans-serif;font-size:13px;line-height:1.55;color:#6b7280;">
                ${footnote}
              </p>
              <p style="margin:16px 0 0;font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:1.5;color:#9ca3af;">
                Need help? ${support}<br />
                ${escapeHtml(brand.copyrightProduct)}
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

export function buildEmailVerificationMail(input: {
  email: string;
  code: string;
  verifyUrl: string;
  expiresHours?: number;
}): BrandedMailContent {
  const hours = input.expiresHours ?? 24;
  const subject = `Confirm your email — ${brand.productName}`;
  const intro = `Use the code below to verify ${input.email} and activate your ${brand.productName} Customer Portal account. This code expires in ${hours} hours.`;
  const html = renderBrandedEmail({
    title: "Confirm your email",
    intro,
    code: input.code,
    codeHint: "Verification code",
    ctaLabel: "Confirm email",
    ctaUrl: input.verifyUrl,
    footnote:
      "For security, do not share this code with anyone. If you did not create this account, you can ignore this email.",
  });
  const text = [
    `${brand.productName}`,
    "",
    "Confirm your email",
    "",
    intro,
    "",
    `Verification code: ${input.code}`,
    "",
    `Confirm email: ${input.verifyUrl}`,
    "",
    "For security, do not share this code with anyone.",
    `Need help? ${brand.emails.support}`,
  ].join("\n");
  return { subject, html, text };
}

export function buildPasswordResetMail(input: {
  email: string;
  resetUrl: string;
  expiresHours?: number;
}): BrandedMailContent {
  const hours = input.expiresHours ?? 1;
  const subject = `Reset your password — ${brand.productName}`;
  const intro = `We received a password reset request for ${input.email}. Use the button below to choose a new password. This link expires in ${hours} hour${hours === 1 ? "" : "s"}.`;
  const html = renderBrandedEmail({
    title: "Reset your password",
    intro,
    ctaLabel: "Reset password",
    ctaUrl: input.resetUrl,
    footnote:
      "If you did not request a password reset, you can ignore this email. Your password will stay the same.",
  });
  const text = [
    `${brand.productName}`,
    "",
    "Reset your password",
    "",
    intro,
    "",
    `Reset password: ${input.resetUrl}`,
    "",
    `Need help? ${brand.emails.support}`,
  ].join("\n");
  return { subject, html, text };
}

/** Cryptographically fair 6-digit code (000000–999999). */
export function newVerificationCode(): string {
  return String(randomInt(0, 1_000_000)).padStart(6, "0");
}
