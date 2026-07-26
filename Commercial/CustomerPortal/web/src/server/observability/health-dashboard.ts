/**
 * Production Health Dashboard aggregations.
 * Completely independent of Core Trading Engine.
 */
import { runHealthChecks } from "@/server/cloud/monitoring";
import type { HealthStatus } from "@/server/cloud/types";
import { getUptimeSec } from "@/server/cloud/gateway";
import { evaluateAlerts } from "./alert-engine";
import { getAlertSummary } from "./alert-store";
import { ensureDemoTelemetry, getTelemetrySummary } from "./telemetry-store";

export interface HealthCard {
  id: string;
  label: string;
  status: HealthStatus;
  latencyMs: number;
  detail?: string;
}

export async function getProductionHealthDashboard() {
  ensureDemoTelemetry();
  const report = await runHealthChecks(true);
  const svc = (id: string) => report.services.find((s) => s.id === id);

  const cards: HealthCard[] = [
    {
      id: "platform",
      label: "Overall Platform Health",
      status: report.status,
      latencyMs: 0,
      detail: `uptime ${getUptimeSec()}s`,
    },
    {
      id: "portal",
      label: "Customer Portal Health",
      status: svc("portal")?.status || "degraded",
      latencyMs: svc("portal")?.latencyMs || 0,
      detail: svc("portal")?.detail,
    },
    {
      id: "api",
      label: "API Gateway Health",
      status: svc("api")?.status || "degraded",
      latencyMs: svc("api")?.latencyMs || 0,
      detail: svc("api")?.detail,
    },
    {
      id: "auth",
      label: "Authentication Service",
      status: svc("auth")?.status || "degraded",
      latencyMs: svc("auth")?.latencyMs || 0,
      detail: svc("auth")?.detail,
    },
    {
      id: "license",
      label: "License Service",
      status: svc("license")?.status || "degraded",
      latencyMs: svc("license")?.latencyMs || 0,
      detail: svc("license")?.detail,
    },
    {
      id: "subscription",
      label: "Subscription Service",
      status: svc("subscription")?.status || "degraded",
      latencyMs: svc("subscription")?.latencyMs || 0,
      detail: svc("subscription")?.detail,
    },
    {
      id: "payments",
      label: "Payment Service",
      status: svc("payments")?.status || "degraded",
      latencyMs: svc("payments")?.latencyMs || 0,
      detail: svc("payments")?.detail,
    },
    {
      id: "email",
      label: "Email Service",
      status: svc("email")?.status || "degraded",
      latencyMs: svc("email")?.latencyMs || 0,
      detail: svc("email")?.detail,
    },
    {
      id: "update",
      label: "Update Service",
      status: svc("update")?.status || "degraded",
      latencyMs: svc("update")?.latencyMs || 0,
      detail: svc("update")?.detail,
    },
    {
      id: "database",
      label: "Database Health",
      status: svc("database")?.status || "degraded",
      latencyMs: svc("database")?.latencyMs || 0,
      detail: svc("database")?.detail,
    },
    {
      id: "redis",
      label: "Redis Cache",
      status: svc("cache")?.status || "degraded",
      latencyMs: svc("cache")?.latencyMs || 0,
      detail: svc("cache")?.detail || "Upstash/Memory",
    },
    {
      id: "workers",
      label: "Background Workers",
      status: svc("workers")?.status || "degraded",
      latencyMs: svc("workers")?.latencyMs || 0,
      detail: svc("workers")?.detail,
    },
  ];

  const alertEval = await evaluateAlerts();
  const alerts = getAlertSummary();
  const telemetry = getTelemetrySummary();

  return {
    overall: report.status,
    uptimeSec: getUptimeSec(),
    checkedAt: report.checkedAt,
    cards,
    telemetry,
    alerts,
    alertEval,
    isolation: {
      coreTradingEngine: "NOT_CONNECTED",
      monitoringFailureStopsTrading: false,
      statement: "Monitoring observes commercial platform only; Core EA continues if monitoring fails.",
    },
  };
}
