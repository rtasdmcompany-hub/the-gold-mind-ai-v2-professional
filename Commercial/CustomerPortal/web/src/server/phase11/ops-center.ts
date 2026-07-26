/**
 * Task 1 — Global Operations Center aggregations.
 */
import { getAlertSummary } from "@/server/observability/alert-store";
import { getOpsIntelligenceDashboard } from "@/server/observability/ops-intelligence";
import { getProductionHealthDashboard } from "@/server/observability/health-dashboard";
import { getUptimeSec } from "@/server/cloud/gateway";
import { CORE_CERT_SHA, savePhase11Run, sha256File, workspaceRoot } from "./store";
import { safeBillingDashboard, safeEnsureCommercialData, safeEnterpriseDashboardWithHealth } from "./safe";
import path from "path";

export async function buildGlobalOperationsCenter() {
  safeEnsureCommercialData();
  const [enterprise, ops, healthDash] = await Promise.all([
    safeEnterpriseDashboardWithHealth(),
    getOpsIntelligenceDashboard().catch(async () => ({
      systemUptime: { seconds: getUptimeSec(), percentProxy: 99.0, health: "degraded" as const },
    })),
    getProductionHealthDashboard().catch(() => ({
      cards: [] as { id: string; status: string }[],
    })),
  ]);
  const billing = safeBillingDashboard();
  let alerts = { firing: 0, criticalFiring: 0, resolved: 0 };
  try {
    alerts = getAlertSummary();
  } catch {
    /* ignore */
  }
  const coreOk =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;

  const svcStatus = (id: string) =>
    healthDash.cards.find((c) => c.id === id)?.status ||
    ("systemHealth" in enterprise ? enterprise.systemHealth : "unknown") ||
    "unknown";

  const payload = {
    activeCustomers: enterprise.activeCustomers,
    activeLicenses: enterprise.activeLicenses,
    newRegistrations: enterprise.newRegistrations,
    revenue: enterprise.revenueOverview,
    revenueCents: enterprise.revenueCents,
    subscriptionStatus: {
      active: enterprise.subscriptions,
      failedPayments: enterprise.failedPayments,
      billingSubs: billing.subscriptionCount,
    },
    websiteHealth: svcStatus("portal"),
    apiHealth: svcStatus("api"),
    customerPortalStatus: svcStatus("portal"),
    systemHealth: "systemHealth" in enterprise ? enterprise.systemHealth : "degraded",
    supportQueue: {
      open: enterprise.supportTicketsOpen,
      total: enterprise.supportTicketsTotal,
    },
    securityAlerts: {
      firing: alerts.firing,
      critical: alerts.criticalFiring,
      resolved: alerts.resolved,
    },
    globalUptime: {
      seconds: getUptimeSec(),
      percentProxy: ops.systemUptime.percentProxy,
    },
    coreIsolation: "Phase 11 Operations Center never modifies Core Trading Engine",
    coreShaMatch: coreOk,
    coreSha: CORE_CERT_SHA,
    at: new Date().toISOString(),
  };
  savePhase11Run("ops_center", "Global Operations Center snapshot", payload);
  return payload;
}
