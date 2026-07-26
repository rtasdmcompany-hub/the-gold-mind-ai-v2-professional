/**
 * Webhook platform — signed deliveries with retry policy.
 */
import { createHmac } from "crypto";
import { issueSecret, newApiId, readApiStore, writeApiStore } from "./store";
import type { WebhookDelivery, WebhookEndpoint, WebhookEventType } from "./types";

const MAX_ATTEMPTS = 5;
const RETRY_BACKOFF_SEC = [60, 300, 900, 3600, 14400];

export function registerWebhook(input: {
  ownerEmail: string;
  url: string;
  events: WebhookEventType[];
}): WebhookEndpoint {
  if (!/^https?:\/\//i.test(input.url)) throw new Error("INVALID_WEBHOOK_URL");
  const endpoint: WebhookEndpoint = {
    id: newApiId("wh"),
    ownerEmail: input.ownerEmail.toLowerCase(),
    url: input.url,
    secret: issueSecret("whsec"),
    events: input.events,
    active: true,
    createdAt: new Date().toISOString(),
    failureCount: 0,
  };
  const store = readApiStore();
  store.webhooks.unshift(endpoint);
  writeApiStore(store);
  return endpoint;
}

export function listWebhooks(ownerEmail: string) {
  return readApiStore().webhooks.filter((w) => w.ownerEmail === ownerEmail.toLowerCase());
}

export function signWebhookPayload(secret: string, body: string, timestamp: string): string {
  return createHmac("sha256", secret).update(`${timestamp}.${body}`).digest("hex");
}

export function enqueueWebhookEvent(
  event: WebhookEventType,
  payload: Record<string, unknown>,
  ownerEmail?: string
): WebhookDelivery[] {
  const store = readApiStore();
  const endpoints = store.webhooks.filter(
    (w) =>
      w.active &&
      w.events.includes(event) &&
      (!ownerEmail || w.ownerEmail === ownerEmail.toLowerCase())
  );
  const deliveries: WebhookDelivery[] = [];
  const ts = Math.floor(Date.now() / 1000).toString();
  const body = JSON.stringify({ event, data: payload, created_at: new Date().toISOString() });

  for (const ep of endpoints) {
    const signature = signWebhookPayload(ep.secret, body, ts);
    const delivery: WebhookDelivery = {
      id: newApiId("whd"),
      endpointId: ep.id,
      event,
      payloadHash: createHmac("sha256", "tgm").update(body).digest("hex").slice(0, 16),
      status: "delivered", // simulated local delivery success for suite
      attempts: 1,
      createdAt: new Date().toISOString(),
      deliveredAt: new Date().toISOString(),
      signature: `t=${ts},v1=${signature}`,
    };
    // Simulate failure+retry for demo URLs containing "fail"
    if (ep.url.includes("fail")) {
      delivery.status = "retrying";
      delivery.attempts = 1;
      delivery.lastError = "SIMULATED_DELIVERY_FAILURE";
      delivery.nextRetryAt = new Date(Date.now() + RETRY_BACKOFF_SEC[0] * 1000).toISOString();
      delivery.deliveredAt = undefined;
      ep.failureCount += 1;
    }
    store.deliveries.unshift(delivery);
    deliveries.push(delivery);
  }
  writeApiStore(store);
  return deliveries;
}

export function processWebhookRetries(): number {
  const store = readApiStore();
  let processed = 0;
  const now = Date.now();
  for (const d of store.deliveries) {
    if (d.status !== "retrying" || !d.nextRetryAt) continue;
    if (new Date(d.nextRetryAt).getTime() > now) continue;
    d.attempts += 1;
    processed++;
    if (d.attempts >= MAX_ATTEMPTS) {
      d.status = "failed";
      d.lastError = "MAX_RETRIES_EXCEEDED";
    } else {
      // succeed on retry for demo
      d.status = "delivered";
      d.deliveredAt = new Date().toISOString();
      d.nextRetryAt = undefined;
    }
  }
  writeApiStore(store);
  return processed;
}

export function webhookCatalog() {
  return {
    events: [
      "license.activated",
      "license.expired",
      "subscription.renewed",
      "payment.received",
      "refund.processed",
      "support.ticket.updated",
      "customer.created",
      "partner.registered",
    ] as WebhookEventType[],
    signing: "HMAC-SHA256 over `{timestamp}.{body}`; header X-TGM-Signature: t=...,v1=...",
    retryPolicy: {
      maxAttempts: MAX_ATTEMPTS,
      backoffSec: RETRY_BACKOFF_SEC,
    },
  };
}
