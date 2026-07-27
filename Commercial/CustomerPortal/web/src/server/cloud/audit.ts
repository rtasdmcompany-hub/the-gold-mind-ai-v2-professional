/**
 * Centralized commercial audit log.
 * Encrypted file store — independent of Trading Engine.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type { AuditAction, AuditEntry, AuditResult } from "./types";
import { commercialDataRoot } from "./data-root";

const ALGO = "aes-256-gcm";

interface AuditStoreData {
  version: 1;
  edition: "Professional_Website";
  entries: AuditEntry[];
}

const EMPTY: AuditStoreData = {
  version: 1,
  edition: "Professional_Website",
  entries: [],
};

function masterKey(): Buffer {
  const raw =
    process.env.AUDIT_STORE_SECRET ||
    process.env.LICENSE_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    process.env.AUTH_SECRET ||
    "dev-audit-store";
  return createHash("sha256").update(raw).digest();
}

function encryptJson(obj: unknown): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGO, masterKey(), iv);
  const plaintext = Buffer.from(JSON.stringify(obj), "utf8");
  const enc = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString("base64");
}

function decryptJson<T>(blob: string): T {
  const buf = Buffer.from(blob, "base64");
  const iv = buf.subarray(0, 12);
  const tag = buf.subarray(12, 28);
  const data = buf.subarray(28);
  const decipher = createDecipheriv(ALGO, masterKey(), iv);
  decipher.setAuthTag(tag);
  const dec = Buffer.concat([decipher.update(data), decipher.final()]);
  return JSON.parse(dec.toString("utf8")) as T;
}

function dataDir(): string {
  const dir = process.env.AUDIT_DATA_DIR || commercialDataRoot("audit");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function storePath(): string {
  return path.join(dataDir(), "audit.enc");
}

let cache: AuditStoreData | null = null;

function readStore(): AuditStoreData {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<AuditStoreData>(fs.readFileSync(p, "utf8"));
    if (!Array.isArray(cache.entries)) cache.entries = [];
    return cache;
  } catch {
    throw new Error("AUDIT_STORE_DECRYPT_FAIL");
  }
}

function writeStore(data: AuditStoreData): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

function id(): string {
  return `aud_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export function writeAudit(input: {
  user: string;
  action: AuditAction;
  ip: string;
  result: AuditResult;
  detail?: string;
  resource?: string;
  meta?: Record<string, string>;
}): AuditEntry {
  const entry: AuditEntry = {
    id: id(),
    at: new Date().toISOString(),
    user: input.user || "anonymous",
    action: input.action,
    ip: maskIp(input.ip),
    result: input.result,
    detail: input.detail,
    resource: input.resource,
    meta: input.meta,
  };
  const data = structuredClone(readStore());
  data.entries.unshift(entry);
  if (data.entries.length > 10000) data.entries.length = 10000;
  writeStore(data);
  if (process.env.AUDIT_LOG_CONSOLE === "true" || process.env.NODE_ENV !== "production") {
    console.info(`[audit] ${entry.action} · ${entry.user} · ${entry.result} · ${entry.ip}`);
  }
  return entry;
}

export function listAudit(limit = 50, filter?: { action?: AuditAction; user?: string }): AuditEntry[] {
  let rows = readStore().entries;
  if (filter?.action) rows = rows.filter((e) => e.action === filter.action);
  if (filter?.user) rows = rows.filter((e) => e.user.toLowerCase() === filter.user!.toLowerCase());
  return rows.slice(0, limit);
}

export function auditCount(): number {
  return readStore().entries.length;
}

function maskIp(ip: string): string {
  if (!ip || ip === "unknown") return "unknown";
  const parts = ip.split(".");
  if (parts.length === 4) return `${parts[0]}.${parts[1]}.${parts[2]}.***`;
  if (ip.includes(":")) return ip.split(":").slice(0, 3).join(":") + ":***";
  return ip;
}

export function clientIpFromHeaders(headers: Headers): string {
  return (
    headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    headers.get("x-real-ip") ||
    "127.0.0.1"
  );
}
