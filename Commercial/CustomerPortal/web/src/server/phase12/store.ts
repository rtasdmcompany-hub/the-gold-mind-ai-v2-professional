/**
 * Phase 12 encrypted run store — commercial LTS ops only.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.PHASE12_STORE_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.CLOSURE_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-phase12-store";
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

export function phase12DataDir(subdir: string): string {
  const root = process.env.PHASE12_DATA_DIR || path.join(process.cwd(), ".data", "phase12");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export type Phase12RunKind =
  | "cs_suite"
  | "support_suite"
  | "bi_suite"
  | "ops_suite"
  | "release_suite"
  | "v2_planning"
  | "monthly_reports"
  | "scorecard"
  | "lts_suite";

export interface Phase12Run {
  id: string;
  kind: Phase12RunKind;
  label: string;
  payload: unknown;
  at: string;
}

interface Store {
  version: 1;
  runs: Phase12Run[];
}

const EMPTY: Store = { version: 1, runs: [] };
let cache: Store | null = null;

function storePath(): string {
  return path.join(phase12DataDir("runs"), "runs.enc");
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
  if (data.runs.length > 120) data.runs = data.runs.slice(0, 120);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function savePhase12Run(kind: Phase12RunKind, label: string, payload: unknown): Phase12Run {
  const store = read();
  const row: Phase12Run = {
    id: newId("p12"),
    kind,
    label,
    payload,
    at: new Date().toISOString(),
  };
  store.runs.unshift(row);
  write(store);
  return row;
}

export function listPhase12Runs(kind?: Phase12RunKind) {
  const rows = read().runs;
  return kind ? rows.filter((r) => r.kind === kind) : rows;
}

export function latestPhase12Run(kind: Phase12RunKind) {
  return listPhase12Runs(kind)[0] || null;
}

/** Re-export Core helpers from Phase 11 store (same certified value). */
export {
  CORE_CERT_SHA,
  commercialRoot,
  workspaceRoot,
  docsRoot,
  sha256File,
} from "@/server/phase11/store";
