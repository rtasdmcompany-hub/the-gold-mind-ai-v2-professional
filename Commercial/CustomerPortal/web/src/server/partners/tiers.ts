/**
 * Partner tier qualification — config-driven rules.
 */
import type { PartnerProfile, PartnerTierId } from "./types";
import { mutatePartnerStore, newId, readPartnerStore } from "./store";

export function computePartnerPerformance(partnerId: string) {
  const store = readPartnerStore();
  const sales = store.attributions.filter(
    (a) => a.partnerId === partnerId && a.type === "sale" && a.verified
  );
  const revenueCents = sales.reduce((a, s) => a + (s.amountCents || 0), 0);
  return { qualifiedSales: sales.length, revenueCents };
}

export function evaluateTier(partnerId: string): PartnerTierId {
  const store = readPartnerStore();
  const { qualifiedSales, revenueCents } = computePartnerPerformance(partnerId);
  const ordered = [...store.config.tiers].sort(
    (a, b) => b.minQualifiedSales - a.minQualifiedSales || b.minRevenueCents - a.minRevenueCents
  );
  for (const tier of ordered) {
    if (qualifiedSales >= tier.minQualifiedSales || revenueCents >= tier.minRevenueCents) {
      // both thresholds: require meeting the tier's primary bars — use OR as documented in config descriptions
      if (
        (tier.minQualifiedSales === 0 && tier.minRevenueCents === 0) ||
        qualifiedSales >= tier.minQualifiedSales ||
        revenueCents >= tier.minRevenueCents
      ) {
        return tier.id;
      }
    }
  }
  return "registered";
}

export function refreshPartnerTier(partnerId: string, actor: string): PartnerProfile {
  let updated: PartnerProfile | null = null;
  mutatePartnerStore((d) => {
    const p = d.partners.find((x) => x.id === partnerId);
    if (!p) throw new Error("PARTNER_NOT_FOUND");
    const next = evaluateTier(partnerId);
    p.tier = next;
    p.updatedAt = new Date().toISOString();
    updated = p;
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "tier_refresh",
      detail: `${partnerId} → ${next}`,
    });
  });
  return updated!;
}

export function listTierRules() {
  return readPartnerStore().config.tiers;
}
