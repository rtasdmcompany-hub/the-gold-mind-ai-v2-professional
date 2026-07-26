/**
 * Partner analytics — ACTUAL ledger counts only.
 */
import { readPartnerStore } from "./store";
import { computePartnerPerformance } from "./tiers";

function formatUsd(cents: number): string {
  return `USD ${(cents / 100).toFixed(2)}`;
}

export function buildPartnerAnalytics() {
  const store = readPartnerStore();
  const clicks = store.clicks.length;
  const registrations = store.attributions.filter((a) => a.type === "registration").length;
  const conversions = store.attributions.filter((a) => a.type === "conversion" || a.type === "sale").length;
  const sales = store.attributions.filter((a) => a.type === "sale" && a.verified);
  const revenueCents = sales.reduce((a, s) => a + (s.amountCents || 0), 0);
  const commissionCents = store.commissions
    .filter((c) => c.status === "approved" || c.status === "paid" || c.status === "pending_approval")
    .reduce((a, c) => a + c.amountCents, 0);
  const clawbacks = store.commissions.filter((c) => c.status === "clawed_back");
  const refundImpactCents = clawbacks.reduce((a, c) => a + c.amountCents, 0);

  const byPartner = store.partners.map((p) => {
    const perf = computePartnerPerformance(p.id);
    const comm = store.commissions
      .filter((c) => c.partnerId === p.id && c.status !== "rejected" && c.status !== "clawed_back")
      .reduce((a, c) => a + c.amountCents, 0);
    const partnerClicks = store.clicks.filter((c) => c.partnerId === p.id).length;
    return {
      partnerId: p.id,
      name: p.name,
      email: p.email,
      region: p.region || "UNATTRIBUTED",
      country: p.country || "UNATTRIBUTED",
      tier: p.tier,
      clicks: partnerClicks,
      sales: perf.qualifiedSales,
      revenueCents: perf.revenueCents,
      revenueFormatted: formatUsd(perf.revenueCents),
      commissionCents: comm,
      commissionFormatted: formatUsd(comm),
    };
  });

  const topPerforming = [...byPartner].sort((a, b) => b.revenueCents - a.revenueCents).slice(0, 10);

  const regionalMap = new Map<string, { revenueCents: number; partners: number; sales: number }>();
  for (const row of byPartner) {
    const key = row.region;
    const cur = regionalMap.get(key) || { revenueCents: 0, partners: 0, sales: 0 };
    cur.revenueCents += row.revenueCents;
    cur.partners += 1;
    cur.sales += row.sales;
    regionalMap.set(key, cur);
  }

  return {
    kind: "ACTUAL" as const,
    clicks,
    registrations,
    conversions,
    sales: sales.length,
    revenue: { cents: revenueCents, formatted: formatUsd(revenueCents) },
    commission: { cents: commissionCents, formatted: formatUsd(commissionCents) },
    refundImpact: {
      cents: refundImpactCents,
      formatted: formatUsd(refundImpactCents),
      note: "Clawed-back commissions (ACTUAL) — linked to refund/dispute policy",
    },
    topPerformingPartners: topPerforming,
    regionalPerformance: [...regionalMap.entries()].map(([region, v]) => ({
      region,
      ...v,
      revenueFormatted: formatUsd(v.revenueCents),
    })),
    partnerCount: store.partners.length,
    pendingApplications: store.applications.filter((a) => a.status === "submitted").length,
    at: new Date().toISOString(),
  };
}
