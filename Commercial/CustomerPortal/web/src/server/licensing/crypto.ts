import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes, timingSafeEqual } from "crypto";
import path from "path";
import fs from "fs";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw = process.env.LICENSE_STORE_SECRET || process.env.NEXTAUTH_SECRET || "dev-license-store-insecure";
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
  const dir = process.env.LICENSE_DATA_DIR || path.join(process.cwd(), ".data", "licensing");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function storePath(): string {
  return path.join(dataDir(), "store.enc");
}

export function graceDays(): number {
  const n = Number(process.env.LICENSE_GRACE_DAYS || "7");
  return Number.isFinite(n) && n >= 0 ? n : 7;
}

export function seatsForType(type: string): number {
  switch (type) {
    case "trial":
      return 1;
    case "monthly":
      return 2;
    case "yearly":
      return 3;
    case "lifetime":
      return 2;
    default:
      return 1;
  }
}

export function addDays(iso: string | Date, days: number): string {
  const d = new Date(iso);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString();
}

export function nowIso(): string {
  return new Date().toISOString();
}
