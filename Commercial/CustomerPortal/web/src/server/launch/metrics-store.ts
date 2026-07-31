/**
 * Beta production metrics events — commercial telemetry only.
 */
import fs from "fs";
import path from "path";
import { writeAudit } from "@/server/cloud/audit";
import { isProductionRuntime } from "@/server/security/dev-bypass";
import { decryptJson, encryptJson, launchDataDir, newId } from "./store-crypto";

export type MetricEventType =
  | "install_attempt"
  | "install_success"
  | "install_fail"
  | "activation_attempt"
  | "activation_success"
  | "activation_fail"
  | "login_attempt"
  | "login_success"
  | "login_fail"
  | "license_validation_ok"
  | "license_validation_fail"
  | "portal_page_view"
  | "update_success"
  | "update_fail"
  | "crash_report"
  | "session_end"
  | "support_request";

export interface MetricEvent {
  id: string;
  type: MetricEventType;
  email?: string;
  sessionMinutes?: number;
  detail?: string;
  at: string;
}

interface MetricsStore {
  version: 1;
  events: MetricEvent[];
}

const EMPTY: MetricsStore = { version: 1, events: [] };
let cache: MetricsStore | null = null;

function storePath(): string {
  return path.join(launchDataDir("metrics"), "events.enc");
}

function read(): MetricsStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<MetricsStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.events)) cache.events = [];
  return cache;
}

function write(data: MetricsStore): void {
  cache = data;
  if (data.events.length > 5000) data.events = data.events.slice(0, 5000);
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function recordMetricEvent(input: {
  type: MetricEventType;
  email?: string;
  sessionMinutes?: number;
  detail?: string;
}): MetricEvent {
  const store = read();
  const row: MetricEvent = {
    id: newId("met"),
    type: input.type,
    email: input.email?.toLowerCase(),
    sessionMinutes: input.sessionMinutes,
    detail: input.detail,
    at: new Date().toISOString(),
  };
  store.events.unshift(row);
  write(store);
  return row;
}

function rate(success: number, fail: number): number {
  const t = success + fail;
  if (t === 0) return 100;
  return Math.round((success / t) * 1000) / 10;
}

export function getProductionMetrics() {
  const events = read().events;
  const count = (t: MetricEventType) => events.filter((e) => e.type === t).length;

  const installSuccess = count("install_success");
  const installFail = count("install_fail");
  const activationSuccess = count("activation_success");
  const activationFail = count("activation_fail");
  const loginSuccess = count("login_success");
  const loginFail = count("login_fail");
  const licOk = count("license_validation_ok");
  const licFail = count("license_validation_fail");
  const updateOk = count("update_success");
  const updateFail = count("update_fail");
  const crashes = count("crash_report");
  const portalViews = count("portal_page_view");
  const supportRequests = count("support_request");

  const sessions = events.filter((e) => e.type === "session_end" && typeof e.sessionMinutes === "number");
  const avgSession =
    sessions.length === 0
      ? 0
      : Math.round((sessions.reduce((a, e) => a + (e.sessionMinutes || 0), 0) / sessions.length) * 10) / 10;

  const crashRate =
    loginSuccess + portalViews === 0
      ? 0
      : Math.round((crashes / Math.max(loginSuccess + portalViews, 1)) * 1000) / 10;

  return {
    installationSuccessRate: rate(installSuccess, installFail),
    activationSuccessRate: rate(activationSuccess, activationFail),
    loginSuccessRate: rate(loginSuccess, loginFail),
    licenseValidationRate: rate(licOk, licFail),
    portalUsage: portalViews,
    updateSuccessRate: rate(updateOk, updateFail),
    crashRate,
    averageSessionTimeMin: avgSession,
    supportRequests,
    totals: {
      installSuccess,
      installFail,
      activationSuccess,
      activationFail,
      loginSuccess,
      loginFail,
      crashes,
      events: events.length,
    },
  };
}

export function ensureDemoMetrics(): void {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_SEED !== "true") return;
  const store = read();
  if (store.events.length > 0) return;
  const samples: Array<{ type: MetricEventType; email?: string; sessionMinutes?: number }> = [
    { type: "install_success", email: "qa@thegoldmind.local" },
    { type: "install_success", email: "pro.trader@goldmind.local" },
    { type: "install_fail", email: "creator@example.com" },
    { type: "activation_success", email: "qa@thegoldmind.local" },
    { type: "activation_success", email: "pro.trader@goldmind.local" },
    { type: "login_success", email: "qa@thegoldmind.local" },
    { type: "login_success", email: "pro.trader@goldmind.local" },
    { type: "login_success", email: "support.lead@thegoldmind.local" },
    { type: "license_validation_ok", email: "qa@thegoldmind.local" },
    { type: "license_validation_ok", email: "pro.trader@goldmind.local" },
    { type: "portal_page_view", email: "qa@thegoldmind.local" },
    { type: "portal_page_view", email: "pro.trader@goldmind.local" },
    { type: "update_success", email: "qa@thegoldmind.local" },
    { type: "session_end", email: "qa@thegoldmind.local", sessionMinutes: 24 },
    { type: "session_end", email: "pro.trader@goldmind.local", sessionMinutes: 41 },
    { type: "support_request", email: "creator@example.com" },
  ];
  for (const s of samples) {
    store.events.push({
      id: newId("met"),
      type: s.type,
      email: s.email,
      sessionMinutes: s.sessionMinutes,
      detail: "Sprint 2 seed",
      at: new Date().toISOString(),
    });
  }
  write(store);
  writeAudit({
    user: "system",
    action: "admin_action",
    ip: "system",
    result: "success",
    detail: "demo metrics seeded",
  });
}
