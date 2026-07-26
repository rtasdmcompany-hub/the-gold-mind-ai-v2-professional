/**
 * Usage analytics, request logging, error tracking, health.
 */
import { newApiId, readApiStore, writeApiStore } from "./store";
import { API_PLATFORM_VERSION, API_CORE_ISOLATION } from "./types";

export function logApiUsage(input: {
  apiKeyId?: string;
  ownerEmail?: string;
  method: string;
  path: string;
  status: number;
  requestId: string;
  ip: string;
  latencyMs: number;
  errorCode?: string;
}) {
  const store = readApiStore();
  store.usage.unshift({
    id: newApiId("use"),
    at: new Date().toISOString(),
    ...input,
  });
  if (input.status >= 400) {
    store.errors.unshift({
      id: newApiId("err"),
      at: new Date().toISOString(),
      code: input.errorCode || `HTTP_${input.status}`,
      path: input.path,
      requestId: input.requestId,
      detail: `${input.method} ${input.path}`,
    });
  }
  writeApiStore(store);
}

export function checkPlatformRateLimit(
  bucketKey: string,
  limit: number
): { ok: boolean; remaining: number } {
  const store = readApiStore();
  const now = Date.now();
  let b = store.rateBuckets[bucketKey];
  if (!b || now - b.windowStart > 60_000) {
    b = { count: 0, windowStart: now };
  }
  b.count += 1;
  store.rateBuckets[bucketKey] = b;
  writeApiStore(store);
  return { ok: b.count <= limit, remaining: Math.max(0, limit - b.count) };
}

export function usageAnalytics(ownerEmail?: string) {
  const store = readApiStore();
  let rows = store.usage;
  if (ownerEmail) rows = rows.filter((u) => u.ownerEmail === ownerEmail.toLowerCase());
  const byPath: Record<string, number> = {};
  const byStatus: Record<string, number> = {};
  for (const u of rows.slice(0, 500)) {
    byPath[u.path] = (byPath[u.path] || 0) + 1;
    byStatus[String(u.status)] = (byStatus[String(u.status)] || 0) + 1;
  }
  return {
    total: rows.length,
    byPath,
    byStatus,
    recent: rows.slice(0, 20),
    errors: store.errors.slice(0, 20),
  };
}

export function platformHealth() {
  const store = readApiStore();
  return {
    status: "healthy" as const,
    version: API_PLATFORM_VERSION,
    uptimeNote: "Process-local health for API platform module",
    keysActive: store.keys.filter((k) => !k.revokedAt).length,
    webhooksActive: store.webhooks.filter((w) => w.active).length,
    usageEvents: store.usage.length,
    errorEvents: store.errors.length,
    tradingExposed: false,
    coreIsolation: API_CORE_ISOLATION,
    at: new Date().toISOString(),
  };
}
