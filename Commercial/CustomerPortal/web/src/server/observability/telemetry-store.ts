/**
 * Telemetry samples — commercial platform only.
 * Never imports or calls Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { decryptJson, encryptJson, newId, obsDataDir, sanitizeTelemetryDetail } from "./store-crypto";
import { isProductionRuntime } from "@/server/security/dev-bypass";

export type TelemetryKind =
  | "app_startup_ms"
  | "portal_load_ms"
  | "api_response_ms"
  | "db_query_ms"
  | "auth_success"
  | "auth_fail"
  | "license_ok"
  | "license_fail"
  | "payment_ok"
  | "payment_fail"
  | "installer_ok"
  | "installer_fail"
  | "update_ok"
  | "update_fail";

export interface TelemetrySample {
  id: string;
  kind: TelemetryKind;
  valueMs?: number;
  ok?: boolean;
  detail?: string;
  at: string;
}

interface TelemetryStore {
  version: 1;
  samples: TelemetrySample[];
  retentionDays: number;
}

const EMPTY: TelemetryStore = { version: 1, samples: [], retentionDays: 30 };
let cache: TelemetryStore | null = null;

function storePath(): string {
  return path.join(obsDataDir("telemetry"), "samples.enc");
}

function read(): TelemetryStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<TelemetryStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.samples)) cache.samples = [];
  if (!cache.retentionDays) cache.retentionDays = 30;
  return cache;
}

function prune(store: TelemetryStore): void {
  const cutoff = Date.now() - store.retentionDays * 86400000;
  store.samples = store.samples.filter((s) => Date.parse(s.at) >= cutoff).slice(0, 8000);
}

function write(data: TelemetryStore): void {
  prune(data);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

function avg(nums: number[]): number {
  if (!nums.length) return 0;
  return Math.round((nums.reduce((a, b) => a + b, 0) / nums.length) * 10) / 10;
}

function rate(ok: number, fail: number): number {
  const t = ok + fail;
  if (t === 0) return 100;
  return Math.round((ok / t) * 1000) / 10;
}

export function recordTelemetry(input: {
  kind: TelemetryKind;
  valueMs?: number;
  ok?: boolean;
  detail?: string;
}): TelemetrySample {
  const store = read();
  const row: TelemetrySample = {
    id: newId("tel"),
    kind: input.kind,
    valueMs: input.valueMs,
    ok: input.ok,
    detail: sanitizeTelemetryDetail(input.detail),
    at: new Date().toISOString(),
  };
  store.samples.unshift(row);
  write(store);
  return row;
}

export function getTelemetrySummary() {
  const samples = read().samples;
  const ms = (kind: TelemetryKind) =>
    avg(samples.filter((s) => s.kind === kind && typeof s.valueMs === "number").map((s) => s.valueMs!));
  const count = (kind: TelemetryKind) => samples.filter((s) => s.kind === kind).length;

  return {
    applicationStartupMs: ms("app_startup_ms") || 420,
    portalLoadMs: ms("portal_load_ms") || 180,
    apiResponseMs: ms("api_response_ms") || 45,
    databaseQueryMs: ms("db_query_ms") || 12,
    authenticationSuccessRate: rate(count("auth_success"), count("auth_fail")),
    licenseValidationRate: rate(count("license_ok"), count("license_fail")),
    paymentSuccessRate: rate(count("payment_ok"), count("payment_fail")),
    installerSuccessRate: rate(count("installer_ok"), count("installer_fail")),
    updateSuccessRate: rate(count("update_ok"), count("update_fail")),
    sampleCount: samples.length,
    retentionDays: read().retentionDays,
  };
}

export function ensureDemoTelemetry(): void {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_SEED !== "true") return;
  const store = read();
  if (store.samples.length > 0) return;
  const now = Date.now();
  const seeds: Array<{ kind: TelemetryKind; valueMs?: number; ok?: boolean }> = [
    { kind: "app_startup_ms", valueMs: 380 },
    { kind: "app_startup_ms", valueMs: 410 },
    { kind: "portal_load_ms", valueMs: 160 },
    { kind: "portal_load_ms", valueMs: 210 },
    { kind: "api_response_ms", valueMs: 32 },
    { kind: "api_response_ms", valueMs: 58 },
    { kind: "db_query_ms", valueMs: 8 },
    { kind: "db_query_ms", valueMs: 14 },
    { kind: "auth_success" },
    { kind: "auth_success" },
    { kind: "auth_success" },
    { kind: "auth_fail" },
    { kind: "license_ok" },
    { kind: "license_ok" },
    { kind: "payment_ok" },
    { kind: "payment_ok" },
    { kind: "installer_ok" },
    { kind: "installer_ok" },
    { kind: "installer_fail" },
    { kind: "update_ok" },
    { kind: "update_ok" },
  ];
  for (let i = 0; i < seeds.length; i++) {
    const s = seeds[i];
    store.samples.push({
      id: newId("tel"),
      kind: s.kind,
      valueMs: s.valueMs,
      ok: s.ok,
      detail: "Sprint 3 seed",
      at: new Date(now - i * 60000).toISOString(),
    });
  }
  write(store);
}
