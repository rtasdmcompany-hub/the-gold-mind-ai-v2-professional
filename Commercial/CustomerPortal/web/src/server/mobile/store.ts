/**
 * Encrypted mobile companion store — devices, sessions, push, support.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type {
  DiagnosticReport,
  MobileAppVersion,
  MobileDevice,
  MobileSession,
  OfflineCacheManifest,
  PushMessage,
  PushPreference,
  SupportTicketMobile,
  TrustedDevice,
} from "./types";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.MOBILE_STORE_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-mobile-store";
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

export interface MobileStore {
  version: 1;
  devices: MobileDevice[];
  sessions: MobileSession[];
  trusted: TrustedDevice[];
  pushPrefs: PushPreference[];
  pushMessages: PushMessage[];
  tickets: SupportTicketMobile[];
  diagnostics: DiagnosticReport[];
  offlineCaches: OfflineCacheManifest[];
  appVersions: MobileAppVersion[];
}

const EMPTY: MobileStore = {
  version: 1,
  devices: [],
  sessions: [],
  trusted: [],
  pushPrefs: [],
  pushMessages: [],
  tickets: [],
  diagnostics: [],
  offlineCaches: [],
  appVersions: [
    {
      platform: "android",
      latest: "1.0.0",
      minimum: "1.0.0",
      forceUpdate: false,
      releaseNotes: "Initial Mobile Companion release — commercial management only.",
    },
    {
      platform: "ios",
      latest: "1.0.0",
      minimum: "1.0.0",
      forceUpdate: false,
      releaseNotes: "Initial Mobile Companion release — commercial management only.",
    },
  ],
};

let cache: MobileStore | null = null;

function storePath(): string {
  const dir = path.join(process.cwd(), ".data", "mobile");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "companion.enc");
}

export function readMobileStore(): MobileStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<MobileStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  for (const k of Object.keys(EMPTY) as (keyof MobileStore)[]) {
    if (cache[k] === undefined) (cache as Record<string, unknown>)[k] = structuredClone(EMPTY[k]);
  }
  return cache;
}

export function writeMobileStore(data: MobileStore): void {
  if (data.sessions.length > 500) data.sessions = data.sessions.slice(0, 500);
  if (data.pushMessages.length > 1000) data.pushMessages = data.pushMessages.slice(0, 1000);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function newMobileId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export function issueOpaqueToken(): string {
  return randomBytes(32).toString("base64url");
}
