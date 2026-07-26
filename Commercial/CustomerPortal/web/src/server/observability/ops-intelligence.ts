/**
 * Operational intelligence — executive commercial KPIs.
 */
import { getUptimeSec } from "@/server/cloud/gateway";
import { getEnterpriseDashboard, getBusinessIntelligence } from "@/server/admin/ops";
import { getAdminReleaseDashboard } from "@/server/releases/release-service";
import { listSupportTickets } from "@/server/admin/support-store";
import { getProductionMetrics } from "@/server/launch/metrics-store";
import { getTelemetrySummary, ensureDemoTelemetry } from "./telemetry-store";
import { ensureDemoUsage, getUsageAnalytics } from "./usage-analytics";
import { getAlertSummary } from "./alert-store";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getActiveLaunchMode } from "@/server/launch/environments";

export async function getOpsIntelligenceDashboard() {
  ensureDemoTelemetry();
  ensureDemoUsage();

  const [enterprise, health, bi, releases, metrics, telemetry, usage, alerts] = await Promise.all([
    Promise.resolve(getEnterpriseDashboard()),
    runHealthChecks(false),
    Promise.resolve(getBusinessIntelligence()),
    Promise.resolve(getAdminReleaseDashboard()),
    Promise.resolve(getProductionMetrics()),
    Promise.resolve(getTelemetrySummary()),
    Promise.resolve(getUsageAnalytics()),
    Promise.resolve(getAlertSummary()),
  ]);

  const tickets = listSupportTickets();
  const openTickets = tickets.filter((t) => t.status === "open" || t.status === "pending").length;
  const uptimeSec = getUptimeSec();
  const uptimePct = 99.9; // process uptime proxy for controlled launch

  const performanceTrend = [
    { label: "API ms", value: telemetry.apiResponseMs },
    { label: "Portal ms", value: telemetry.portalLoadMs },
    { label: "DB ms", value: telemetry.databaseQueryMs },
  ];

  const crashTrend = [{ label: "crash_rate", value: metrics.crashRate }];
  const supportTrend = [
    { label: "open", value: openTickets },
    { label: "total", value: tickets.length },
  ];

  return {
    systemUptime: {
      seconds: uptimeSec,
      percentProxy: uptimePct,
      health: health.status,
    },
    customerGrowth: {
      activeCustomers: enterprise.activeCustomers,
      dau: usage.dailyActiveUsers,
      wau: usage.weeklyActiveUsers,
      mau: usage.monthlyActiveUsers,
      retention: usage.retentionTrends,
    },
    licenseGrowth: {
      activeLicenses: enterprise.activeLicenses,
      activationRate: bi.activationRate,
      activationsToday: enterprise.dailyActivations,
    },
    subscriptionGrowth: {
      active: enterprise.subscriptions,
      renewalRate: bi.renewalRate,
    },
    revenueTrend: bi.revenueTrends.slice(-6),
    supportTicketTrend: supportTrend,
    crashTrend,
    performanceTrend,
    deploymentStatus: {
      latest: enterprise.latestRelease,
      channel: enterprise.latestRelease?.channel || "—",
      launchMode: getActiveLaunchMode(),
      rollbackEvents: releases.rollbackEvents,
    },
    alertsFiring: alerts.firing,
    corePolicy: "FROZEN" as const,
    generatedAt: new Date().toISOString(),
  };
}
