/**
 * Multi-tenant enterprise store — org data isolated by orgId.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import type {
  CrmContact,
  CrmLead,
  Department,
  EnterpriseAuditEntry,
  EnterpriseConfig,
  EnterpriseRoleDef,
  LicenseAuditEntry,
  LicensePool,
  OrgInvoice,
  OrgMember,
  OrgSubscription,
  Organization,
  PurchaseOrder,
  SeatLicense,
} from "./types";
import { DEFAULT_ENTERPRISE_CONFIG } from "./config";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.ENTERPRISE_STORE_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-enterprise-store";
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

export function enterpriseDataDir(subdir = ""): string {
  const root = process.env.ENTERPRISE_DATA_DIR || path.join(process.cwd(), ".data", "enterprise");
  const dir = subdir ? path.join(root, subdir) : root;
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export interface EnterpriseStoreData {
  version: 1;
  config: EnterpriseConfig;
  organizations: Organization[];
  departments: Department[];
  members: OrgMember[];
  contacts: CrmContact[];
  leads: CrmLead[];
  pools: LicensePool[];
  seats: SeatLicense[];
  subscriptions: OrgSubscription[];
  invoices: OrgInvoice[];
  purchaseOrders: PurchaseOrder[];
  customRoles: EnterpriseRoleDef[];
  audit: EnterpriseAuditEntry[];
  licenseAudit: LicenseAuditEntry[];
  logins: { id: string; orgId: string; email: string; at: string; result: "success" | "denied" }[];
}

const EMPTY: EnterpriseStoreData = {
  version: 1,
  config: DEFAULT_ENTERPRISE_CONFIG,
  organizations: [],
  departments: [],
  members: [],
  contacts: [],
  leads: [],
  pools: [],
  seats: [],
  subscriptions: [],
  invoices: [],
  purchaseOrders: [],
  customRoles: [],
  audit: [],
  licenseAudit: [],
  logins: [],
};

let cache: EnterpriseStoreData | null = null;

function storePath(): string {
  return path.join(enterpriseDataDir(), "enterprise.enc");
}

export function readEnterpriseStore(): EnterpriseStoreData {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    cache.config = structuredClone(DEFAULT_ENTERPRISE_CONFIG);
    return cache;
  }
  try {
    cache = decryptJson<EnterpriseStoreData>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
    cache.config = structuredClone(DEFAULT_ENTERPRISE_CONFIG);
  }
  if (!cache.config) cache.config = structuredClone(DEFAULT_ENTERPRISE_CONFIG);
  for (const key of Object.keys(EMPTY) as (keyof EnterpriseStoreData)[]) {
    if (key === "version" || key === "config") continue;
    if (!Array.isArray(cache[key])) (cache as EnterpriseStoreData)[key] = [] as never;
  }
  return cache;
}

export function writeEnterpriseStore(data: EnterpriseStoreData): void {
  if (data.audit.length > 20000) data.audit = data.audit.slice(0, 20000);
  if (data.licenseAudit.length > 20000) data.licenseAudit = data.licenseAudit.slice(0, 20000);
  if (data.logins.length > 10000) data.logins = data.logins.slice(0, 10000);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function mutateEnterpriseStore(fn: (data: EnterpriseStoreData) => void): EnterpriseStoreData {
  const data = readEnterpriseStore();
  fn(data);
  writeEnterpriseStore(data);
  return data;
}

/** Append-only immutable audit (never mutates prior rows). */
export function appendOrgAudit(orgId: string, actor: string, action: string, detail: string): void {
  mutateEnterpriseStore((d) => {
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action,
      detail,
      immutable: true,
    });
  });
}

export function forOrg<T extends { orgId: string }>(rows: T[], orgId: string): T[] {
  return rows.filter((r) => r.orgId === orgId);
}

export function assertOrgIsolation(orgId: string, resourceOrgId: string): void {
  if (orgId !== resourceOrgId) throw new Error("TENANT_ISOLATION_VIOLATION");
}

export function safeReadEnterpriseStore(): EnterpriseStoreData {
  try {
    return readEnterpriseStore();
  } catch {
    return structuredClone(EMPTY);
  }
}
