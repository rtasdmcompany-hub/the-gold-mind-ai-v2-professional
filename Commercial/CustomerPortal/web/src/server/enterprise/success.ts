/**
 * Enterprise customer success metrics — org-scoped.
 */
import { listSupportTickets } from "@/server/admin/support-store";
import { forOrg, readEnterpriseStore } from "./store";
import { getPoolUtilization } from "./licensing";

export function computeOrgHealth(orgId: string): {
  score: number;
  factors: Record<string, number>;
} {
  const store = readEnterpriseStore();
  const org = store.organizations.find((o) => o.id === orgId);
  if (!org) return { score: 0, factors: {} };

  const seats = forOrg(store.seats, orgId);
  const assigned = seats.filter((s) => s.status === "assigned").length;
  const util = seats.length === 0 ? 50 : Math.round((assigned / seats.length) * 100);
  const subs = forOrg(store.subscriptions, orgId);
  const activeSubs = subs.filter((s) => s.status === "active" || s.status === "trialing").length;
  const pastDue = subs.some((s) => s.status === "past_due");

  let supportOpen = 0;
  try {
    const contacts = forOrg(store.contacts, orgId).map((c) => c.email);
    supportOpen = listSupportTickets().filter(
      (t) =>
        contacts.includes(t.customerEmail.toLowerCase()) &&
        (t.status === "open" || t.status === "pending")
    ).length;
  } catch {
    supportOpen = 0;
  }

  const factors = {
    utilization: Math.min(100, util),
    subscriptionHealth: pastDue ? 40 : activeSubs > 0 ? 90 : 55,
    supportLoad: Math.max(20, 100 - supportOpen * 15),
    status: org.status === "active" ? 100 : org.status === "trial" ? 75 : 35,
  };
  const score = Math.round(
    (factors.utilization + factors.subscriptionHealth + factors.supportLoad + factors.status) / 4
  );
  return { score, factors };
}

export function buildEnterpriseSuccessDashboard(orgId: string) {
  const store = readEnterpriseStore();
  const org = store.organizations.find((o) => o.id === orgId);
  if (!org) throw new Error("ORG_NOT_FOUND");

  const pools = forOrg(store.pools, orgId);
  const utilization = pools.map((p) => ({
    poolId: p.id,
    name: p.name,
    ...getPoolUtilization(orgId, p.id),
  }));
  const health = computeOrgHealth(orgId);
  const subs = forOrg(store.subscriptions, orgId);
  const renewalRisk = subs.filter((s) => {
    if (!s.renewalDate) return false;
    const days = (Date.parse(s.renewalDate) - Date.now()) / 86400000;
    return days >= 0 && days <= 30;
  });

  let supportActivity = { open: 0, total: 0 };
  try {
    const emails = forOrg(store.contacts, orgId).map((c) => c.email);
    const tickets = listSupportTickets().filter((t) =>
      emails.includes(t.customerEmail.toLowerCase())
    );
    supportActivity = {
      open: tickets.filter((t) => t.status === "open" || t.status === "pending").length,
      total: tickets.length,
    };
  } catch {
    /* ignore */
  }

  const members = forOrg(store.members, orgId);
  const accountGrowth = {
    members: members.length,
    seats: forOrg(store.seats, orgId).length,
    subscriptions: subs.length,
  };

  return {
    organization: org,
    organizationHealth: health,
    activeSeats: forOrg(store.seats, orgId).filter((s) => s.status === "assigned").length,
    licenseUtilization: utilization,
    renewalRisk: renewalRisk.map((s) => ({
      id: s.id,
      planCode: s.planCode,
      renewalDate: s.renewalDate,
    })),
    supportActivity,
    usageTrends: {
      note: "Seat assignment count as commercial usage proxy (ACTUAL)",
      assignedSeats: forOrg(store.seats, orgId).filter((s) => s.status === "assigned").length,
    },
    accountGrowth,
    customerSatisfaction: health.score >= 80 ? 4.5 : health.score >= 60 ? 3.8 : 3.0,
    at: new Date().toISOString(),
  };
}
