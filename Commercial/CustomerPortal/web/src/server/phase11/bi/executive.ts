/**
 * Task 1 — Executive Business Dashboard (ACTUAL metrics only).
 */
import { PLAN_CATALOG } from "@/server/billing/util";
import { savePhase11Run } from "../store";
import { safeEnsureCommercialData } from "../safe";
import { formatUsd, loadBiLedger, monthKey, subscriptionMrrCents } from "./helpers";

export async function buildExecutiveBusinessDashboard() {
  safeEnsureCommercialData();
  const { payments, subscriptions, licenses } = loadBiLedger();
  const now = new Date();
  const thisMonth = now.toISOString().slice(0, 7);
  const thisYear = now.toISOString().slice(0, 4);

  const emails = new Set(licenses.map((l) => l.customerEmail.toLowerCase()));
  for (const s of subscriptions) emails.add(s.customerEmail.toLowerCase());
  for (const p of payments) emails.add(p.customerEmail.toLowerCase());

  const activeEmails = new Set(
    licenses
      .filter((l) => l.status === "active" || l.status === "grace")
      .map((l) => l.customerEmail.toLowerCase())
  );
  const trialEmails = new Set(
    licenses.filter((l) => l.type === "trial").map((l) => l.customerEmail.toLowerCase())
  );
  const paidEmails = new Set(
    licenses
      .filter((l) => l.type !== "trial" && (l.status === "active" || l.status === "grace"))
      .map((l) => l.customerEmail.toLowerCase())
  );
  for (const s of subscriptions) {
    if ((s.status === "active" || s.status === "trialing") && s.plan !== "trial") {
      paidEmails.add(s.customerEmail.toLowerCase());
    }
  }

  const allSucceeded = payments.filter((p) => p.status === "succeeded");
  const monthlyRevenueCents = allSucceeded
    .filter((p) => monthKey(p.createdAt) === thisMonth)
    .reduce((a, p) => a + p.amountCents, 0);
  const annualRevenueCents = allSucceeded
    .filter((p) => p.createdAt.startsWith(thisYear))
    .reduce((a, p) => a + p.amountCents, 0);

  const mrrCents = subscriptions.reduce((a, s) => a + subscriptionMrrCents(s), 0);
  const arrCents = mrrCents * 12;
  const paidCount = Math.max(paidEmails.size, 1);
  const arpuCents = Math.round(mrrCents / paidCount);

  const byCustomer = new Map<string, number>();
  for (const p of allSucceeded) {
    const e = p.customerEmail.toLowerCase();
    byCustomer.set(e, (byCustomer.get(e) || 0) + p.amountCents);
  }
  const observedValues = [...byCustomer.values()];
  const clvObservedCents =
    observedValues.length === 0
      ? 0
      : Math.round(observedValues.reduce((a, b) => a + b, 0) / observedValues.length);

  const payload = {
    kind: "ACTUAL" as const,
    totalCustomers: emails.size,
    activeCustomers: activeEmails.size,
    trialCustomers: trialEmails.size,
    paidCustomers: paidEmails.size,
    monthlyRevenue: {
      cents: monthlyRevenueCents,
      formatted: formatUsd(monthlyRevenueCents),
      period: thisMonth,
    },
    annualRevenue: {
      cents: annualRevenueCents,
      formatted: formatUsd(annualRevenueCents),
      period: thisYear,
    },
    mrr: {
      cents: mrrCents,
      formatted: formatUsd(mrrCents),
      definition: "Sum of ACTUAL catalog MRR for active/trialing monthly+yearly subscriptions",
    },
    arr: {
      cents: arrCents,
      formatted: formatUsd(arrCents),
      definition: "MRR × 12 (derived from ACTUAL MRR)",
    },
    arpu: {
      cents: arpuCents,
      formatted: formatUsd(arpuCents),
      definition: "MRR / max(paidCustomers,1) — ACTUAL",
    },
    clv: {
      cents: clvObservedCents,
      formatted: formatUsd(clvObservedCents),
      definition:
        "Observed historical average of succeeded payments per paying customer (NOT a projected LTV)",
      label: "Observed historical value",
    },
    catalogReference: {
      monthly: PLAN_CATALOG.monthly.amountCents,
      yearly: PLAN_CATALOG.yearly.amountCents,
    },
    dataTrace: "billing.enc payments/subscriptions + licensing store licenses",
    coreIsolation: "BI never reads Core Trading Engine",
    at: new Date().toISOString(),
  };
  savePhase11Run("bi_executive", "Executive business dashboard", payload);
  return payload;
}
