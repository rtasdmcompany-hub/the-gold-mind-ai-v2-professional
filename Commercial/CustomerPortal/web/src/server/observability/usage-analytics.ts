/**
 * Anonymized customer usage analytics — commercial portal only.
 */
import fs from "fs";
import path from "path";
import { decryptJson, encryptJson, hashIdentity, newId, obsDataDir, sanitizeTelemetryDetail } from "./store-crypto";

export interface UsageEvent {
  id: string;
  anonId: string; // hashed identity
  type: "session_start" | "session_end" | "page_view" | "feature_use" | "download" | "activation";
  page?: string;
  feature?: string;
  durationMin?: number;
  at: string;
}

interface UsageStore {
  version: 1;
  events: UsageEvent[];
  retentionDays: number;
}

const EMPTY: UsageStore = { version: 1, events: [], retentionDays: 90 };
let cache: UsageStore | null = null;

function storePath(): string {
  return path.join(obsDataDir("usage"), "events.enc");
}

function read(): UsageStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<UsageStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.events)) cache.events = [];
  if (!cache.retentionDays) cache.retentionDays = 90;
  return cache;
}

function write(data: UsageStore): void {
  const cutoff = Date.now() - data.retentionDays * 86400000;
  data.events = data.events.filter((e) => Date.parse(e.at) >= cutoff).slice(0, 20000);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function recordUsageEvent(input: {
  email?: string;
  anonId?: string;
  type: UsageEvent["type"];
  page?: string;
  feature?: string;
  durationMin?: number;
}): UsageEvent {
  const store = read();
  const anonId = input.anonId || (input.email ? hashIdentity(input.email) : newId("anon").slice(0, 16));
  const row: UsageEvent = {
    id: newId("use"),
    anonId,
    type: input.type,
    page: sanitizeTelemetryDetail(input.page),
    feature: sanitizeTelemetryDetail(input.feature),
    durationMin: input.durationMin,
    at: new Date().toISOString(),
  };
  store.events.unshift(row);
  write(store);
  return row;
}

function uniqueUsers(events: UsageEvent[], sinceMs: number): number {
  const set = new Set<string>();
  for (const e of events) {
    if (Date.parse(e.at) >= sinceMs) set.add(e.anonId);
  }
  return set.size;
}

export function getUsageAnalytics() {
  const events = read().events;
  const now = Date.now();
  const day = 86400000;
  const dau = uniqueUsers(events, now - day);
  const wau = uniqueUsers(events, now - 7 * day);
  const mau = uniqueUsers(events, now - 30 * day);

  const sessions = events.filter((e) => e.type === "session_end" && typeof e.durationMin === "number");
  const avgSession =
    sessions.length === 0
      ? 0
      : Math.round((sessions.reduce((a, e) => a + (e.durationMin || 0), 0) / sessions.length) * 10) / 10;

  const pageCounts = new Map<string, number>();
  for (const e of events.filter((x) => x.type === "page_view" && x.page)) {
    pageCounts.set(e.page!, (pageCounts.get(e.page!) || 0) + 1);
  }
  const mostUsedPages = [...pageCounts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([page, count]) => ({ page, count }));

  const featureCounts = new Map<string, number>();
  for (const e of events.filter((x) => x.type === "feature_use" && x.feature)) {
    featureCounts.set(e.feature!, (featureCounts.get(e.feature!) || 0) + 1);
  }
  const featureUsage = [...featureCounts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([feature, count]) => ({ feature, count }));

  const downloads = events.filter((e) => e.type === "download").length;
  const activations = events.filter((e) => e.type === "activation").length;

  // Retention proxy: users active in last 7d who were also active 8–14d ago
  const recent = new Set(events.filter((e) => Date.parse(e.at) >= now - 7 * day).map((e) => e.anonId));
  const prior = new Set(
    events.filter((e) => Date.parse(e.at) >= now - 14 * day && Date.parse(e.at) < now - 7 * day).map((e) => e.anonId)
  );
  let retained = 0;
  for (const id of prior) if (recent.has(id)) retained += 1;
  const retentionTrend = prior.size === 0 ? 0 : Math.round((retained / prior.size) * 1000) / 10;

  return {
    dailyActiveUsers: dau,
    weeklyActiveUsers: wau,
    monthlyActiveUsers: mau,
    sessionDurationMin: avgSession,
    featureUsage,
    mostUsedPages,
    downloadCounts: downloads,
    activationCounts: activations,
    retentionTrends: retentionTrend,
    eventCount: events.length,
  };
}

export function ensureDemoUsage(): void {
  const store = read();
  if (store.events.length > 0) return;
  const users = ["a1", "b2", "c3", "d4", "e5"].map((x) => hashIdentity(`user${x}@example.com`));
  const pages = ["/portal", "/portal/licenses", "/portal/downloads", "/portal/billing", "/portal/feedback"];
  const features = ["license_activate", "download_installer", "checkout_sandbox", "submit_feedback"];
  const now = Date.now();
  for (let i = 0; i < 40; i++) {
    const anonId = users[i % users.length];
    store.events.push({
      id: newId("use"),
      anonId,
      type: "page_view",
      page: pages[i % pages.length],
      at: new Date(now - i * 3600000).toISOString(),
    });
    if (i % 3 === 0) {
      store.events.push({
        id: newId("use"),
        anonId,
        type: "feature_use",
        feature: features[i % features.length],
        at: new Date(now - i * 3600000).toISOString(),
      });
    }
    if (i % 5 === 0) {
      store.events.push({
        id: newId("use"),
        anonId,
        type: "session_end",
        durationMin: 12 + (i % 30),
        at: new Date(now - i * 3600000).toISOString(),
      });
    }
    if (i % 7 === 0) {
      store.events.push({
        id: newId("use"),
        anonId,
        type: "download",
        at: new Date(now - i * 3600000).toISOString(),
      });
    }
    if (i % 8 === 0) {
      store.events.push({
        id: newId("use"),
        anonId,
        type: "activation",
        at: new Date(now - i * 3600000).toISOString(),
      });
    }
  }
  write(store);
}
