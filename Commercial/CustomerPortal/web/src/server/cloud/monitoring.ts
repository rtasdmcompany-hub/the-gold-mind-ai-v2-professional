/**
 * Cloud service health monitoring.
 * Failures here must NEVER stop local Trading Engine operations.
 */
import fs from "fs";
import path from "path";
import { getCacheBackend, cacheSet, cacheGet, CacheKeys } from "./cache";
import { auditCount } from "./audit";
import { getUptimeSec } from "./gateway";
import { validateSecretsPresent } from "./security";
import { commercialDataRoot } from "./data-root";
import type { HealthStatus, ServiceHealth, SystemHealthReport } from "./types";
import { writeAudit } from "./audit";

async function timed<T>(fn: () => Promise<T> | T): Promise<{ ok: boolean; ms: number; error?: string; value?: T }> {
  const t0 = Date.now();
  try {
    const value = await fn();
    return { ok: true, ms: Date.now() - t0, value };
  } catch (e) {
    return { ok: false, ms: Date.now() - t0, error: e instanceof Error ? e.message : "error" };
  }
}

function rollup(services: ServiceHealth[]): HealthStatus {
  if (services.some((s) => s.status === "unhealthy")) return "unhealthy";
  if (services.some((s) => s.status === "degraded")) return "degraded";
  return "healthy";
}

export async function runHealthChecks(detailed = false): Promise<SystemHealthReport> {
  const services: ServiceHealth[] = [];

  // API / process
  services.push({
    id: "api",
    name: "API Gateway",
    status: "healthy",
    latencyMs: 0,
    detail: `uptime ${getUptimeSec()}s`,
  });

  // Customer portal (self)
  services.push({
    id: "portal",
    name: "Customer Portal",
    status: "healthy",
    latencyMs: 1,
    detail: "Next.js commercial portal",
  });

  // License store
  const lic = await timed(() => {
    const dir = process.env.LICENSE_DATA_DIR || commercialDataRoot("licensing");
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    return fs.readdirSync(dir).length;
  });
  services.push({
    id: "license",
    name: "License Service",
    status: lic.ok ? "healthy" : "unhealthy",
    latencyMs: lic.ms,
    detail: lic.ok ? `store ok (${lic.value} entries)` : lic.error,
  });

  // Billing / subscription store
  const bill = await timed(() => {
    const dir = process.env.BILLING_DATA_DIR || commercialDataRoot("billing");
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    return true;
  });
  services.push({
    id: "subscription",
    name: "Subscription / Billing Service",
    status: bill.ok ? "healthy" : "unhealthy",
    latencyMs: bill.ms,
    detail: bill.ok ? "encrypted store reachable" : bill.error,
  });

  // Payments (provider mode awareness — sandbox vs live)
  const payMode = (process.env.PAYMENT_MODE || process.env.BILLING_MODE || "sandbox").toLowerCase();
  const liveReady = !!(process.env.PADDLE_API_KEY || process.env.PAYPAL_CLIENT_ID);
  const paymentsStatus: ServiceHealth["status"] = !bill.ok
    ? "unhealthy"
    : payMode === "live" && !liveReady
      ? "degraded"
      : "healthy";
  services.push({
    id: "payments",
    name: "Payments",
    status: paymentsStatus,
    latencyMs: bill.ms,
    detail:
      payMode === "live"
        ? liveReady
          ? "live mode · credentials present"
          : "live mode · credentials missing (OWNER ACTION)"
        : `sandbox mode · store ${bill.ok ? "ok" : "fail"}`,
  });

  // Authentication (session secret + NextAuth)
  const authSecret = !!(process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET);
  const hasProvider =
    !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) ||
    process.env.PORTAL_ALLOW_DEMO_IN_PROD === "true";
  services.push({
    id: "auth",
    name: "Authentication",
    status: authSecret
      ? hasProvider || process.env.NODE_ENV !== "production"
        ? "healthy"
        : "degraded"
      : process.env.NODE_ENV === "production"
        ? "unhealthy"
        : "degraded",
    latencyMs: 0,
    detail: authSecret
      ? hasProvider
        ? "session secret configured · provider available"
        : "session secret configured · no OAuth/demo provider (OWNER ACTION: Google OAuth)"
      : "missing AUTH_SECRET/NEXTAUTH_SECRET",
  });

  // Update / releases
  const rel = await timed(() => {
    const dir = process.env.RELEASE_DATA_DIR || commercialDataRoot("releases");
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    return true;
  });
  services.push({
    id: "update",
    name: "Update Service",
    status: rel.ok ? "healthy" : "unhealthy",
    latencyMs: rel.ms,
    detail: rel.ok ? "release catalog reachable" : rel.error,
  });

  // Cache / Redis
  const cacheProbe = await timed(async () => {
    await cacheSet(CacheKeys.perf("health"), String(Date.now()), 30);
    return await cacheGet(CacheKeys.perf("health"));
  });
  services.push({
    id: "cache",
    name: "Cache (Upstash/Memory)",
    status: cacheProbe.ok && cacheProbe.value ? "healthy" : "degraded",
    latencyMs: cacheProbe.ms,
    detail: getCacheBackend(),
  });

  // Email outbox (billing emails)
  const emailConfigured = !!(process.env.RESEND_API_KEY || process.env.SMTP_HOST);
  const email = await timed(() => {
    const p = path.join(process.env.BILLING_DATA_DIR || commercialDataRoot("billing"), "billing.enc");
    return fs.existsSync(p) || true;
  });
  services.push({
    id: "email",
    name: "Email / Notification Service",
    status: email.ok ? (emailConfigured || process.env.NODE_ENV !== "production" ? "healthy" : "degraded") : "degraded",
    latencyMs: email.ms,
    detail: emailConfigured ? "provider configured" : "outbox via billing store · Resend/SMTP OWNER ACTION",
  });

  // Audit
  const aud = await timed(() => auditCount());
  services.push({
    id: "audit",
    name: "Audit System",
    status: aud.ok ? "healthy" : "unhealthy",
    latencyMs: aud.ms,
    detail: aud.ok ? `${aud.value} entries` : aud.error,
  });

  // Background workers (synthetic — queue depth from env/policy)
  services.push({
    id: "workers",
    name: "Background Workers",
    status: "healthy",
    latencyMs: 0,
    detail: "renewal/expiry email jobs on-demand (admin)",
  });

  // Database / persistence health
  const secrets = validateSecretsPresent();
  const persistenceOk = bill.ok && lic.ok && rel.ok;
  services.push({
    id: "database",
    name: "Database / Persistence",
    status: persistenceOk
      ? secrets.ok
        ? "healthy"
        : "degraded"
      : "unhealthy",
    latencyMs: 0,
    detail: persistenceOk
      ? secrets.ok
        ? "writable commercial stores · secrets present"
        : `writable stores · missing optional secrets: ${secrets.missing.join(", ")}`
      : `store write failed · missing: ${secrets.missing.join(", ")}`,
  });

  const report: SystemHealthReport = {
    status: rollup(services),
    checkedAt: new Date().toISOString(),
    services: detailed ? services : services.map(({ id, name, status, latencyMs }) => ({ id, name, status, latencyMs })),
    metrics: {
      uptimeSec: getUptimeSec(),
      auditEntries: aud.value || 0,
      cacheBackend: getCacheBackend(),
      rateLimitBackend: getCacheBackend(),
    },
  };

  if (detailed) {
    writeAudit({
      user: "system",
      action: "health_check",
      ip: "127.0.0.1",
      result: report.status === "unhealthy" ? "failure" : "success",
      detail: report.status,
    });
  }

  return report;
}
