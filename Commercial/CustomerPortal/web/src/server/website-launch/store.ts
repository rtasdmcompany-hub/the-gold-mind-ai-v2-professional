/**
 * Website launch evidence store — commercial Website Edition only.
 * Never touches Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.WEBSITE_LAUNCH_STORE_SECRET ||
    process.env.SECURITY_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-website-launch-store";
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

export function websiteLaunchDataDir(subdir: string): string {
  const root = process.env.WEBSITE_LAUNCH_DATA_DIR || path.join(process.cwd(), ".data", "website-launch");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export type WebsiteLaunchKind =
  | "website"
  | "journey"
  | "workflows"
  | "deployment"
  | "operations"
  | "certification";

export interface WebsiteLaunchRun {
  id: string;
  kind: WebsiteLaunchKind;
  label: string;
  payload: unknown;
  at: string;
}

interface Store {
  version: 1;
  runs: WebsiteLaunchRun[];
}

const EMPTY: Store = { version: 1, runs: [] };
let cache: Store | null = null;

function storePath(): string {
  return path.join(websiteLaunchDataDir("runs"), "runs.enc");
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
  if (data.runs.length > 200) data.runs = data.runs.slice(0, 200);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function saveWebsiteLaunchRun(
  kind: WebsiteLaunchKind,
  label: string,
  payload: unknown
): WebsiteLaunchRun {
  const store = read();
  const row: WebsiteLaunchRun = {
    id: newId("wl"),
    kind,
    label,
    payload,
    at: new Date().toISOString(),
  };
  store.runs.unshift(row);
  write(store);
  return row;
}

export function listWebsiteLaunchRuns(kind?: WebsiteLaunchKind) {
  const rows = read().runs;
  return kind ? rows.filter((r) => r.kind === kind) : rows;
}

export function latestWebsiteLaunchRun(kind: WebsiteLaunchKind) {
  return listWebsiteLaunchRuns(kind)[0] || null;
}

export const CORE_CERT_SHA =
  "c7a251ef5769d597f50f7515165106a937471ed765a491f59f7e542d05e165da";

export function workspaceRoot(): string {
  const commercial = path.resolve(process.cwd(), "..", "..");
  return path.resolve(commercial, "..");
}

export function sha256File(filePath: string): string | null {
  if (!fs.existsSync(filePath)) return null;
  return createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}
