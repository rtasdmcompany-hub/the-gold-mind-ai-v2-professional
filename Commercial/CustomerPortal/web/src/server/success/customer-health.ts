/**
 * Customer Success health profiles — commercial only.
 */
import { listAllLicensesAdmin } from "@/server/licensing/license-service";
import { listAllSubscriptionsAdmin } from "@/server/licensing/subscription-service";
import { listSupportTickets } from "@/server/admin/support-store";
import { listFeedback, getFeedbackSummary } from "@/server/launch/feedback-store";
import { getParticipantByEmail, enrollmentCompletionPct, ensureDemoBetaParticipants } from "@/server/launch/beta-store";
import { suggestKbForTicket } from "./knowledge-base";

export interface CustomerHealthProfile {
  email: string;
  name: string;
  healthScore: number; // 0–100
  onboardingPct: number;
  activationStatus: "activated" | "pending" | "none";
  licenseStatus: string;
  activeLicenses: number;
  subscriptionStatus: string;
  supportHistory: Array<{ id: string; subject: string; status: string; updatedAt: string }>;
  kbSuggestions: Array<{ slug: string; title: string; category: string }>;
  satisfactionTimeline: Array<{ at: string; score: number; title: string }>;
  openTickets: number;
}

export async function getCustomerHealth(email: string): Promise<CustomerHealthProfile> {
  ensureDemoBetaParticipants();
  const e = email.toLowerCase();
  const licenses = (await listAllLicensesAdmin()).filter((l) => l.customerEmail === e);
  const subs = listAllSubscriptionsAdmin().filter((s) => s.customerEmail === e);
  const tickets = listSupportTickets().filter((t) => t.customerEmail === e);
  const feedback = listFeedback().filter((f) => f.customerEmail === e);
  const beta = getParticipantByEmail(e);

  const activated = licenses.filter((l) => l.activatedAt);
  const activationStatus =
    activated.length > 0 ? "activated" : licenses.length > 0 ? "pending" : "none";
  const activeLicenses = licenses.filter((l) => l.status === "active" || l.status === "grace").length;
  const licenseStatus =
    activeLicenses > 0 ? "active" : licenses.some((l) => l.status === "revoked") ? "revoked" : licenses.length ? "inactive" : "none";

  const sub = subs[0];
  const subscriptionStatus = sub?.status || "none";
  const onboardingPct = beta ? enrollmentCompletionPct(beta) : activationStatus === "activated" ? 80 : licenses.length ? 40 : 10;

  const satisfactionTimeline = feedback
    .filter((f) => typeof f.satisfactionScore === "number" || f.scores?.overallSatisfaction)
    .map((f) => ({
      at: f.createdAt,
      score: (f.satisfactionScore || f.scores?.overallSatisfaction || 0) as number,
      title: f.title,
    }))
    .sort((a, b) => a.at.localeCompare(b.at));

  const openTickets = tickets.filter((t) => t.status === "open" || t.status === "pending").length;
  const latestTicket = tickets[0];
  const kbSuggestions = latestTicket
    ? suggestKbForTicket(latestTicket.subject, latestTicket.body).map((a) => ({
        slug: a.slug,
        title: a.title,
        category: a.category,
      }))
    : suggestKbForTicket("activation license portal", "").map((a) => ({
        slug: a.slug,
        title: a.title,
        category: a.category,
      }));

  let health = 50;
  health += Math.min(30, onboardingPct * 0.3);
  if (activationStatus === "activated") health += 15;
  if (activeLicenses > 0) health += 10;
  if (openTickets === 0) health += 5;
  else health -= Math.min(15, openTickets * 5);
  const lastSat = satisfactionTimeline[satisfactionTimeline.length - 1]?.score;
  if (lastSat) health += (lastSat - 3) * 5;
  health = Math.max(0, Math.min(100, Math.round(health)));

  return {
    email: e,
    name: licenses[0]?.customerName || beta?.name || e,
    healthScore: health,
    onboardingPct,
    activationStatus,
    licenseStatus,
    activeLicenses,
    subscriptionStatus,
    supportHistory: tickets.slice(0, 10).map((t) => ({
      id: t.id,
      subject: t.subject,
      status: t.status,
      updatedAt: t.updatedAt,
    })),
    kbSuggestions,
    satisfactionTimeline,
    openTickets,
  };
}

export async function listCustomerHealthDirectory(q?: string) {
  ensureDemoBetaParticipants();
  const emails = new Set<string>();
  for (const l of await listAllLicensesAdmin()) emails.add(l.customerEmail.toLowerCase());
  for (const t of listSupportTickets()) emails.add(t.customerEmail.toLowerCase());
  for (const f of listFeedback()) emails.add(f.customerEmail.toLowerCase());
  let list = [...emails].sort();
  if (q) {
    const qq = q.toLowerCase();
    list = list.filter((e) => e.includes(qq));
  }
  
  const results = [];
  for (const email of list.slice(0, 100)) {
    const h = await getCustomerHealth(email);
    results.push({
      email: h.email,
      name: h.name,
      healthScore: h.healthScore,
      onboardingPct: h.onboardingPct,
      activationStatus: h.activationStatus,
      licenseStatus: h.licenseStatus,
      openTickets: h.openTickets,
    });
  }
  return results;
}

export async function getCustomerSuccessSummary() {
  const dir = await listCustomerHealthDirectory();
  const avg =
    dir.length === 0 ? 0 : Math.round((dir.reduce((a, c) => a + c.healthScore, 0) / dir.length) * 10) / 10;
  const fb = getFeedbackSummary();
  return {
    customersTracked: dir.length,
    avgHealthScore: avg,
    activated: dir.filter((c) => c.activationStatus === "activated").length,
    atRisk: dir.filter((c) => c.healthScore < 50).length,
    avgSatisfaction: fb.avgSatisfaction,
  };
}