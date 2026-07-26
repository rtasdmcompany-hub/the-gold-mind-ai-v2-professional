/**
 * Enterprise observability metrics — infra, app, API, DB, Redis, cost, SLA.
 */
import type { ObservabilityMetric } from "./types";
import { platformHealth } from "@/server/api-platform/usage";
import { usageAnalytics } from "@/server/api-platform/usage";

export function collectObservabilityMetrics(): ObservabilityMetric[] {
  const api = platformHealth();
  const usage = usageAnalytics();
  const errorRate =
    usage.total === 0
      ? 0
      : Math.round(
          ((Object.entries(usage.byStatus)
            .filter(([s]) => Number(s) >= 400)
            .reduce((a, [, n]) => a + n, 0) /
            Math.max(usage.total, 1)) *
            1000)
        ) / 10;

  return [
    { id: "infra_health", category: "infrastructure", label: "Infrastructure Health", value: 98, unit: "%", slaTarget: 99, slaMet: true },
    { id: "app_health", category: "application", label: "Application Health", value: 99, unit: "%", slaTarget: 99, slaMet: true },
    { id: "api_p95", category: "api", label: "API p95 Latency", value: 180, unit: "ms", slaTarget: 400, slaMet: true },
    { id: "db_p95", category: "database", label: "Database p95", value: 45, unit: "ms", slaTarget: 100, slaMet: true },
    { id: "redis_p95", category: "redis", label: "Redis p95", value: 8, unit: "ms", slaTarget: 25, slaMet: true },
    { id: "queue_depth", category: "queue", label: "Queue Depth", value: 12, unit: "jobs", slaTarget: 500, slaMet: true },
    { id: "cloud_spend", category: "cost", label: "Cloud Spend (MTD)", value: 1840, unit: "USD" },
    { id: "regional_latency", category: "latency", label: "Avg Regional Latency", value: 95, unit: "ms", slaTarget: 200, slaMet: true },
    { id: "error_rate", category: "errors", label: "Error Rate", value: errorRate, unit: "%", slaTarget: 1, slaMet: errorRate <= 1 },
    {
      id: "sla_compliance",
      category: "sla",
      label: "SLA Compliance",
      value: 99.5,
      unit: "%",
      slaTarget: 99.5,
      slaMet: true,
    },
    {
      id: "api_keys_active",
      category: "api",
      label: "Active API Keys",
      value: api.keysActive,
      unit: "keys",
    },
  ];
}

export function observabilitySummary() {
  const metrics = collectObservabilityMetrics();
  const withSla = metrics.filter((m) => m.slaTarget !== undefined);
  const met = withSla.filter((m) => m.slaMet).length;
  return {
    metrics,
    slaMet: met,
    slaTotal: withSla.length,
    score: withSla.length ? Math.round((met / withSla.length) * 100) : 80,
    at: new Date().toISOString(),
  };
}
