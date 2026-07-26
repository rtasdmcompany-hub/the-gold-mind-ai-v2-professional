/**
 * Shared BI helpers — ACTUAL vs FORECAST discipline.
 * Never invents revenue/country; unattributed when data absent.
 */
import { PLAN_CATALOG } from "@/server/billing/util";
import type {
  BillingStoreData,
  BillingSubscriptionRecord,
  PaymentRecord,
  PlanCode,
} from "@/server/billing/types";
import { readBillingStore } from "@/server/billing/store";
import { safeListLicenses } from "../safe";

export type MetricKind = "ACTUAL" | "FORECAST" | "UNATTRIBUTED";

export function formatUsd(cents: number): string {
  return `USD ${(Math.max(0, cents) / 100).toFixed(2)}`;
}

export function monthKey(iso: string): string {
  return iso.slice(0, 7);
}

export function safeReadBillingStore(): BillingStoreData {
  try {
    return readBillingStore();
  } catch {
    return {
      version: 1,
      edition: "Professional_Website",
      invoices: [],
      payments: [],
      subscriptions: [],
      processedWebhooks: [],
      webhookAudits: [],
      emails: [],
    };
  }
}

export function loadBiLedger() {
  const store = safeReadBillingStore();
  const licenses = safeListLicenses();
  return {
    payments: store.payments || [],
    subscriptions: store.subscriptions || [],
    invoices: store.invoices || [],
    licenses,
    store,
  };
}

/** Recurring monthly cents contribution from an active/trialing subscription (ACTUAL catalog prices). */
export function subscriptionMrrCents(sub: BillingSubscriptionRecord): number {
  if (sub.status !== "active" && sub.status !== "trialing") return 0;
  if (sub.plan === "trial" || sub.plan === "lifetime") return 0;
  const plan = PLAN_CATALOG[sub.plan as PlanCode];
  if (!plan) return 0;
  if (sub.plan === "yearly") return Math.round(plan.amountCents / 12);
  return plan.amountCents;
}

export function sumSucceededByPlan(payments: PaymentRecord[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const p of payments) {
    if (p.status !== "succeeded") continue;
    const key = p.plan || "unspecified";
    out[key] = (out[key] || 0) + p.amountCents;
  }
  return out;
}

export function sumSucceededByProvider(payments: PaymentRecord[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const p of payments) {
    if (p.status !== "succeeded") continue;
    out[p.provider] = (out[p.provider] || 0) + p.amountCents;
  }
  return out;
}

/**
 * Country: only when payment note embeds country=XX; otherwise UNATTRIBUTED.
 * Never invents geo.
 */
export function sumSucceededByCountry(payments: PaymentRecord[]): {
  byCountry: Record<string, number>;
  kind: MetricKind;
  note: string;
} {
  const byCountry: Record<string, number> = {};
  let attributed = 0;
  for (const p of payments) {
    if (p.status !== "succeeded") continue;
    const m = /country=([A-Z]{2})/i.exec(p.note || "");
    if (m) {
      const c = m[1].toUpperCase();
      byCountry[c] = (byCountry[c] || 0) + p.amountCents;
      attributed += 1;
    } else {
      byCountry["UNATTRIBUTED"] = (byCountry["UNATTRIBUTED"] || 0) + p.amountCents;
    }
  }
  return {
    byCountry,
    kind: attributed > 0 ? "ACTUAL" : "UNATTRIBUTED",
    note:
      attributed > 0
        ? `${attributed} payments carried country=XX in note`
        : "No country tags on payments — shown as UNATTRIBUTED (not estimated)",
  };
}

export function monthlyRevenueTrend(payments: PaymentRecord[]): {
  month: string;
  cents: number;
  formatted: string;
  kind: "ACTUAL";
}[] {
  const map = new Map<string, number>();
  for (const p of payments) {
    if (p.status !== "succeeded") continue;
    const m = monthKey(p.createdAt);
    map.set(m, (map.get(m) || 0) + p.amountCents);
  }
  return [...map.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([month, cents]) => ({ month, cents, formatted: formatUsd(cents), kind: "ACTUAL" as const }));
}

export function linearForecast(
  series: number[],
  periods: number
): { values: number[]; confidence: "low" | "medium" | "high"; method: string; assumptions: string[] } {
  if (series.length < 2) {
    const last = series[0] || 0;
    return {
      values: Array.from({ length: periods }, () => last),
      confidence: "low",
      method: "flat-hold (insufficient history)",
      assumptions: [
        "Fewer than 2 historical points — forecast holds last known value",
        "NOT ACTUAL revenue or customers",
      ],
    };
  }
  const n = series.length;
  let sumX = 0;
  let sumY = 0;
  let sumXY = 0;
  let sumXX = 0;
  for (let i = 0; i < n; i++) {
    sumX += i;
    sumY += series[i];
    sumXY += i * series[i];
    sumXX += i * i;
  }
  const denom = n * sumXX - sumX * sumX || 1;
  const slope = (n * sumXY - sumX * sumY) / denom;
  const intercept = (sumY - slope * sumX) / n;
  const values = Array.from({ length: periods }, (_, k) =>
    Math.max(0, Math.round(intercept + slope * (n + k)))
  );
  const confidence: "low" | "medium" | "high" = n >= 12 ? "high" : n >= 6 ? "medium" : "low";
  return {
    values,
    confidence,
    method: "ordinary-least-squares linear trend",
    assumptions: [
      "Linear continuity of recent ACTUAL series",
      "No seasonality / campaign shocks modeled",
      "FORECAST only — must not be labeled as ACTUAL",
      `History length n=${n}`,
    ],
  };
}
