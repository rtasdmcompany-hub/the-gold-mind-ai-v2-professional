/**
 * Shared crypto helpers for observability stores.
 * Failures here must NEVER affect Core Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.OBSERVABILITY_STORE_SECRET ||
    process.env.LAUNCH_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-observability-store";
  return createHash("sha256").update(raw).digest();
}

export function encryptJson(obj: unknown): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGO, masterKey(), iv);
  const enc = Buffer.concat([cipher.update(Buffer.from(JSON.stringify(obj), "utf8")), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString("base64");
}

export function decryptJson<T>(blob: string): T {
  const buf = Buffer.from(blob, "base64");
  const decipher = createDecipheriv(ALGO, masterKey(), buf.subarray(0, 12));
  decipher.setAuthTag(buf.subarray(12, 28));
  const dec = Buffer.concat([decipher.update(buf.subarray(28)), decipher.final()]);
  return JSON.parse(dec.toString("utf8")) as T;
}

export function obsDataDir(subdir: string): string {
  const root = process.env.OBSERVABILITY_DATA_DIR || path.join(process.cwd(), ".data", "observability");
  const dir = path.join(root, subdir);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

/** Strip emails / keys from telemetry detail strings */
export function sanitizeTelemetryDetail(raw?: string): string | undefined {
  if (!raw) return undefined;
  return raw
    .replace(/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/gi, "[redacted-email]")
    .replace(/(sk|pk|key|secret|token)[=:]\s*\S+/gi, "$1=[redacted]")
    .slice(0, 240);
}

export function hashIdentity(email: string): string {
  return createHash("sha256").update(email.toLowerCase()).digest("hex").slice(0, 16);
}
