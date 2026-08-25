/**
 * Market evidence store — commercial Market edition ops only.
 * Never imports or modifies Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.MARKET_STORE_SECRET ||
    process.env.SECURITY_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-market-store";
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

export function marketDataDir(subdir: string): string {
  const root = process.env.MARKET_DATA_DIR || path.join(process.cwd(), ".data", "market");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export type MarketRunKind =
  | "edition"
  | "compliance"
  | "assets"
  | "documentation"
  | "metadata"
  | "validation"
  | "submission";

export interface MarketRunRecord {
  id: string;
  kind: MarketRunKind;
  label: string;
  payload: unknown;
  at: string;
}

interface MarketStore {
  version: 1;
  runs: MarketRunRecord[];
}

const EMPTY: MarketStore = { version: 1, runs: [] };
let cache: MarketStore | null = null;

function storePath(): string {
  return path.join(marketDataDir("runs"), "runs.enc");
}

function read(): MarketStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<MarketStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  if (!Array.isArray(cache.runs)) cache.runs = [];
  return cache;
}

function write(data: MarketStore): void {
  if (data.runs.length > 200) data.runs = data.runs.slice(0, 200);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function saveMarketRun(kind: MarketRunKind, label: string, payload: unknown): MarketRunRecord {
  const store = read();
  const row: MarketRunRecord = {
    id: newId("mkt"),
    kind,
    label,
    payload,
    at: new Date().toISOString(),
  };
  store.runs.unshift(row);
  write(store);
  return row;
}

export function listMarketRuns(kind?: MarketRunKind) {
  const rows = read().runs;
  return kind ? rows.filter((r) => r.kind === kind) : rows;
}

export function latestMarketRun(kind: MarketRunKind) {
  return listMarketRuns(kind)[0] || null;
}

/** Resolve Commercial/ root from portal cwd */
export function commercialRoot(): string {
  const fromEnv = process.env.TGM_COMMERCIAL_ROOT;
  if (fromEnv && fs.existsSync(fromEnv)) return fromEnv;
  // CustomerPortal/web → ../../
  const candidate = path.resolve(process.cwd(), "..", "..");
  if (fs.existsSync(path.join(candidate, "Documentation"))) return candidate;
  const candidate2 = path.resolve(process.cwd(), "..", "..", "..", "Commercial");
  if (fs.existsSync(candidate2)) return candidate2;
  return candidate;
}

export function workspaceRoot(): string {
  return path.resolve(commercialRoot(), "..");
}

export const CORE_CERT_SHA =
  "c7a251ef5769d597f50f7515165106a937471ed765a491f59f7e542d05e165da";
export const CORE_REL_PATH = path.join("Experts", "TheGoldMindAI_Professional.mq5");
