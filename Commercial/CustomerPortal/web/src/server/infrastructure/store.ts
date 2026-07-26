/**
 * Encrypted infrastructure ops store — incidents, scaling events, snapshots.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type { OpsIncident } from "./types";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.INFRA_STORE_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-infra-store";
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

export interface InfraStore {
  version: 1;
  incidents: OpsIncident[];
  scalingEvents: { id: string; at: string; tier: string; note: string }[];
  lastSuiteAt?: string;
}

const EMPTY: InfraStore = { version: 1, incidents: [], scalingEvents: [] };
let cache: InfraStore | null = null;

function storePath(): string {
  const dir = path.join(process.cwd(), ".data", "infrastructure");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "ops.enc");
}

export function readInfraStore(): InfraStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<InfraStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  if (!Array.isArray(cache.incidents)) cache.incidents = [];
  if (!Array.isArray(cache.scalingEvents)) cache.scalingEvents = [];
  return cache;
}

export function writeInfraStore(data: InfraStore): void {
  if (data.incidents.length > 200) data.incidents = data.incidents.slice(0, 200);
  if (data.scalingEvents.length > 200) data.scalingEvents = data.scalingEvents.slice(0, 200);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function newInfraId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}
