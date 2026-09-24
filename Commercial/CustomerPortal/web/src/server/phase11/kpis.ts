/**
 * Task 2 — Business KPI Dashboard.
 */
import {
  safeBillingDashboard,
  safeBusinessIntelligence,
  safeCustomerSuccessSummary,
  safeEnsureCommercialData,
  safeEnterpriseDashboard,
  safeListLicenses,
  safeUsageAnalytics,
} from "./safe";
import { savePhase11Run } from "./store";

export async function buildBusinessKpiDashboard() {
  safeEnsureCommercialData();
  const usage = safeUsageAnalytics();
  const enterprise = await safeEnterpriseDashboard();
  const bi = await safeBusinessIntelligence();
  const billing = safeBillingDashboard();
  
  // FIX: Added await here because safeCustomerSuccessSummary is now async
  const cs = await safeCustomerSuccessSummary();
  
  const licenses = await safeListLicenses();

  const trialLicenses = licenses.filter((l) => l.type === "trial");
  const paidLicenses = licenses.filter(
    (l) => l.type !== "trial" && (l.status === "active" || l.status === "grace")
  );
  const cancelledSubs = billing.subscriptions.filter((s) => s.status === "cancelled").length;
  const totalSubsEver = Math.max(billing.subscriptions.length, 1);
  const cancellationRate = Math.round((cancelledSubs / totalSubsEver) * 1000) / 10;

  const convertedFromTrial = paidLicenses.filter((l) =>
    trialLicenses.some((t) => t.customerEmail.toLowerCase() === l.customerEmail.toLowerCase())
  ).length;
  const trialConversionRate =
    trialLicenses.length === 0
      ? 0
      : Math.round((convertedFromTrial / Math.max(trialLicenses.length, 1)) * 1000) / 10;

  const payload = {
    dailyActiveUsers: usage.dailyActiveUsers,
    weeklyActiveUsers: usage.weeklyActiveUsers,
    monthlyActiveUsers: usage.monthlyActiveUsers,
    customerGrowth: {
      active: enterprise.activeCustomers,
      newToday: enterprise.newRegistrations,
      retentionPct: bi.customerRetention,
    },
    licenseGrowth: {
      active: enterprise.activeLicenses,
      activationsToday: enterprise.dailyActivations,
      activationRate: bi.activationRate,
    },
    subscriptionGrowth: {
      active: enterprise.subscriptions,
      total: billing.subscriptions.length,
      renewals: billing.renewals.length,
    },
    renewalRate: bi.renewalRate,
    cancellationRate,
    trialConversionRate,
    customerSatisfaction: cs.avgSatisfaction,
    revenueTrend: bi.revenueTrends.slice(-12),
    measurable: true,
    at: new Date().toISOString(),
  };
  savePhase11Run("kpis", "Business KPI Dashboard snapshot", payload);
  return payload;
}