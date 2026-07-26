/**
 * Phase 10 production monitoring facade — commercial services only.
 * Cloud/monitoring failures must NEVER stop local Trading Engine operations.
 */
import { runHealthChecks } from "@/server/cloud/monitoring";
import type { HealthStatus, ServiceHealth, SystemHealthReport } from "@/server/cloud/types";
import { getActiveLaunchMode, assertNotPublicStableUnlessAuthorized } from "./environments";
import { getIncidentSummary } from "./incident-store";

export type MonitoredDomain =
  | "application"
  | "api"
  | "license"
  | "portal"
  | "payments"
  | "updates"
  | "authentication"
  | "database"
  | "email"
  | "workers";

export interface DomainHealth {
  domain: MonitoredDomain;
  label: string;
  status: HealthStatus;
  latencyMs: number;
  detail?: string;
}

function mapService(id: string, services: ServiceHealth[]): ServiceHealth | undefined {
  return services.find((s) => s.id === id);
}

export async function runProductionMonitoring(detailed = true): Promise<{
  report: SystemHealthReport;
  domains: DomainHealth[];
  launchMode: string;
  publicStableGate: { ok: boolean; reason: string };
  openIncidents: number;
  criticalIncidents: number;
}> {
  const report = await runHealthChecks(detailed);
  const services = report.services;

  const domains: DomainHealth[] = [
    {
      domain: "application",
      label: "Application Health",
      status: report.status,
      latencyMs: 0,
      detail: `rollup · uptime ${report.metrics?.uptimeSec ?? 0}s`,
    },
    {
      domain: "api",
      label: "API Health",
      status: mapService("api", services)?.status || "degraded",
      latencyMs: mapService("api", services)?.latencyMs || 0,
      detail: mapService("api", services)?.detail,
    },
    {
      domain: "license",
      label: "License Server",
      status: mapService("license", services)?.status || "degraded",
      latencyMs: mapService("license", services)?.latencyMs || 0,
      detail: mapService("license", services)?.detail,
    },
    {
      domain: "portal",
      label: "Customer Portal",
      status: mapService("portal", services)?.status || "degraded",
      latencyMs: mapService("portal", services)?.latencyMs || 0,
      detail: mapService("portal", services)?.detail,
    },
    {
      domain: "payments",
      label: "Payments",
      status: mapService("payments", services)?.status || mapService("subscription", services)?.status || "degraded",
      latencyMs: mapService("payments", services)?.latencyMs || mapService("subscription", services)?.latencyMs || 0,
      detail: mapService("payments", services)?.detail || mapService("subscription", services)?.detail,
    },
    {
      domain: "updates",
      label: "Updates",
      status: mapService("update", services)?.status || "degraded",
      latencyMs: mapService("update", services)?.latencyMs || 0,
      detail: mapService("update", services)?.detail,
    },
    {
      domain: "authentication",
      label: "Authentication",
      status: mapService("auth", services)?.status || "degraded",
      latencyMs: mapService("auth", services)?.latencyMs || 0,
      detail: mapService("auth", services)?.detail,
    },
    {
      domain: "database",
      label: "Database",
      status: mapService("database", services)?.status || "degraded",
      latencyMs: mapService("database", services)?.latencyMs || 0,
      detail: mapService("database", services)?.detail,
    },
    {
      domain: "email",
      label: "Email",
      status: mapService("email", services)?.status || "degraded",
      latencyMs: mapService("email", services)?.latencyMs || 0,
      detail: mapService("email", services)?.detail,
    },
    {
      domain: "workers",
      label: "Background Workers",
      status: mapService("workers", services)?.status || "degraded",
      latencyMs: mapService("workers", services)?.latencyMs || 0,
      detail: mapService("workers", services)?.detail,
    },
  ];

  const incidents = getIncidentSummary();
  return {
    report,
    domains,
    launchMode: getActiveLaunchMode(),
    publicStableGate: assertNotPublicStableUnlessAuthorized(),
    openIncidents: incidents.open,
    criticalIncidents: incidents.criticalOpen,
  };
}
