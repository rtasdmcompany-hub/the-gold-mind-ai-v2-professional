/**
 * Performance store — commercial platform only.
 * Never touches Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.PERF_STORE_SECRET ||
    process.env.OBSERVABILITY_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-perf-store";
  return createHash("sha256").update(raw).digest();
}

function encryptJson(obj: unknown): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGO, masterKey(), iv);
  const enc = Buffer.concat([cipher.update(Buffer.from(JSON.stringify(obj), "utf8")), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString("base64");
}

function decryptJson<T>(blob: string): T {
  const buf = Buffer.from(blob, "base64");
  const decipher = createDecipheriv(ALGO, masterKey(), buf.subarray(0, 12));
  decipher.setAuthTag(buf.subarray(12, 28));
  const dec = Buffer.concat([decipher.update(buf.subarray(28)), decipher.final()]);
  return JSON.parse(dec.toString("utf8")) as T;
}

export function perfDataDir(subdir: string): string {
  const root = process.env.PERF_DATA_DIR || path.join(process.cwd(), ".data", "performance");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export interface PerfRunRecord {
  id: string;
  kind: "benchmark" | "scalability" | "load" | "resilience" | "database" | "cloud";
  label: string;
  payload: unknown;
  at: string;
}

interface PerfStore {
  version: 1;
  runs: PerfRunRecord[];
}

const EMPTY: PerfStore = { version: 1, runs: [] };
let cache: PerfStore | null = null;

function storePath(): string {
  return path.join(perfDataDir("runs"), "runs.enc");
}

function read(): PerfStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<PerfStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.runs)) cache.runs = [];
  return cache;
}

function write(data: PerfStore): void {
  if (data.runs.length > 200) data.runs = data.runs.slice(0, 200);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function savePerfRun(kind: PerfRunRecord["kind"], label: string, payload: unknown): PerfRunRecord {
  const store = read();
  const row: PerfRunRecord = {
    id: newId("perf"),
    kind,
    label,
    payload,
    at: new Date().toISOString(),
  };
  store.runs.unshift(row);
  write(store);
  return row;
}

export function listPerfRuns(kind?: PerfRunRecord["kind"]) {
  const rows = read().runs;
  return kind ? rows.filter((r) => r.kind === kind) : rows;
}

export function latestPerfRun(kind: PerfRunRecord["kind"]) {
  return listPerfRuns(kind)[0] || null;
}

export function percentile(sorted: number[], p: number): number {
  if (!sorted.length) return 0;
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[idx];
}

export function stats(samples: number[]) {
  const sorted = [...samples].sort((a, b) => a - b);
  const sum = sorted.reduce((a, b) => a + b, 0);
  return {
    count: sorted.length,
    avg: sorted.length ? Math.round((sum / sorted.length) * 10) / 10 : 0,
    min: sorted[0] || 0,
    max: sorted[sorted.length - 1] || 0,
    p50: percentile(sorted, 50),
    p95: percentile(sorted, 95),
    p99: percentile(sorted, 99),
  };
}
