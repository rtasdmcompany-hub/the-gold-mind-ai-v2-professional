import { brand } from "@/lib/brand";
import { productPackageLabel } from "@/lib/product";
import { queueCommercialEmail, updateCommercialEmailStatus } from "@/server/billing/email";
import type { EmailTemplate } from "@/server/billing/email";

export type MailSendResult = {
  ok: boolean;
  mode: "resend" | "outbox";
  error?: string;
  /** Resend message id when delivery was accepted */
  providerId?: string;
  outboxId?: string;
};

/**
 * Send transactional email via Resend when configured.
 * Always queues to commercial outbox for audit (status queued → sent|failed).
 * Missing API key / From address returns ok:false — callers must not claim success.
 */
export async function sendTransactionalEmail(input: {
  to: string;
  subject: string;
  html: string;
  text: string;
  template?: EmailTemplate;
}): Promise<MailSendResult> {
  const template = input.template || "support_ticket";
  let outboxId: string | undefined;
  try {
    outboxId = queueCommercialEmail({
      to: input.to,
      template,
      subject: input.subject,
      body: input.text,
      status: "queued",
    });
  } catch (e) {
    // Outbox must never block signup / reset / contact when billing durability is unavailable.
    console.warn(
      `[mailer] outbox queue skipped: ${e instanceof Error ? e.message : e} (to=${input.to})`
    );
  }

  const apiKey = (process.env.RESEND_API_KEY || "").trim();
  const from = brand.resendFrom.trim();
  if (!apiKey || !from) {
    const error = "Email delivery is not configured (RESEND_API_KEY / brand From missing).";
    console.warn(`[mailer] Outbox only — ${error} (to=${input.to} outbox=${outboxId || "none"})`);
    try {
      updateCommercialEmailStatus(outboxId, "failed", error);
    } catch {
      /* ignore */
    }
    return { ok: false, mode: "outbox", error, outboxId };
  }

  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: [input.to],
        subject: input.subject,
        html: input.html,
        text: input.text,
      }),
    });

    const bodyText = await res.text();
    let providerId: string | undefined;
    try {
      const parsed = JSON.parse(bodyText) as { id?: string; message?: string; name?: string };
      if (parsed?.id) providerId = parsed.id;
    } catch {
      /* non-JSON error body */
    }

    if (!res.ok) {
      const error = `Resend ${res.status}: ${bodyText.slice(0, 180)}`;
      console.warn(`[mailer] ${error} (to=${input.to} outbox=${outboxId || "none"})`);
      try {
        updateCommercialEmailStatus(outboxId, "failed", error);
      } catch {
        /* ignore */
      }
      return { ok: false, mode: "outbox", error, outboxId };
    }

    console.info(
      `[mailer] Resend OK id=${providerId || "unknown"} → ${input.to} · ${input.subject} (outbox=${outboxId || "none"})`
    );
    try {
      updateCommercialEmailStatus(outboxId, "sent");
    } catch {
      /* ignore */
    }
    return { ok: true, mode: "resend", providerId, outboxId };
  } catch (e) {
    const error = e instanceof Error ? e.message : "send failed";
    console.warn(`[mailer] Resend exception: ${error} (to=${input.to} outbox=${outboxId || "none"})`);
    try {
      updateCommercialEmailStatus(outboxId, "failed", error);
    } catch {
      /* ignore */
    }
    return { ok: false, mode: "outbox", error, outboxId };
  }
}

/** True when both Resend env vars are present (does not validate the key). */
export function isResendConfigured(): boolean {
  return !!(process.env.RESEND_API_KEY || "").trim() && !!brand.resendFrom.trim();
}

export function packageLabel(type: string): string {
  return productPackageLabel(type);
}
