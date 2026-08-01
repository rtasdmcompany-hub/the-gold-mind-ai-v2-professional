import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes, timingSafeEqual } from "crypto";
import path from "path";
import fs from "fs";
import { commercialDataRoot } from "@/server/cloud/data-root";
import { productGraceDays, productSeatsForType } from "@/lib/product";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.LICENSE_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    process.env.AUTH_SECRET ||
    "dev-license-store-insecure";
  return createHash("sha256").update(raw).digest();
}

export function sha256(input: string): string {
  return createHash("sha256").update(input, "utf8").digest("hex");
}

export function hmacSha256(payload: string): string {
  return createHmac("sha256", masterKey()).update(payload, "utf8").digest("hex");
}

export function safeEqualHex(a: string, b: string): boolean {
  try {
    const ba = Buffer.from(a, "hex");
    const bb = Buffer.from(b, "hex");
    if (ba.length !== bb.length) return false;
    return timingSafeEqual(ba, bb);
  } catch {
    return false;
  }
}

export function generateLicenseKey(type: string): string {
  const body = randomBytes(10).toString("hex").toUpperCase();
  const prefix =
    type === "trial" ? "TRL" : type === "monthly" ? "MON" : type === "yearly" ? "YER" : "LIF";
  return `TGM-${prefix}-${body.slice(0, 4)}-${body.slice(4, 8)}-${body.slice(8, 12)}`;
}

/**
 * Collapse common alias tricks so one person cannot mint many free trials
 * via Gmail dots / plus-tags / googlemail.
 */
export function normalizeTrialEmail(email: string): string {
  const e = email.trim().toLowerCase();
  const at = e.lastIndexOf("@");
  if (at < 1) return e;
  let local = e.slice(0, at);
  let domain = e.slice(at + 1);
  local = local.split("+")[0] || local;
  if (domain === "googlemail.com") domain = "gmail.com";
  if (domain === "gmail.com") local = local.replace(/\./g, "");
  return `${local}@${domain}`;
}

/** Stable trial key for an email — same address always yields the same key. */
export function deriveTrialKey(email: string): string {
  const norm = normalizeTrialEmail(email);
  const digest = hmacSha256(`tgm-trial-key-v1|${norm}`).toUpperCase().replace(/[^A-F0-9]/g, "");
  const body = (digest + digest).slice(0, 12);
  return `TGM-TRL-${body.slice(0, 4)}-${body.slice(4, 8)}-${body.slice(8, 12)}`;
}

/** Encrypt a recoverable trial plaintext key (AES-GCM via store cipher). */
export function sealSecret(plaintext: string): string {
  return encryptJson({ v: 1, s: plaintext });
}

export function openSecret(blob: string | null | undefined): string | null {
  if (!blob) return null;
  try {
    const o = decryptJson<{ v?: number; s?: string }>(blob);
    return typeof o?.s === "string" && o.s ? o.s : null;
  } catch {
    return null;
  }
}

export function hashClientIp(ip: string): string {
  const cleaned = (ip || "").trim().toLowerCase();
  if (!cleaned || cleaned === "127.0.0.1" || cleaned === "::1" || cleaned === "unknown") {
    return "";
  }
  return sha256(`tgm-trial-ip-v1|${cleaned}`);
}

export function maskLicenseKey(keyOrPrefix: string): string {
  if (keyOrPrefix.includes("*")) return keyOrPrefix;
  const parts = keyOrPrefix.split("-");
  if (parts.length >= 5) {
    return `${parts[0]}-${parts[1]}-****-****-${parts[parts.length - 1]}`;
  }
  if (keyOrPrefix.length <= 8) return "****";
  return `${keyOrPrefix.slice(0, 7)}-****-****-${keyOrPrefix.slice(-4)}`;
}

export function maskFingerprint(hash: string): string {
  if (!hash || hash.length < 12) return "****";
  return `${hash.slice(0, 8)}…${hash.slice(-4)}`;
}

export function encryptJson(obj: unknown): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGO, masterKey(), iv);
  const plaintext = Buffer.from(JSON.stringify(obj), "utf8");
  const enc = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString("base64");
}

export function decryptJson<T>(blob: string): T {
  const buf = Buffer.from(blob, "base64");
  const iv = buf.subarray(0, 12);
  const tag = buf.subarray(12, 28);
  const data = buf.subarray(28);
  const decipher = createDecipheriv(ALGO, masterKey(), iv);
  decipher.setAuthTag(tag);
  const dec = Buffer.concat([decipher.update(data), decipher.final()]);
  return JSON.parse(dec.toString("utf8")) as T;
}

export function dataDir(): string {
  const dir = process.env.LICENSE_DATA_DIR || commercialDataRoot("licensing");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function storePath(): string {
  return path.join(dataDir(), "store.enc");
}

export function graceDays(): number {
  return productGraceDays();
}

export function seatsForType(type: string): number {
  return productSeatsForType(type);
}

export function addDays(iso: string | Date, days: number): string {
  const d = new Date(iso);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString();
}

export function nowIso(): string {
  return new Date().toISOString();
}
