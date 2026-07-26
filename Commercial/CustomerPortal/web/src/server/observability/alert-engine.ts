/**
 * Evaluate alert rules from live commercial health + telemetry.
 * Evaluation failures must never throw into trading paths (isolated module).
 */
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getTelemetrySummary } from "./telemetry-store";
import { fireAlert, listAlertRules } from "./alert-store";
import { listSupportTickets } from "@/server/admin/support-store";
import { getProductionMetrics } from "@/server/launch/metrics-store";

export async function evaluateAlerts(): Promise<{ evaluated: number; fired: string[] }> {
  const rules = listAlertRules().filter((r) => r.enabled);
  const health = await runHealthChecks(true);
  const tel = getTelemetrySummary();
  const metrics = getProductionMetrics();
  const openTickets = listSupportTickets().filter((t) => t.status === "open" || t.status === "pending").length;
  const fired: string[] = [];

  const byId = (id: string) => health.services.find((s) => s.id === id);

  for (const rule of rules) {
    try {
      if (rule.id === "service_down" && health.status === "unhealthy") {
        fireAlert({
          ruleId: rule.id,
          title: "Service Down",
          detail: `Platform rollup unhealthy · ${health.services
            .filter((s) => s.status === "unhealthy")
            .map((s) => s.id)
            .join(", ")}`,
        });
        fired.push(rule.id);
      }
      if (rule.id === "database_issues" && byId("database")?.status === "unhealthy") {
        fireAlert({ ruleId: rule.id, title: "Database Issues", detail: byId("database")?.detail || "database unhealthy" });
        fired.push(rule.id);
      }
      if (rule.id === "email_delivery_failure" && byId("email") && byId("email")!.status !== "healthy") {
        fireAlert({
          ruleId: rule.id,
          title: "Email Delivery Failure",
          detail: byId("email")?.detail || "email degraded",
          severity: "medium",
        });
        fired.push(rule.id);
      }
      if (rule.id === "slow_api" && tel.apiResponseMs > 500) {
        fireAlert({
          ruleId: rule.id,
          title: "Slow API Response",
          detail: `API avg ${tel.apiResponseMs}ms > 500ms`,
        });
        fired.push(rule.id);
      }
      if (rule.id === "high_error_rate" && tel.authenticationSuccessRate < 95) {
        fireAlert({
          ruleId: rule.id,
          title: "High Error Rate",
          detail: `Auth success ${tel.authenticationSuccessRate}% < 95%`,
        });
        fired.push(rule.id);
      }
      if (rule.id === "failed_payments" && tel.paymentSuccessRate < 90) {
        fireAlert({
          ruleId: rule.id,
          title: "Failed Payments",
          detail: `Payment success ${tel.paymentSuccessRate}% < 90%`,
        });
        fired.push(rule.id);
      }
      if (rule.id === "license_validation_failure" && tel.licenseValidationRate < 95) {
        fireAlert({
          ruleId: rule.id,
          title: "License Validation Failure",
          detail: `License validation ${tel.licenseValidationRate}% < 95%`,
        });
        fired.push(rule.id);
      }
      if (rule.id === "update_failure" && tel.updateSuccessRate < 90) {
        fireAlert({
          ruleId: rule.id,
          title: "Update Failure",
          detail: `Update success ${tel.updateSuccessRate}% < 90%`,
        });
        fired.push(rule.id);
      }
      if (rule.id === "high_crash_rate" && metrics.crashRate > 2) {
        fireAlert({
          ruleId: rule.id,
          title: "High Crash Rate",
          detail: `Crash rate ${metrics.crashRate}% > 2% (portal proxy)`,
        });
        fired.push(rule.id);
      }
      if (rule.id === "support_queue_threshold" && openTickets > 20) {
        fireAlert({
          ruleId: rule.id,
          title: "Support Queue Threshold",
          detail: `Open tickets ${openTickets} > 20`,
        });
        fired.push(rule.id);
      }
    } catch {
      // swallow — monitoring must not cascade failures
    }
  }

  return { evaluated: rules.length, fired: [...new Set(fired)] };
}
