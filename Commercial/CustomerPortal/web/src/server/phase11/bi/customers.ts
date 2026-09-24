/**
 * Task 4 — Customer Analytics (ACTUAL from usage/CS/support).
 */
import { savePhase11Run } from "../store";
import {
  safeCustomerSuccessSummary,
  safeEnsureCommercialData,
  safeSupportTickets,
  safeUsageAnalytics,
} from "../safe";
import { loadBiLedger } from "./helpers";

export async function buildCustomerAnalytics() {
  safeEnsureCommercialData();
  const usage = safeUsageAnalytics();
  
  // FIX: Added await here because safeCustomerSuccessSummary is now async
  const cs = await safeCustomerSuccessSummary();
  
  const tickets = safeSupportTickets();
  const { licenses, subscriptions } = await loadBiLedger();

  const customers = new Set(licenses.map((l) => l.customerEmail.toLowerCase()));
  const active = new Set(
    licenses
      .filter((l) => l.status === "active" || l.status === "grace")
      .map((l) => l.customerEmail.toLowerCase())
  );
  const cancelled = subscriptions.filter((s) => s.status === "cancelled").length;
  const churnPct =
    customers.size === 0 ? 0 : Math.round((cancelled / Math.max(customers.size, 1)) * 1000) / 10;
  const retentionPct =
    customers.size === 0 ? 0 : Math.round((active.size / customers.size) * 1000) / 10;

  const openTickets = tickets.filter((t) => t.status === "open" || t.status === "pending").length;

  const payload = {
    kind: "ACTUAL" as const,
    dailyActiveUsers: usage.dailyActiveUsers,
    weeklyActiveUsers: usage.weeklyActiveUsers,
    monthlyActiveUsers: usage.monthlyActiveUsers,
    sessionDuration: { minutes: usage.sessionDurationMin },
    featureAdoption: usage.featureUsage,
    customerRetention: { percent: retentionPct, active: active.size, total: customers.size },
    customerChurn: {
      percent: churnPct,
      cancelledSubscriptions: cancelled,
      note: "Churn proxy = cancelled billing subscriptions / unique license customers (ACTUAL counts)",
    },
    customerSatisfaction: cs.avgSatisfaction,
    supportActivity: {
      open: openTickets,
      total: tickets.length,
      avgHealthScore: cs.avgHealthScore,
    },
    dataTrace: "usage analytics · feedback · support tickets · licenses · billing subscriptions",
    at: new Date().toISOString(),
  };
  savePhase11Run("bi_customers", "Customer analytics", payload);
  return payload;
}