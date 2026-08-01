/**
 * Encrypted JSON file store helper for Phase 10 launch ops.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import { commercialDataRoot } from "@/server/cloud/data-root";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.LAUNCH_STORE_SECRET ||
    process.env.AUDIT_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-launch-store";
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

export function ensureDir(dir: string): void {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

export function launchDataDir(subdir: string): string {
  // Serverless-safe commercial root (/tmp on Vercel) — never process.cwd()/.data.
  if (process.env.LAUNCH_DATA_DIR) {
    const dir = path.join(process.env.LAUNCH_DATA_DIR, subdir);
    try {
      ensureDir(dir);
      return dir;
    } catch {
      /* fall through to commercial root */
    }
  }
  return commercialDataRoot("launch", subdir);
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}
