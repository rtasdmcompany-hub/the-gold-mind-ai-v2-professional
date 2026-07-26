/**
 * Partner portal dashboard aggregations.
 */
import { buildReferralLink } from "./affiliate";
import { getCommissionConfigSnapshot } from "./commission";
import { listPartnerResources } from "./resources";
import { listTierRules } from "./tiers";
import { readPartnerStore } from "./store";
import type { PartnerProfile } from "./types";

function formatUsd(cents: number): string {
  return `USD ${(cents / 100).toFixed(2)}`;
}

export function getPartnerPortalDashboard(partnerIdOrEmail: string) {
  const store = readPartnerStore();
  const partner =
    store.partners.find((p) => p.id === partnerIdOrEmail) ||
    store.partners.find((p) => p.email.toLowerCase() === partnerIdOrEmail.toLowerCase());
  if (!partner) return null;

  const commissions = store.commissions.filter((c) => c.partnerId === partner.id);
  const pending = commissions.filter((c) => c.status === "pending_approval");
  const approved = commissions.filter((c) => c.status === "approved");
  const paid = commissions.filter((c) => c.status === "paid");
  const payouts = store.payouts.filter((p) => p.partnerId === partner.id);
  const campaigns = store.campaigns.filter((c) => c.active);
  const clicks = store.clicks.filter((c) => c.partnerId === partner.id).length;
  const attrs = store.attributions.filter((a) => a.partnerId === partner.id);

  return {
    profile: partner,
    referralLink: buildReferralLink(partner.referralCode),
    referralCode: partner.referralCode,
    commissionSummary: {
      pendingCents: pending.reduce((a, c) => a + c.amountCents, 0),
      approvedCents: approved.reduce((a, c) => a + c.amountCents, 0),
      paidCents: paid.reduce((a, c) => a + c.amountCents, 0),
      pendingFormatted: formatUsd(pending.reduce((a, c) => a + c.amountCents, 0)),
      approvedFormatted: formatUsd(approved.reduce((a, c) => a + c.amountCents, 0)),
      paidFormatted: formatUsd(paid.reduce((a, c) => a + c.amountCents, 0)),
      history: commissions.slice(0, 40),
    },
    payoutStatus: payouts.slice(0, 20),
    campaigns,
    clicks,
    attributions: attrs.slice(0, 40),
    resources: listPartnerResources(),
    tiers: listTierRules(),
    training: [
      { id: "onboard", title: "Partner onboarding", path: "/portal/partner/training" },
      { id: "compliance", title: "Compliance essentials", path: "/portal/partner/resources" },
      { id: "sales", title: "Sales playbook", path: "/portal/partner/resources" },
    ],
    support: {
      email: "partners@thegoldmind.local",
      portalPath: "/portal/support",
    },
    coreIsolation: "Partner Portal never connects to Core Trading Engine",
    at: new Date().toISOString(),
  };
}

export function getPartnerByEmail(email: string): PartnerProfile | undefined {
  return readPartnerStore().partners.find((p) => p.email.toLowerCase() === email.toLowerCase());
}

export function getAdminPartnersOverview() {
  const store = readPartnerStore();
  return {
    partners: store.partners,
    applications: store.applications,
    commissions: store.commissions.slice(0, 50),
    payouts: store.payouts.slice(0, 50),
    disputes: store.disputes.slice(0, 50),
    config: getCommissionConfigSnapshot(),
    audit: store.audit.slice(0, 40),
  };
}
