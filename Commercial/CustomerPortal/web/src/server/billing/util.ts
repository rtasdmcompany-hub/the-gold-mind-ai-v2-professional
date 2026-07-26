import { createHmac, timingSafeEqual, randomBytes } from "crypto";
import type { PlanCode } from "./types";

export const PLAN_CATALOG: Record<
  PlanCode,
  { label: string; amountCents: number; currency: string; interval: string }
> = {
  trial: { label: "Professional Trial", amountCents: 0, currency: "USD", interval: "14d" },
  monthly: { label: "Professional Monthly", amountCents: 9900, currency: "USD", interval: "month" },
  yearly: { label: "Professional Yearly", amountCents: 89900, currency: "USD", interval: "year" },
  lifetime: { label: "Professional Lifetime", amountCents: 249900, currency: "USD", interval: "once" },
};

export function nowIso(): string {
  return new Date().toISOString();
}

export function id(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export function hmacSha256(secret: string, payload: string): string {
  return createHmac("sha256", secret).update(payload, "utf8").digest("hex");
}

export function safeEqual(a: string, b: string): boolean {
  try {
    const ba = Buffer.from(a);
    const bb = Buffer.from(b);
    if (ba.length !== bb.length) return false;
    return timingSafeEqual(ba, bb);
  } catch {
    return false;
  }
}

export function formatMoney(cents: number, currency = "USD"): string {
  return `${currency} ${(cents / 100).toFixed(2)}`;
}

/** Website Edition only — Market never imports this module for checkout. */
export const WEBSITE_EDITION_ONLY = "THE GOLD MIND PROFESSIONAL (Website)" as const;
