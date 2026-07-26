/**
 * Task 3 — Revenue Analytics (ACTUAL / UNATTRIBUTED only — never invented).
 */
import { savePhase11Run } from "../store";
import { safeEnsureCommercialData } from "../safe";
import {
  formatUsd,
  loadBiLedger,
  monthlyRevenueTrend,
  sumSucceededByCountry,
  sumSucceededByPlan,
  sumSucceededByProvider,
} from "./helpers";

export async function buildRevenueAnalytics() {
  safeEnsureCommercialData();
  const { payments } = loadBiLedger();
  const succeeded = payments.filter((p) => p.status === "succeeded");
  const refunded = payments.filter((p) => p.status === "refunded");
  const disputed = payments.filter((p) => p.status === "disputed");

  const byPlan = sumSucceededByPlan(payments);
  const byProvider = sumSucceededByProvider(payments);
  const country = sumSucceededByCountry(payments);
  const trend = monthlyRevenueTrend(payments);

  const totalSucceededCents = succeeded.reduce((a, p) => a + p.amountCents, 0);
  const refundCents = refunded.reduce((a, p) => a + p.amountCents, 0);
  const chargebackCents = disputed.reduce((a, p) => a + p.amountCents, 0);
  const denom = Math.max(totalSucceededCents, 1);
  const refundRate = Math.round((refundCents / denom) * 10000) / 100;
  const chargebackRate = Math.round((chargebackCents / denom) * 10000) / 100;
  const aovCents =
    succeeded.length === 0 ? 0 : Math.round(totalSucceededCents / succeeded.length);

  let growthPct = 0;
  if (trend.length >= 2) {
    const prev = trend[trend.length - 2].cents;
    const cur = trend[trend.length - 1].cents;
    growthPct = prev === 0 ? (cur > 0 ? 100 : 0) : Math.round(((cur - prev) / prev) * 1000) / 10;
  }

  const payload = {
    kind: "ACTUAL" as const,
    revenueByPlan: Object.entries(byPlan).map(([plan, cents]) => ({
      plan,
      cents,
      formatted: formatUsd(cents),
    })),
    revenueByCountry: {
      kind: country.kind,
      note: country.note,
      rows: Object.entries(country.byCountry).map(([countryCode, cents]) => ({
        country: countryCode,
        cents,
        formatted: formatUsd(cents),
      })),
    },
    revenueByPaymentProvider: Object.entries(byProvider).map(([provider, cents]) => ({
      provider,
      cents,
      formatted: formatUsd(cents),
    })),
    refundRate: { value: refundRate, unit: "percent_of_succeeded_cents", refundCents },
    chargebackRate: { value: chargebackRate, unit: "percent_of_succeeded_cents", chargebackCents },
    averageOrderValue: { cents: aovCents, formatted: formatUsd(aovCents) },
    revenueGrowth: {
      monthOverMonthPct: growthPct,
      basis: trend.length >= 2 ? "last two ACTUAL monthly buckets" : "insufficient months",
    },
    monthlyRevenueTrend: trend,
    totalSucceeded: { cents: totalSucceededCents, formatted: formatUsd(totalSucceededCents) },
    at: new Date().toISOString(),
  };
  savePhase11Run("bi_revenue", "Revenue analytics", payload);
  return payload;
}
