/**
 * Security evidence store — commercial platform only.
 * Never touches Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.SECURITY_STORE_SECRET ||
    process.env.AUDIT_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-security-store";
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

export function securityDataDir(subdir: string): string {
  const root = process.env.SECURITY_DATA_DIR || path.join(process.cwd(), ".data", "security");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export type SecurityRunKind =
  | "assessment"
  | "pentest"
  | "owasp"
  | "secrets"
  | "data_protection"
  | "disaster_recovery"
  | "compliance";

export interface SecurityRunRecord {
  id: string;
  kind: SecurityRunKind;
  label: string;
  payload: unknown;
  at: string;
}

interface SecurityStore {
  version: 1;
  runs: SecurityRunRecord[];
}

const EMPTY: SecurityStore = { version: 1, runs: [] };
let cache: SecurityStore | null = null;

function storePath(): string {
  return path.join(securityDataDir("runs"), "runs.enc");
}

function read(): SecurityStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<SecurityStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  if (!Array.isArray(cache.runs)) cache.runs = [];
  return cache;
}

function write(data: SecurityStore): void {
  if (data.runs.length > 200) data.runs = data.runs.slice(0, 200);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function saveSecurityRun(
  kind: SecurityRunRecord["kind"],
  label: string,
  payload: unknown
): SecurityRunRecord {
  const store = read();
  const row: SecurityRunRecord = {
    id: newId("sec"),
    kind,
    label,
    payload,
    at: new Date().toISOString(),
  };
  store.runs.unshift(row);
  write(store);
  return row;
}

export function listSecurityRuns(kind?: SecurityRunRecord["kind"]) {
  const rows = read().runs;
  return kind ? rows.filter((r) => r.kind === kind) : rows;
}

export function latestSecurityRun(kind: SecurityRunRecord["kind"]) {
  return listSecurityRuns(kind)[0] || null;
}

export type FindingSeverity = "Critical" | "High" | "Medium" | "Low" | "Info";

export interface SecurityFinding {
  id: string;
  area: string;
  severity: FindingSeverity;
  title: string;
  detail: string;
  status: "open" | "mitigated" | "accepted" | "pass";
  mitigation?: string;
}
