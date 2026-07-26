/**
 * Task 7 — Forecasting (FORECAST only — never presented as ACTUAL).
 */
import { savePhase11Run } from "../store";
import { safeEnsureCommercialData, safeSupportTickets, safeUsageAnalytics } from "../safe";
import {
  formatUsd,
  linearForecast,
  loadBiLedger,
  monthlyRevenueTrend,
  subscriptionMrrCents,
} from "./helpers";

export async function buildForecastingModel() {
  safeEnsureCommercialData();
  const { payments, subscriptions, licenses } = loadBiLedger();
  const usage = safeUsageAnalytics();
  const tickets = safeSupportTickets();

  const revenueTrend = monthlyRevenueTrend(payments);
  const revenueSeries = revenueTrend.map((r) => r.cents);
  const revFc = linearForecast(revenueSeries, 3);

  const monthKeys = [...new Set(subscriptions.map((s) => s.createdAt.slice(0, 7)))].sort();
  const subSeries = monthKeys.map(
    (m) => subscriptions.filter((s) => s.createdAt.startsWith(m)).length
  );
  const subFc = linearForecast(subSeries.length ? subSeries : [subscriptions.length], 3);

  const licenseMonths = [
    ...new Set(licenses.map((l) => (l.createdAt || "").slice(0, 7)).filter(Boolean)),
  ].sort();
  const growthSeries = licenseMonths.map(
    (m) => licenses.filter((l) => (l.createdAt || "").startsWith(m)).length
  );
  const growthFc = linearForecast(growthSeries.length ? growthSeries : [licenses.length], 3);

  const renewalsByMonth = new Map<string, number>();
  for (const p of payments) {
    if (p.note === "renewal" && p.status === "succeeded") {
      const m = p.createdAt.slice(0, 7);
      renewalsByMonth.set(m, (renewalsByMonth.get(m) || 0) + 1);
    }
  }
  const renewSeries = [...renewalsByMonth.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([, n]) => n);
  const renewFc = linearForecast(renewSeries.length ? renewSeries : [0], 3);

  const mrr = subscriptions.reduce((a, s) => a + subscriptionMrrCents(s), 0);
  // Infrastructure capacity: FORECAST heuristic from MAU growth — clearly labeled
  const mau = usage.monthlyActiveUsers || 0;
  const capFc = linearForecast([Math.max(mau, 1), Math.max(mau, 1) * 1.05], 3);

  const open = tickets.filter((t) => t.status === "open" || t.status === "pending").length;
  const supportFc = linearForecast([open, open], 3);

  const horizon = [1, 2, 3].map((i) => {
    const d = new Date();
    d.setUTCMonth(d.getUTCMonth() + i);
    return d.toISOString().slice(0, 7);
  });

  const payload = {
    kind: "FORECAST" as const,
    disclaimer:
      "All values below are FORECAST. They must never be presented as ACTUAL revenue or customer activity.",
    horizonMonths: horizon,
    revenue: {
      valuesCents: revFc.values,
      formatted: revFc.values.map(formatUsd),
      confidence: revFc.confidence,
      method: revFc.method,
      assumptions: revFc.assumptions,
      basisActualMonths: revenueTrend.length,
    },
    subscriptions: {
      values: subFc.values,
      confidence: subFc.confidence,
      method: subFc.method,
      assumptions: subFc.assumptions,
    },
    customerGrowth: {
      values: growthFc.values,
      confidence: growthFc.confidence,
      method: growthFc.method,
      assumptions: growthFc.assumptions,
    },
    renewals: {
      values: renewFc.values,
      confidence: renewFc.confidence,
      method: renewFc.method,
      assumptions: renewFc.assumptions,
    },
    infrastructureCapacity: {
      values: capFc.values,
      unit: "projected_mau_load_index",
      confidence: "low" as const,
      method: capFc.method,
      assumptions: [
        ...capFc.assumptions,
        "Capacity index is a planning heuristic from MAU — not a cloud bill forecast",
        `Current ACTUAL MRR context (not forecast): ${formatUsd(mrr)}`,
      ],
    },
    supportDemand: {
      values: supportFc.values,
      unit: "projected_open_tickets",
      confidence: supportFc.confidence,
      method: supportFc.method,
      assumptions: supportFc.assumptions,
    },
    forecastAccuracyReadiness: {
      score: Math.min(
        100,
        Math.round(
          (revenueTrend.length >= 3 ? 35 : revenueTrend.length * 10) +
            (renewSeries.length >= 2 ? 25 : 10) +
            (licenseMonths.length >= 2 ? 25 : 10) +
            15
        )
      ),
      note: "Readiness to trust forecasts — improves with longer ACTUAL history",
    },
    at: new Date().toISOString(),
  };
  savePhase11Run("bi_forecast", "Forecasting model", payload);
  return payload;
}
