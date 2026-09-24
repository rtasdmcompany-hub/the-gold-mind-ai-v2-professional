/**
 * Task 5 — Operational Analytics (ACTUAL telemetry / health / support).
 */
import { getUptimeSec } from "@/server/cloud/gateway";
import { getProductionHealthDashboard } from "@/server/observability/health-dashboard";
import { ensureDemoTelemetry, getTelemetrySummary } from "@/server/observability/telemetry-store";
import { getAlertSummary } from "@/server/observability/alert-store";
import { getAdminReleaseDashboard } from "@/server/releases/release-service";
import { listIncidents } from "@/server/launch/incident-store";
import { savePhase11Run } from "../store";
import { safeEnsureCommercialData, safeEnterpriseDashboard, safeSupportTickets } from "../safe";

export async function buildOperationalAnalytics() {
  safeEnsureCommercialData();
  try {
    ensureDemoTelemetry();
  } catch {
    /* ignore */
  }
  const telemetry = (() => {
    try {
      return getTelemetrySummary();
    } catch {
      return {
        portalLoadMs: 0,
        apiResponseMs: 0,
        authenticationSuccessRate: 0,
        paymentSuccessRate: 0,
        updateSuccessRate: 0,
        sampleCount: 0,
      };
    }
  })();

  const health = await getProductionHealthDashboard().catch(() => ({
    overall: "degraded" as const,
    uptimeSec: getUptimeSec(),
  }));
  
  // FIX: Added await here because safeEnterpriseDashboard is now async
  const enterprise = await safeEnterpriseDashboard();
  
  const tickets = safeSupportTickets();
  const alerts = (() => {
    try {
      return getAlertSummary();
    } catch {
      return { firing: 0, criticalFiring: 0, resolved: 0, total: 0 };
    }
  })();
  const releases = (() => {
    try {
      return getAdminReleaseDashboard();
    } catch {
      return { updateSuccessRate: telemetry.updateSuccessRate || 0, totalDownloads: 0 };
    }
  })();
  const incidents = (() => {
    try {
      return listIncidents().slice(0, 20);
    } catch {
      return [];
    }
  })();

  const resolved = tickets.filter((t) => t.status === "resolved" || t.status === "closed").length;
  const slaMetPct =
    tickets.length === 0 ? 100 : Math.round((resolved / tickets.length) * 1000) / 10;

  const payload = {
    kind: "ACTUAL" as const,
    portalPerformance: { loadMs: telemetry.portalLoadMs },
    apiPerformance: { responseMs: telemetry.apiResponseMs },
    licenseActivations: enterprise.dailyActivations,
    updateSuccess: {
      rate: releases.updateSuccessRate ?? telemetry.updateSuccessRate,
      source: "releases / telemetry",
    },
    authenticationSuccess: { rate: telemetry.authenticationSuccessRate },
    paymentSuccess: { rate: telemetry.paymentSuccessRate },
    systemUptime: {
      seconds: "uptimeSec" in health ? health.uptimeSec : getUptimeSec(),
      overall: "overall" in health ? health.overall : "unknown",
    },
    supportSla: {
      resolvedRatePct: slaMetPct,
      open: tickets.filter((t) => t.status === "open" || t.status === "pending").length,
      note: "Resolved/closed  total tickets (ACTUAL) — proxy SLA until formal SLA clocks exist",
    },
    incidentTrends: {
      recent: incidents.length,
      alertsFiring: alerts.firing,
      critical: alerts.criticalFiring,
      sample: incidents.slice(0, 5).map((i) => ({
        id: (i as { id?: string }).id,
        title: (i as { title?: string }).title,
        status: (i as { status?: string }).status,
      })),
    },
    at: new Date().toISOString(),
  };
  savePhase11Run("bi_operations", "Operational analytics", payload);
  return payload;
}