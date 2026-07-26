/**
 * Production stabilization review — commercial reliability signals.
 */
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getTelemetrySummary, ensureDemoTelemetry } from "@/server/observability/telemetry-store";
import { getProductionMetrics, ensureDemoMetrics } from "@/server/launch/metrics-store";
import { getAlertSummary } from "@/server/observability/alert-store";

export type StabilityRating = "stable" | "watch" | "unstable";

function rate(ok: boolean, watch: boolean): StabilityRating {
  if (!ok) return "unstable";
  if (watch) return "watch";
  return "stable";
}

export async function getProductionStabilization() {
  ensureDemoTelemetry();
  ensureDemoMetrics();
  const health = await runHealthChecks(true);
  const tel = getTelemetrySummary();
  const metrics = getProductionMetrics();
  const alerts = getAlertSummary();

  const svc = (id: string) => health.services.find((s) => s.id === id)?.status || "degraded";

  const areas = [
    {
      id: "portal",
      label: "Portal Performance",
      rating: rate(svc("portal") === "healthy", tel.portalLoadMs > 400),
      detail: `load ${tel.portalLoadMs}ms · status ${svc("portal")}`,
    },
    {
      id: "api",
      label: "API Reliability",
      rating: rate(svc("api") === "healthy", tel.apiResponseMs > 300),
      detail: `api ${tel.apiResponseMs}ms · status ${svc("api")}`,
    },
    {
      id: "license",
      label: "License Reliability",
      rating: rate(tel.licenseValidationRate >= 95, tel.licenseValidationRate < 98),
      detail: `validation ${tel.licenseValidationRate}%`,
    },
    {
      id: "installer",
      label: "Installer Reliability",
      rating: rate(tel.installerSuccessRate >= 90, tel.installerSuccessRate < 95),
      detail: `success ${tel.installerSuccessRate}%`,
    },
    {
      id: "update",
      label: "Update Reliability",
      rating: rate(tel.updateSuccessRate >= 90, tel.updateSuccessRate < 95),
      detail: `success ${tel.updateSuccessRate}%`,
    },
    {
      id: "auth",
      label: "Authentication",
      rating: rate(tel.authenticationSuccessRate >= 95 && svc("auth") !== "unhealthy", tel.authenticationSuccessRate < 98),
      detail: `success ${tel.authenticationSuccessRate}% · ${svc("auth")}`,
    },
    {
      id: "cloud",
      label: "Cloud Services",
      rating: rate(health.status === "healthy", health.status === "degraded"),
      detail: `rollup ${health.status} · alerts firing ${alerts.firing}`,
    },
    {
      id: "database",
      label: "Database",
      rating: rate(svc("database") === "healthy", svc("database") === "degraded"),
      detail: `status ${svc("database")} · query ${tel.databaseQueryMs}ms`,
    },
  ];

  const unstable = areas.filter((a) => a.rating === "unstable").length;
  const watch = areas.filter((a) => a.rating === "watch").length;
  const productStabilityScore = Math.max(0, 100 - unstable * 18 - watch * 6 - Math.min(20, alerts.criticalFiring * 10));

  return {
    areas,
    productStabilityScore,
    platformHealth: health.status,
    crashRate: metrics.crashRate,
    criticalAlerts: alerts.criticalFiring,
    reviewedAt: new Date().toISOString(),
    coreIsolation: "Monitoring/stabilization does not modify Core Trading Engine",
  };
}
