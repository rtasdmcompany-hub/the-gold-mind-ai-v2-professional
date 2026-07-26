/**
 * Alerting system — commercial observability only.
 */
import fs from "fs";
import path from "path";
import { writeAudit } from "@/server/cloud/audit";
import { decryptJson, encryptJson, newId, obsDataDir } from "./store-crypto";

export type AlertSeverity = "critical" | "high" | "medium" | "low";
export type AlertStatus = "firing" | "acknowledged" | "resolved";

export type AlertRuleId =
  | "service_down"
  | "high_error_rate"
  | "slow_api"
  | "failed_payments"
  | "license_validation_failure"
  | "database_issues"
  | "email_delivery_failure"
  | "update_failure"
  | "high_crash_rate"
  | "support_queue_threshold";

export interface AlertRule {
  id: AlertRuleId;
  name: string;
  severity: AlertSeverity;
  description: string;
  threshold: string;
  enabled: boolean;
}

export interface AlertEvent {
  id: string;
  ruleId: AlertRuleId;
  severity: AlertSeverity;
  status: AlertStatus;
  title: string;
  detail: string;
  firedAt: string;
  acknowledgedAt?: string;
  resolvedAt?: string;
  owner?: string;
}

interface AlertStore {
  version: 1;
  rules: AlertRule[];
  events: AlertEvent[];
}

const DEFAULT_RULES: AlertRule[] = [
  {
    id: "service_down",
    name: "Service Down",
    severity: "critical",
    description: "Any monitored service reports unhealthy",
    threshold: "status=unhealthy",
    enabled: true,
  },
  {
    id: "high_error_rate",
    name: "High Error Rate",
    severity: "high",
    description: "Auth/license/payment failure rate elevated",
    threshold: "success_rate<95%",
    enabled: true,
  },
  {
    id: "slow_api",
    name: "Slow API Response",
    severity: "medium",
    description: "API p50 response time high",
    threshold: "api_ms>500",
    enabled: true,
  },
  {
    id: "failed_payments",
    name: "Failed Payments",
    severity: "high",
    description: "Payment success rate below threshold",
    threshold: "payment_success<90%",
    enabled: true,
  },
  {
    id: "license_validation_failure",
    name: "License Validation Failure",
    severity: "high",
    description: "License validation success below threshold",
    threshold: "license_ok<95%",
    enabled: true,
  },
  {
    id: "database_issues",
    name: "Database Issues",
    severity: "critical",
    description: "Persistence/database probe unhealthy",
    threshold: "database=unhealthy",
    enabled: true,
  },
  {
    id: "email_delivery_failure",
    name: "Email Delivery Failure",
    severity: "medium",
    description: "Email service degraded/unhealthy",
    threshold: "email!=healthy",
    enabled: true,
  },
  {
    id: "update_failure",
    name: "Update Failure",
    severity: "high",
    description: "Update success rate below threshold",
    threshold: "update_success<90%",
    enabled: true,
  },
  {
    id: "high_crash_rate",
    name: "High Crash Rate",
    severity: "high",
    description: "Portal crash proxy above threshold",
    threshold: "crash_rate>2%",
    enabled: true,
  },
  {
    id: "support_queue_threshold",
    name: "Support Queue Threshold",
    severity: "medium",
    description: "Open support tickets above threshold",
    threshold: "open_tickets>20",
    enabled: true,
  },
];

const EMPTY: AlertStore = { version: 1, rules: DEFAULT_RULES, events: [] };
let cache: AlertStore | null = null;

function storePath(): string {
  return path.join(obsDataDir("alerts"), "alerts.enc");
}

function read(): AlertStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<AlertStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.rules) || cache.rules.length === 0) cache.rules = structuredClone(DEFAULT_RULES);
  if (!Array.isArray(cache.events)) cache.events = [];
  return cache;
}

function write(data: AlertStore): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function listAlertRules(): AlertRule[] {
  return read().rules;
}

export function listAlerts(filter?: { status?: AlertStatus; severity?: AlertSeverity }) {
  let rows = [...read().events];
  if (filter?.status) rows = rows.filter((e) => e.status === filter.status);
  if (filter?.severity) rows = rows.filter((e) => e.severity === filter.severity);
  return rows.sort((a, b) => b.firedAt.localeCompare(a.firedAt));
}

export function getAlertSummary() {
  const events = read().events;
  const firing = events.filter((e) => e.status === "firing" || e.status === "acknowledged");
  return {
    rules: read().rules.length,
    firing: firing.length,
    criticalFiring: firing.filter((e) => e.severity === "critical").length,
    resolved: events.filter((e) => e.status === "resolved").length,
    total: events.length,
  };
}

export function fireAlert(input: {
  ruleId: AlertRuleId;
  title: string;
  detail: string;
  severity?: AlertSeverity;
}): AlertEvent {
  const store = read();
  const rule = store.rules.find((r) => r.id === input.ruleId);
  const existing = store.events.find(
    (e) => e.ruleId === input.ruleId && (e.status === "firing" || e.status === "acknowledged")
  );
  if (existing) {
    existing.detail = input.detail;
    existing.firedAt = new Date().toISOString();
    write(store);
    return existing;
  }
  const row: AlertEvent = {
    id: newId("alrt"),
    ruleId: input.ruleId,
    severity: input.severity || rule?.severity || "medium",
    status: "firing",
    title: input.title,
    detail: input.detail,
    firedAt: new Date().toISOString(),
  };
  store.events.unshift(row);
  write(store);
  writeAudit({
    user: "system",
    action: "alert_fire",
    ip: "observability",
    result: "success",
    detail: `${row.ruleId} · ${row.severity}`,
  });
  return row;
}

export function updateAlert(
  id: string,
  patch: Partial<Pick<AlertEvent, "status" | "owner">>,
  actor: string
): AlertEvent | null {
  const store = read();
  const row = store.events.find((e) => e.id === id);
  if (!row) return null;
  if (patch.status) {
    row.status = patch.status;
    if (patch.status === "acknowledged") row.acknowledgedAt = new Date().toISOString();
    if (patch.status === "resolved") row.resolvedAt = new Date().toISOString();
  }
  if (patch.owner) row.owner = patch.owner;
  write(store);
  writeAudit({
    user: actor,
    action: "alert_update",
    ip: "admin",
    result: "success",
    detail: `${id} · ${row.status}`,
  });
  return row;
}

export function setRuleEnabled(ruleId: AlertRuleId, enabled: boolean, actor: string): void {
  const store = read();
  const rule = store.rules.find((r) => r.id === ruleId);
  if (!rule) return;
  rule.enabled = enabled;
  write(store);
  writeAudit({
    user: actor,
    action: "alert_rule",
    ip: "admin",
    result: "success",
    detail: `${ruleId}=${enabled}`,
  });
}
