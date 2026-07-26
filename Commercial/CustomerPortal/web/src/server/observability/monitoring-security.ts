/**
 * Monitoring security & privacy controls.
 */
import { listPermissions, type AdminPermission } from "@/server/admin/roles";

export const OBSERVABILITY_PERMISSIONS = {
  read: "admin.observability.read" as AdminPermission,
  write: "admin.observability.write" as AdminPermission,
};

export function getMonitoringSecurityReview() {
  return {
    accessPermissions: {
      dashboard: "admin.observability.read",
      alertManage: "admin.observability.write",
      audit: "admin.audit.read",
      note: "No monitoring role can access Core Trading Engine",
    },
    auditLogs: {
      healthChecks: true,
      alertFire: true,
      alertUpdate: true,
      telemetrySanitize: true,
    },
    dashboardPermissions: {
      health: "admin.observability.read",
      telemetry: "admin.observability.read",
      usage: "admin.observability.read",
      alerts: "admin.observability.read",
      opsIntelligence: "admin.observability.read",
    },
    dataPrivacy: {
      usageIdentity: "SHA-256 truncated hash only",
      emailsInTelemetry: "redacted",
      secretsInDetail: "redacted",
      coreTradeData: "never collected",
    },
    telemetryRetention: {
      performanceSamplesDays: 30,
      usageEventsDays: 90,
      alerts: "retained until resolved + store cap",
    },
    sensitiveDataFiltering: {
      emailRegex: true,
      secretTokenRegex: true,
      maxDetailLength: 240,
    },
    isolation: {
      monitoringFailureStopsTrading: false,
      tradingEngineDependency: false,
    },
  };
}

export function roleCanReadObservability(role?: string): boolean {
  const perms = listPermissions(role);
  return perms.includes("admin.observability.read") || perms.includes("admin.cloud.read");
}
