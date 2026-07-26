/**
 * Commission engine — all amounts from config rules + verified attribution only.
 */
import type {
  AttributionEvent,
  CommissionLedgerEntry,
  CommissionRuleConfig,
  PartnerProfile,
  PartnerProgramConfig,
} from "./types";
import { auditPartner, mutatePartnerStore, newId, readPartnerStore } from "./store";

function tierBoostBps(partner: PartnerProfile, config: PartnerProgramConfig): number {
  return config.tiers.find((t) => t.id === partner.tier)?.commissionBoostBps || 0;
}

function pickRules(
  config: PartnerProgramConfig,
  attribution: AttributionEvent,
  isRenewal: boolean
): CommissionRuleConfig[] {
  return config.commissionRules.filter((r) => {
    if (!r.active) return false;
    if (r.campaignId) {
      const camp = readPartnerStore().campaigns.find((c) => c.id === r.campaignId && c.active);
      if (!camp) return false;
      const now = Date.now();
      if (Date.parse(camp.startsAt) > now || Date.parse(camp.endsAt) < now) return false;
    }
    if (r.planCodes?.length && attribution.planCode && !r.planCodes.includes(attribution.planCode)) {
      return false;
    }
    if (r.type === "recurring" && !isRenewal && attribution.type !== "sale") return false;
    if (r.type === "recurring" && !isRenewal) {
      // allow recurring rule only when note says renewal or type sale with renewal flag
      return isRenewal;
    }
    if ((r.type === "percentage" || r.type === "one_time") && attribution.type !== "sale") return false;
    if (r.type === "fixed" && attribution.type === "registration" && !attribution.verified) return false;
    return true;
  });
}

function computeAmountCents(
  rule: CommissionRuleConfig,
  saleAmountCents: number,
  boostBps: number
): number {
  if (rule.type === "fixed" || rule.type === "bonus") return Math.max(0, rule.value);
  if (rule.type === "percentage" || rule.type === "recurring" || rule.type === "one_time") {
    const bps = rule.value + boostBps;
    return Math.max(0, Math.round((saleAmountCents * bps) / 10000));
  }
  return 0;
}

/**
 * Create commission ledger rows only when attribution.verified === true.
 * Returns empty if attribution not verified (FINAL RULE).
 */
export function createCommissionsFromAttribution(input: {
  attributionId: string;
  actor: string;
  isRenewal?: boolean;
}): CommissionLedgerEntry[] {
  const store = readPartnerStore();
  const attr = store.attributions.find((a) => a.id === input.attributionId);
  if (!attr) throw new Error("ATTRIBUTION_NOT_FOUND");
  if (!attr.verified) {
    auditPartner(input.actor, "commission_blocked", `unverified attribution ${attr.id}`);
    return [];
  }
  const partner = store.partners.find((p) => p.id === attr.partnerId);
  if (!partner || partner.status === "suspended" || partner.status === "rejected") {
    throw new Error("PARTNER_NOT_ELIGIBLE");
  }

  const rules = pickRules(store.config, attr, !!input.isRenewal);
  const boost = tierBoostBps(partner, store.config);
  const saleCents = attr.amountCents || 0;
  const created: CommissionLedgerEntry[] = [];

  mutatePartnerStore((d) => {
    for (const rule of rules) {
      // prevent duplicate commission for same attribution+rule
      if (d.commissions.some((c) => c.attributionId === attr.id && c.ruleId === rule.id)) continue;
      const amountCents = computeAmountCents(rule, saleCents, boost);
      if (amountCents <= 0 && rule.type !== "fixed") continue;
      const entry: CommissionLedgerEntry = {
        id: newId("comm"),
        partnerId: partner.id,
        attributionId: attr.id,
        ruleId: rule.id,
        type: rule.type,
        amountCents,
        currency: "USD",
        status: rule.requiresApproval ? "pending_approval" : "approved",
        saleAmountCents: saleCents || undefined,
        createdAt: new Date().toISOString(),
        approvedAt: rule.requiresApproval ? undefined : new Date().toISOString(),
        approvedBy: rule.requiresApproval ? undefined : "auto",
        auditNote: `rule=${rule.id}; boostBps=${boost}; verified_attribution=${attr.id}`,
      };
      d.commissions.unshift(entry);
      created.push(entry);
    }
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor: input.actor,
      action: "commission_create",
      detail: `${created.length} commissions for attribution ${attr.id}`,
    });
  });

  return created;
}

export function approveCommission(commissionId: string, actor: string): CommissionLedgerEntry {
  let updated: CommissionLedgerEntry | null = null;
  mutatePartnerStore((d) => {
    const c = d.commissions.find((x) => x.id === commissionId);
    if (!c) throw new Error("COMMISSION_NOT_FOUND");
    if (c.status !== "pending_approval") throw new Error("COMMISSION_NOT_PENDING");
    c.status = "approved";
    c.approvedAt = new Date().toISOString();
    c.approvedBy = actor;
    updated = c;
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "commission_approve",
      detail: commissionId,
    });
  });
  return updated!;
}

export function clawbackCommission(commissionId: string, actor: string, reason: string): void {
  mutatePartnerStore((d) => {
    const c = d.commissions.find((x) => x.id === commissionId);
    if (!c) throw new Error("COMMISSION_NOT_FOUND");
    c.status = "clawed_back";
    c.clawbackReason = reason;
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "commission_clawback",
      detail: `${commissionId}: ${reason}`,
    });
  });
}

export function getCommissionConfigSnapshot() {
  const config = readPartnerStore().config;
  return {
    attribution: config.attribution,
    rules: config.commissionRules,
    tiers: config.tiers,
    approvalWorkflow: config.approvalWorkflow,
    minPayoutCents: config.minPayoutCents,
    note: "Policy changes are configuration updates — not Core code changes",
  };
}
