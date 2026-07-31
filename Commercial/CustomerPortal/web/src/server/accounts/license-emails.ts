import { packageLabel, sendTransactionalEmail, type MailSendResult } from "./mailer";
import { brand } from "@/lib/brand";

/** Email plaintext license key once when a license is created. */
export async function sendLicenseCreatedEmail(input: {
  to: string;
  customerName?: string;
  packageType: string;
  plaintextKey: string;
  licenseId?: string;
}): Promise<MailSendResult> {
  const pkg = packageLabel(input.packageType);
  const name = input.customerName?.trim() || "Customer";
  const subject = `Your license key — ${pkg} · ${brand.productName}`;
  const text = [
    `Hello ${name},`,
    ``,
    `Your ${brand.productName} license is ready.`,
    ``,
    `Account: ${input.to}`,
    `Package: ${pkg}`,
    `License key: ${input.plaintextKey}`,
    input.licenseId ? `License ID: ${input.licenseId}` : "",
    ``,
    `Store this key securely. It is shown in this email once for delivery.`,
    `Activate it in the Customer Portal or during desktop installation.`,
    ``,
    `— ${brand.productName}`,
  ]
    .filter(Boolean)
    .join("\n");

  const html = `
    <p>Hello <strong>${escapeHtml(name)}</strong>,</p>
    <p>Your <strong>${brand.productName}</strong> license is ready.</p>
    <ul>
      <li><strong>Account:</strong> ${escapeHtml(input.to)}</li>
      <li><strong>Package:</strong> ${escapeHtml(pkg)}</li>
      <li><strong>License key:</strong> <code style="font-size:15px;letter-spacing:0.02em">${escapeHtml(input.plaintextKey)}</code></li>
      ${input.licenseId ? `<li><strong>License ID:</strong> ${escapeHtml(input.licenseId)}</li>` : ""}
    </ul>
    <p>Store this key securely. Activate it in the Customer Portal or during desktop installation.</p>
    <p style="color:#666;font-size:13px">— ${brand.productName}</p>
  `;

  const sent = await sendTransactionalEmail({
    to: input.to,
    subject,
    html,
    text,
    template: "license_delivery",
  });
  if (!sent.ok) {
    console.warn(`[license-emails] create delivery failed → ${input.to}: ${sent.error || "unknown"}`);
  } else {
    console.info(`[license-emails] create delivery OK id=${sent.providerId || "n/a"} → ${input.to}`);
  }
  return sent;
}

/** Confirm activation — masked key only (full key already delivered at create). */
export async function sendLicenseActivatedEmail(input: {
  to: string;
  customerName?: string;
  packageType: string;
  keyMasked: string;
  licenseId?: string;
  deviceName?: string;
}): Promise<MailSendResult> {
  const pkg = packageLabel(input.packageType);
  const name = input.customerName?.trim() || "Customer";
  const subject = `License activated — ${pkg} · ${brand.productName}`;
  const text = [
    `Hello ${name},`,
    ``,
    `Your ${brand.productName} license is now active.`,
    ``,
    `Account: ${input.to}`,
    `Package: ${pkg}`,
    `License: ${input.keyMasked}`,
    input.licenseId ? `License ID: ${input.licenseId}` : "",
    input.deviceName ? `Device: ${input.deviceName}` : "",
    ``,
    `You can manage devices and subscriptions in the Customer Portal.`,
    ``,
    `— ${brand.productName}`,
  ]
    .filter(Boolean)
    .join("\n");

  const html = `
    <p>Hello <strong>${escapeHtml(name)}</strong>,</p>
    <p>Your <strong>${brand.productName}</strong> license is now <strong>active</strong>.</p>
    <ul>
      <li><strong>Account:</strong> ${escapeHtml(input.to)}</li>
      <li><strong>Package:</strong> ${escapeHtml(pkg)}</li>
      <li><strong>License:</strong> <code>${escapeHtml(input.keyMasked)}</code></li>
      ${input.licenseId ? `<li><strong>License ID:</strong> ${escapeHtml(input.licenseId)}</li>` : ""}
      ${input.deviceName ? `<li><strong>Device:</strong> ${escapeHtml(input.deviceName)}</li>` : ""}
    </ul>
    <p>Manage devices and subscriptions in the Customer Portal.</p>
    <p style="color:#666;font-size:13px">— ${brand.productName}</p>
  `;

  const sent = await sendTransactionalEmail({
    to: input.to,
    subject,
    html,
    text,
    template: "purchase_confirmation",
  });
  if (!sent.ok) {
    console.warn(`[license-emails] activate notice failed → ${input.to}: ${sent.error || "unknown"}`);
  } else {
    console.info(`[license-emails] activate notice OK id=${sent.providerId || "n/a"} → ${input.to}`);
  }
  return sent;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
