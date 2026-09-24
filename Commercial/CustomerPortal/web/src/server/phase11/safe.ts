/**
 * Safe commercial data probes for Phase 11 CLI/admin.
 * Survives LICENSE_STORE_TAMPER_OR_DECRYPT_FAIL when secrets differ.
 */
import { ensureSeedData } from "@/server/licensing/seed";
import { listAllLicensesAdmin } from "@/server/licensing/license-service";
import { getAdminBillingDashboard } from "@/server/billing/billing-service";
import { listSupportTickets, ensureDemoTickets } from "@/server/admin/support-store";
import {
  getEnterpriseDashboard,
  getEnterpriseDashboardWithHealth,
  getBusinessIntelligence,
} from "@/server/admin/ops";
import { listAudit } from "@/server/cloud/audit";
import {
  getCustomerSuccessSummary,
  listCustomerHealthDirectory,
} from "@/server/success/customer-health";
import { ensureDemoUsage, getUsageAnalytics } from "@/server/observability/usage-analytics";

export function safeEnsureCommercialData(): void {
  try {
    ensureSeedData();
  } catch { /* CLI secret mismatch */ }
  try {
    ensureDemoTickets();
  } catch { /* ignore */ }
  try {
    ensureDemoUsage();
  } catch { /* ignore */ }
}

export async function safeListLicenses() {
  try {
    return await listAllLicensesAdmin();
  } catch {
    return [];
  }
}

export function safeBillingDashboard() {
  try {
    return getAdminBillingDashboard();
  } catch {
    return {
      revenueCents: 0,
      revenueFormatted: "USD 0.00",
      subscriptionCount: 0,
      failedPayments: [] as ReturnType<typeof getAdminBillingDashboard>["failedPayments"],
      refunds: [] as ReturnType<typeof getAdminBillingDashboard>["refunds"],
      renewals: [] as ReturnType<typeof getAdminBillingDashboard>["renewals"],
      recentTransactions: [] as ReturnType<typeof getAdminBillingDashboard>["recentTransactions"],
      subscriptions: [] as ReturnType<typeof getAdminBillingDashboard>["subscriptions"],
      invoices: [] as ReturnType<typeof getAdminBillingDashboard>["invoices"],
      webhookAudits: [] as ReturnType<typeof getAdminBillingDashboard>["webhookAudits"],
    };
  }
}

export async function safeEnterpriseDashboard() {
  try {
    return await getEnterpriseDashboard();
  } catch {
    return {
      activeCustomers: 0,
      activeLicenses: 0,
      subscriptions: 0,
      revenueOverview: "USD 0.00",
      revenueCents: 0,
      dailyActivations: 0,
      newRegistrations: 0,
      supportTicketsOpen: 0,
      supportTicketsTotal: 0,
      latestRelease: null,
      deviceCount: 0,
      entitlementSubs: 0,
      failedPayments: 0,
      rollbackEvents: 0,
      auditEntries: 0,
    };
  }
}

export async function safeEnterpriseDashboardWithHealth() {
  try {
    return await getEnterpriseDashboardWithHealth();
  } catch {
    const base = await safeEnterpriseDashboard();
    return {
      ...base,
      systemHealth: "degraded" as const,
      platformStatus: "degraded",
      healthServices: [],
    };
  }
}

export async function safeBusinessIntelligence() {
  try {
    return await getBusinessIntelligence();
  } catch {
    return {
      revenueTrends: [] as { month: string; cents: number; formatted: string }[],
      subscriptionGrowth: { active: 0, billingSubs: 0 },
      customerRetention: 0,
      activationRate: 0,
      renewalRate: 0,
      refundStatistics: { count: 0, cents: 0 },
      supportPerformance: { resolvedRate: 100, open: 0, total: 0 },
      productAdoption: {
        downloads: 0,
        updateSuccessRate: 100,
        licensesByType: { trial: 0, monthly: 0, yearly: 0, lifetime: 0 },
      },
    };
  }
}

export function safeSupportTickets() {
  try {
    return listSupportTickets();
  } catch {
    return [];
  }
}

export function safeAudit(limit = 20) {
  try {
    return listAudit(limit);
  } catch {
    return [];
  }
}

// FIX: Made async and added await
export async function safeCustomerSuccessSummary() {
  try {
    return await getCustomerSuccessSummary();
  } catch {
    return {
      customersTracked: 0,
      avgHealthScore: 0,
      activated: 0,
      atRisk: 0,
      avgSatisfaction: 0,
    };
  }
}

// FIX: Made async and added await
export async function safeCustomerHealthDirectory(q?: string) {
  try {
    return await listCustomerHealthDirectory(q);
  } catch {
    return [];
  }
}

export function safeUsageAnalytics() {
  try {
    ensureDemoUsage();
    return getUsageAnalytics();
  } catch {
    return {
      dailyActiveUsers: 0,
      weeklyActiveUsers: 0,
      monthlyActiveUsers: 0,
      sessionDurationMin: 0,
      featureUsage: [] as { feature: string; count: number }[],
      mostUsedPages: [] as { page: string; count: number }[],
      downloadCounts: 0,
      activationCounts: 0,
      retentionTrends: 0,
      eventCount: 0,
    };
  }
}