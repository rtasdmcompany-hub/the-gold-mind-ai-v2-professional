/**
 * Phase 11 Sprint 1 — Global Commercial Operations store.
 * Commercial SaaS operations only — never imports or modifies Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.PHASE11_STORE_SECRET ||
    process.env.CLOSURE_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-phase11-store";
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

export function phase11DataDir(subdir: string): string {
  const root = process.env.PHASE11_DATA_DIR || path.join(process.cwd(), ".data", "phase11");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export type Phase11RunKind =
  | "ops_center"
  | "kpis"
  | "commercial"
  | "reports"
  | "health"
  | "success"
  | "scorecard"
  | "suite"
  | "bi_executive"
  | "bi_subscriptions"
  | "bi_revenue"
  | "bi_customers"
  | "bi_operations"
  | "bi_reports"
  | "bi_forecast"
  | "bi_scorecard"
  | "bi_suite"
  | "partner_suite"
  | "partner_scorecard"
  | "enterprise_suite"
  | "enterprise_scorecard"
  | "i18n_suite"
  | "i18n_scorecard"
  | "mobile_suite"
  | "mobile_scorecard"
  | "ai_suite"
  | "ai_scorecard"
  | "api_suite"
  | "api_scorecard"
  | "infra_suite"
  | "infra_scorecard"
  | "p11_closure_suite"
  | "p11_closure_scorecard"
  | "p11_closure_decision";

export interface Phase11Run {
  id: string;
  kind: Phase11RunKind;
  label: string;
  payload: unknown;
  at: string;
}

interface Store {
  version: 1;
  runs: Phase11Run[];
}

const EMPTY: Store = { version: 1, runs: [] };
let cache: Store | null = null;

function storePath(): string {
  return path.join(phase11DataDir("runs"), "runs.enc");
}

function read(): Store {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<Store>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  if (!Array.isArray(cache.runs)) cache.runs = [];
  return cache;
}

function write(data: Store): void {
  if (data.runs.length > 100) data.runs = data.runs.slice(0, 100);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function savePhase11Run(kind: Phase11RunKind, label: string, payload: unknown): Phase11Run {
  const store = read();
  const row: Phase11Run = {
    id: newId("p11"),
    kind,
    label,
    payload,
    at: new Date().toISOString(),
  };
  store.runs.unshift(row);
  write(store);
  return row;
}

export function listPhase11Runs(kind?: Phase11RunKind) {
  const rows = read().runs;
  return kind ? rows.filter((r) => r.kind === kind) : rows;
}

export function latestPhase11Run(kind: Phase11RunKind) {
  return listPhase11Runs(kind)[0] || null;
}

export const CORE_CERT_SHA =
  "1965551f7b88f403cf8a0af5475211a562b9c05500a0bb530e0136d38d403f1e";

export function commercialRoot(): string {
  return path.resolve(process.cwd(), "..", "..");
}

export function workspaceRoot(): string {
  return path.resolve(commercialRoot(), "..");
}

export function docsRoot(): string {
  return path.join(commercialRoot(), "Documentation");
}

export function sha256File(filePath: string): string | null {
  if (!fs.existsSync(filePath)) return null;
  return createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}
