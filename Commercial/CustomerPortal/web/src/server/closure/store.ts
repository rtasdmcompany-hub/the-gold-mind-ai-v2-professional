/**
 * Phase 10 Sprint 10 — Project closure store.
 * Executive validation only — never modifies Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.CLOSURE_STORE_SECRET ||
    process.env.EXECUTIVE_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-closure-store";
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

export function closureDataDir(subdir: string): string {
  const root = process.env.CLOSURE_DATA_DIR || path.join(process.cwd(), ".data", "closure");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export type ClosureRunKind = "phases" | "architecture" | "operations" | "commercial" | "scorecard" | "decision" | "closure";

export interface ClosureRun {
  id: string;
  kind: ClosureRunKind;
  label: string;
  payload: unknown;
  at: string;
}

interface Store {
  version: 1;
  runs: ClosureRun[];
}

const EMPTY: Store = { version: 1, runs: [] };
let cache: Store | null = null;

function storePath(): string {
  return path.join(closureDataDir("runs"), "runs.enc");
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
  if (data.runs.length > 80) data.runs = data.runs.slice(0, 80);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function saveClosureRun(kind: ClosureRunKind, label: string, payload: unknown): ClosureRun {
  const store = read();
  const row: ClosureRun = {
    id: newId("cls"),
    kind,
    label,
    payload,
    at: new Date().toISOString(),
  };
  store.runs.unshift(row);
  write(store);
  return row;
}

export function listClosureRuns(kind?: ClosureRunKind) {
  const rows = read().runs;
  return kind ? rows.filter((r) => r.kind === kind) : rows;
}

export function latestClosureRun(kind: ClosureRunKind) {
  return listClosureRuns(kind)[0] || null;
}

export const CORE_CERT_SHA =
  "9fd202466a0894577f12721610b4a9a80f6f8d02bb9fd908aed3d3e88654d49a";

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

export function countFilesRecursive(dir: string, exts?: string[]): number {
  if (!fs.existsSync(dir)) return 0;
  let n = 0;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      if (ent.name === "node_modules" || ent.name === ".data" || ent.name === ".next") continue;
      n += countFilesRecursive(p, exts);
    } else if (!exts || exts.some((e) => ent.name.toLowerCase().endsWith(e))) {
      n += 1;
    }
  }
  return n;
}
