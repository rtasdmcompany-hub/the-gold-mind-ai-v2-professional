/**
 * Affiliate referral tracking — cookie + hashed visitor, verified attribution only.
 */
import { createHash } from "crypto";
import {
  auditPartner,
  mutatePartnerStore,
  newId,
  readPartnerStore,
} from "./store";
import type { AttributionEvent, ReferralClick } from "./types";

export function hashVisitor(raw: string): string {
  return createHash("sha256").update(raw).digest("hex").slice(0, 32);
}

export function buildReferralLink(referralCode: string, baseUrl?: string, campaignId?: string): string {
  const base = (baseUrl || process.env.NEXT_PUBLIC_APP_URL || process.env.AUTH_URL || "https://the-gold-mind-ai-v2-professional.vercel.app").replace(
    /\/$/,
    ""
  );
  const q = new URLSearchParams({ ref: referralCode });
  if (campaignId) q.set("camp", campaignId);
  return `${base}/register?${q.toString()}`;
}

export function recordReferralClick(input: {
  referralCode: string;
  visitorKey: string;
  landingPath?: string;
  campaignId?: string;
  ip?: string;
}): ReferralClick {
  const store = readPartnerStore();
  const partner = store.partners.find((p) => {
    const codeOk = p.referralCode.toLowerCase() === input.referralCode.toLowerCase();
    const statusOk = p.status === "approved" || p.status === "verified";
    return codeOk && statusOk;
  });
  if (!partner) throw new Error("INVALID_REFERRAL_CODE");

  const click: ReferralClick = {
    id: newId("clk"),
    partnerId: partner.id,
    referralCode: partner.referralCode,
    campaignId: input.campaignId,
    visitorHash: hashVisitor(input.visitorKey),
    landingPath: input.landingPath || "/register",
    at: new Date().toISOString(),
    ipHash: input.ip ? hashVisitor(input.ip) : undefined,
  };

  mutatePartnerStore((d) => {
    d.clicks.unshift(click);
  });
  return click;
}

export function resolveAttributionPartner(visitorHash: string): {
  partnerId: string;
  referralCode: string;
  clickId: string;
} | null {
  const store = readPartnerStore();
  const days = store.config.attribution.cookieDays;
  const cutoff = Date.now() - days * 86400000;
  const clicks = store.clicks
    .filter((c) => c.visitorHash === visitorHash && Date.parse(c.at) >= cutoff)
    .sort((a, b) => Date.parse(b.at) - Date.parse(a.at));
  if (!clicks.length) return null;
  const chosen = store.config.attribution.lastClickWins ? clicks[0] : clicks[clicks.length - 1];
  return {
    partnerId: chosen.partnerId,
    referralCode: chosen.referralCode,
    clickId: chosen.id,
  };
}

/**
 * Record attribution. Conversion/sale commissions require verified=true.
 */
export function recordAttribution(input: {
  visitorKey: string;
  type: AttributionEvent["type"];
  customerEmail?: string;
  paymentId?: string;
  amountCents?: number;
  planCode?: string;
  verified: boolean;
  actor: string;
  detail?: string;
}): AttributionEvent | null {
  const visitorHash = hashVisitor(input.visitorKey);
  const resolved = resolveAttributionPartner(visitorHash);
  if (!resolved) return null;

  const store = readPartnerStore();
  const partner = store.partners.find((p) => p.id === resolved.partnerId);
  if (!partner) return null;

  if (
    store.config.attribution.blockSelfReferral &&
    input.customerEmail &&
    input.customerEmail.toLowerCase() === partner.email.toLowerCase()
  ) {
    auditPartner(input.actor, "attribution_blocked_self", input.customerEmail);
    return null;
  }

  if (store.config.attribution.requireVerifiedConversion && input.type !== "registration" && !input.verified) {
    auditPartner(input.actor, "attribution_unverified_blocked", `${input.type}`);
    return null;
  }

  const event: AttributionEvent = {
    id: newId("attr"),
    partnerId: resolved.partnerId,
    referralCode: resolved.referralCode,
    visitorHash,
    customerEmail: input.customerEmail?.toLowerCase(),
    type: input.type,
    paymentId: input.paymentId,
    amountCents: input.amountCents,
    planCode: input.planCode,
    clickId: resolved.clickId,
    verified: input.verified,
    at: new Date().toISOString(),
    detail: input.detail || `${input.type} attribution`,
  };

  mutatePartnerStore((d) => {
    d.attributions.unshift(event);
    d.audit.unshift({
      id: newId("paud"),
      at: new Date().toISOString(),
      actor: input.actor,
      action: "attribution_record",
      detail: `${event.id} verified=${event.verified}`,
    });
  });

  return event;
}

/** Cookie value helper for edge/middleware or client set */
export function referralCookiePayload(referralCode: string, visitorKey: string): string {
  return `${referralCode}.${hashVisitor(visitorKey)}`;
}
