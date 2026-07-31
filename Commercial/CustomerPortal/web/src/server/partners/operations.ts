/**
 * Partner operations workflows — application → payout / disputes.
 */
import { randomBytes } from "crypto";
import type {
  PartnerApplication,
  PartnerPayoutRequest,
  PartnerProfile,
  PartnerStatus,
} from "./types";
import { mutatePartnerStore, newId, readPartnerStore } from "./store";
import { isProductionRuntime } from "@/server/security/dev-bypass";
import { refreshPartnerTier } from "./tiers";
import { recordAttribution, recordReferralClick } from "./affiliate";
import { createCommissionsFromAttribution } from "./commission";
import { brand } from "@/lib/brand";

function makeReferralCode(name: string): string {
  const base = name.replace(/[^a-zA-Z0-9]/g, "").slice(0, 8).toUpperCase() || "TGM";
  return `${base}${randomBytes(2).toString("hex").toUpperCase()}`;
}

export function submitPartnerApplication(input: {
  email: string;
  name: string;
  company?: string;
  region?: string;
  country?: string;
  website?: string;
  pitch: string;
}): PartnerApplication {
  const email = input.email.toLowerCase();
  let app: PartnerApplication | null = null;
  mutatePartnerStore((d) => {
    if (d.applications.some((a) => a.email === email && a.status === "submitted")) {
      throw new Error("APPLICATION_EXISTS");
    }
    app = {
      id: newId("papp"),
      email,
      name: input.name,
      company: input.company,
      region: input.region,
      country: input.country,
      website: input.website,
      pitch: input.pitch,
      status: "submitted",
      createdAt: new Date().toISOString(),
    };
    d.applications.unshift(app);
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor: email,
      action: "application_submit",
      detail: app.id,
    });
  });
  return app!;
}

export function approveApplication(applicationId: string, reviewer: string): PartnerProfile {
  let partner: PartnerProfile | null = null;
  mutatePartnerStore((d) => {
    const app = d.applications.find((a) => a.id === applicationId);
    if (!app) throw new Error("APPLICATION_NOT_FOUND");
    app.status = "approved";
    app.reviewedAt = new Date().toISOString();
    app.reviewer = reviewer;
    partner = {
      id: newId("ptr"),
      email: app.email,
      name: app.name,
      company: app.company,
      region: app.region,
      country: app.country,
      tier: "registered",
      status: "approved",
      referralCode: makeReferralCode(app.name),
      contractStatus: "sent",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    d.partners.unshift(partner);
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor: reviewer,
      action: "application_approve",
      detail: `${applicationId} → ${partner.id}`,
    });
  });
  return partner!;
}

export function rejectApplication(applicationId: string, reviewer: string, notes: string): void {
  mutatePartnerStore((d) => {
    const app = d.applications.find((a) => a.id === applicationId);
    if (!app) throw new Error("APPLICATION_NOT_FOUND");
    app.status = "rejected";
    app.reviewedAt = new Date().toISOString();
    app.reviewer = reviewer;
    app.notes = notes;
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor: reviewer,
      action: "application_reject",
      detail: applicationId,
    });
  });
}

export function verifyPartner(partnerId: string, actor: string): void {
  mutatePartnerStore((d) => {
    const p = d.partners.find((x) => x.id === partnerId);
    if (!p) throw new Error("PARTNER_NOT_FOUND");
    p.status = "verified";
    p.verifiedAt = new Date().toISOString();
    p.contractStatus = "signed";
    p.updatedAt = new Date().toISOString();
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "partner_verify",
      detail: partnerId,
    });
  });
  refreshPartnerTier(partnerId, actor);
}

export function setPartnerStatus(
  partnerId: string,
  status: PartnerStatus,
  actor: string,
  reason?: string
): void {
  mutatePartnerStore((d) => {
    const p = d.partners.find((x) => x.id === partnerId);
    if (!p) throw new Error("PARTNER_NOT_FOUND");
    p.status = status;
    p.updatedAt = new Date().toISOString();
    if (status === "suspended") {
      p.suspendedAt = new Date().toISOString();
      p.suspensionReason = reason;
    }
    if (status === "approved" || status === "verified") {
      p.suspendedAt = undefined;
      p.suspensionReason = undefined;
    }
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "partner_status",
      detail: `${partnerId} → ${status}`,
    });
  });
}

export function requestPayout(partnerId: string, actor: string): PartnerPayoutRequest {
  const store = readPartnerStore();
  const approved = store.commissions.filter(
    (c) => c.partnerId === partnerId && c.status === "approved"
  );
  const amountCents = approved.reduce((a, c) => a + c.amountCents, 0);
  if (amountCents < store.config.minPayoutCents) throw new Error("BELOW_MIN_PAYOUT");
  let req: PartnerPayoutRequest | null = null;
  mutatePartnerStore((d) => {
    req = {
      id: newId("pay"),
      partnerId,
      amountCents,
      status: "requested",
      commissionIds: approved.map((c) => c.id),
      requestedAt: new Date().toISOString(),
    };
    d.payouts.unshift(req);
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "payout_request",
      detail: `${req.id} cents=${amountCents}`,
    });
  });
  return req!;
}

export function processPayout(
  payoutId: string,
  actor: string,
  decision: "approved" | "paid" | "rejected",
  detail?: string
): void {
  mutatePartnerStore((d) => {
    const p = d.payouts.find((x) => x.id === payoutId);
    if (!p) throw new Error("PAYOUT_NOT_FOUND");
    p.status = decision;
    p.processedAt = new Date().toISOString();
    p.processor = actor;
    p.detail = detail;
    if (decision === "paid") {
      for (const id of p.commissionIds) {
        const c = d.commissions.find((x) => x.id === id);
        if (c && c.status === "approved") {
          c.status = "paid";
          c.paidAt = new Date().toISOString();
        }
      }
    }
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "payout_process",
      detail: `${payoutId} → ${decision}`,
    });
  });
}

export function openDispute(input: {
  partnerId: string;
  subject: string;
  commissionId?: string;
}): void {
  mutatePartnerStore((d) => {
    d.disputes.unshift({
      id: newId("disp"),
      partnerId: input.partnerId,
      commissionId: input.commissionId,
      subject: input.subject,
      status: "open",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  });
}

export function resolveDispute(disputeId: string, actor: string, resolution: string): void {
  mutatePartnerStore((d) => {
    const x = d.disputes.find((d0) => d0.id === disputeId);
    if (!x) throw new Error("DISPUTE_NOT_FOUND");
    x.status = "resolved";
    x.resolution = resolution;
    x.updatedAt = new Date().toISOString();
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor,
      action: "dispute_resolve",
      detail: disputeId,
    });
  });
}

export function ensureDemoPartner(): PartnerProfile {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_SEED !== "true") {
    const store = readPartnerStore();
    const existing = store.partners.find((p) => p.email === "partner@goldmind.local") || store.partners[0];
    if (existing) return existing;
    throw new Error("PARTNER_DEMO_SEED_DISABLED");
  }
  const store = readPartnerStore();
  const existing = store.partners.find((p) => p.email === "partner@goldmind.local");
  if (existing) return existing;
  const app = submitPartnerApplication({
    email: "partner@goldmind.local",
    name: "Demo Partner",
    company: `${brand.brandName} Channel Demo`,
    region: "EMEA",
    country: "AE",
    pitch: "Demo partner for Phase 11 Sprint 3 validation",
  });
  const partner = approveApplication(app.id, "system");
  verifyPartner(partner.id, "system");
  return readPartnerStore().partners.find((p) => p.id === partner.id)!;
}

/** Deterministic seed for suite demos without inventing unpaid commissions */
export function seedPartnerDemoTraffic(partnerId: string): void {
  const store = readPartnerStore();
  const partner = store.partners.find((p) => p.id === partnerId);
  if (!partner) return;
  if (store.clicks.some((c) => c.partnerId === partnerId)) return;

  for (let i = 0; i < 5; i++) {
    const visitorKey = `demo-visitor-${i}@example.com`;
    recordReferralClick({
      referralCode: partner.referralCode,
      visitorKey,
      landingPath: "/register",
      campaignId: i === 0 ? "camp_launch" : undefined,
    });
    if (i < 2) {
      recordAttribution({
        visitorKey,
        type: "registration",
        customerEmail: `referred${i}@example.com`,
        verified: true,
        actor: "system",
        detail: "demo registration",
      });
    }
    if (i === 0) {
      const attr = recordAttribution({
        visitorKey,
        type: "sale",
        customerEmail: "referred0@example.com",
        paymentId: `pay_demo_${i}`,
        amountCents: 9900,
        planCode: "monthly",
        verified: true,
        actor: "system",
        detail: "demo verified sale",
      });
      if (attr) createCommissionsFromAttribution({ attributionId: attr.id, actor: "system" });
    }
  }
}
