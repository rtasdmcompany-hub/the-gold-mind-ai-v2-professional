import { NextResponse } from "next/server";
import { getWebhookPort } from "@/server/billing/payment-port";
import { processNormalizedEvent } from "@/server/billing/webhook-processor";
import { mutateBilling } from "@/server/billing/store";
import { id, nowIso } from "@/server/billing/util";
import type { WebhookAuditEntry } from "@/server/billing/types";

/**
 * POST /api/billing/webhooks/[provider]
 * Website Edition only. Authenticated · logged · idempotent · retry-safe.
 * Public route (no portal session) — verified via PaymentPort signature.
 * Never touches Core Trading Engine. Never used by MQL5 Market Edition.
 */
export async function POST(
  req: Request,
  ctx: { params: Promise<{ provider: string }> }
) {
  const { provider } = await ctx.params;
  const port = getWebhookPort(provider);
  if (!port) {
    auditWebhook({
      provider,
      authenticated: false,
      detail: "UNKNOWN_PROVIDER",
      httpStatus: 404,
    });
    return NextResponse.json({ error: "UNKNOWN_PROVIDER" }, { status: 404 });
  }

  const rawBody = await req.text();
  const event = await port.verifyWebhook(req.headers, rawBody);
  if (!event) {
    auditWebhook({
      provider,
      authenticated: false,
      detail: "WEBHOOK_AUTH_FAILED",
      httpStatus: 401,
    });
    console.warn("[webhook] auth failed", provider);
    return NextResponse.json({ error: "WEBHOOK_AUTH_FAILED" }, { status: 401 });
  }

  try {
    const result = await processNormalizedEvent(event);
    auditWebhook({
      provider,
      authenticated: true,
      duplicate: result.duplicate || false,
      eventType: event.type,
      providerEventId: event.providerEventId,
      detail: result.detail,
      httpStatus: 200,
    });
    console.info(
      "[webhook]",
      provider,
      event.type,
      result.duplicate ? "duplicate" : "applied",
      event.providerEventId
    );
    return NextResponse.json({
      ok: result.ok,
      duplicate: result.duplicate || false,
      detail: result.detail,
      // Never echo plaintext license key on webhook response
      licenseId: result.licenseId,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "PROCESS_FAIL";
    auditWebhook({
      provider,
      authenticated: true,
      eventType: event.type,
      providerEventId: event.providerEventId,
      detail: msg,
      httpStatus: 500,
    });
    console.error("[webhook]", provider, msg);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

function auditWebhook(entry: Omit<WebhookAuditEntry, "id" | "at">): void {
  try {
    mutateBilling((data) => {
      data.webhookAudits.unshift({
        id: id("wha"),
        at: nowIso(),
        ...entry,
      });
    });
  } catch (err) {
    console.error("[webhook-audit]", err);
  }
}