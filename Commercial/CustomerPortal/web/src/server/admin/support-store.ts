/**
 * Support console ticket store — commercial ops.
 * Durable via Upstash when configured (same pattern as licensing/billing).
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import { writeAudit } from "@/server/cloud/audit";
import { commercialDataRoot } from "@/server/cloud/data-root";
import {
  durableGet,
  durableSet,
  isDurableStoreConfigured,
  isDurableStoreRequired,
} from "@/server/cloud/cache";
import { isProductionRuntime } from "@/server/security/dev-bypass";

export type TicketPriority = "low" | "normal" | "high" | "urgent";
export type TicketStatus = "open" | "pending" | "resolved" | "closed";

export interface SupportTicket {
  id: string;
  customerEmail: string;
  subject: string;
  body: string;
  priority: TicketPriority;
  status: TicketStatus;
  assignee?: string;
  internalNotes: Array<{ at: string; by: string; note: string }>;
  kbLinks: string[];
  createdAt: string;
  updatedAt: string;
  resolution?: string;
  firstRespondedAt?: string;
  resolvedAt?: string;
  reopenedCount?: number;
}

interface SupportStore {
  version: 1;
  tickets: SupportTicket[];
}

const EMPTY: SupportStore = { version: 1, tickets: [] };
const ALGO = "aes-256-gcm";
const DURABLE_KEY = "tgm:support:store:v1";

function masterKey(): Buffer {
  const raw =
    process.env.SUPPORT_STORE_SECRET ||
    process.env.AUDIT_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-support-store";
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

function storePath(): string {
  const dir = process.env.SUPPORT_DATA_DIR || commercialDataRoot("support");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "tickets.enc");
}

let cache: SupportStore | null = null;
let writeChain: Promise<void> = Promise.resolve();
let loadPromise: Promise<void> | null = null;

function loadRawFromDisk(): SupportStore {
  const p = storePath();
  if (!fs.existsSync(p)) return structuredClone(EMPTY);
  try {
    const data = decryptJson<SupportStore>(fs.readFileSync(p, "utf8"));
    if (!Array.isArray(data.tickets)) data.tickets = [];
    return data;
  } catch {
    throw new Error("SUPPORT_STORE_DECRYPT_FAIL");
  }
}

export function assertDurableStoreForSupport(): void {
  if (isDurableStoreRequired() && !isDurableStoreConfigured()) {
    throw new Error(
      "DURABLE_STORE_REQUIRED: Set UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN so support tickets survive redeploys."
    );
  }
}

export async function ensureSupportStoreLoaded(): Promise<void> {
  if (cache) return;
  if (!loadPromise) {
    loadPromise = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(DURABLE_KEY);
          if (remote) {
            cache = decryptJson<SupportStore>(remote);
            if (!Array.isArray(cache.tickets)) cache.tickets = [];
            return;
          }
        } catch {
          /* fall through */
        }
      }
      cache = loadRawFromDisk();
      if (isDurableStoreConfigured() && cache.tickets.length > 0) {
        try {
          await durableSet(DURABLE_KEY, encryptJson(cache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      if (!cache) loadPromise = null;
    });
  }
  await loadPromise;
  if (!cache) cache = structuredClone(EMPTY);
}

function read(): SupportStore {
  if (cache) return cache;
  cache = loadRawFromDisk();
  return cache;
}

function write(data: SupportStore): void {
  assertDurableStoreForSupport();
  cache = data;
  if (data.tickets.length > 5000) data.tickets.length = 5000;
  const blob = encryptJson(data);
  writeChain = writeChain.then(async () => {
    try {
      fs.writeFileSync(storePath(), blob, "utf8");
    } catch {
      /* serverless may only have durable */
    }
    if (isDurableStoreConfigured()) {
      await durableSet(DURABLE_KEY, blob);
    }
  });
}

export async function flushSupportStore(): Promise<void> {
  await writeChain;
}

function id(): string {
  return `tkt_${Date.now().toString(36)}_${randomBytes(2).toString("hex")}`;
}

export function listSupportTickets(filter?: {
  status?: TicketStatus;
  assignee?: string;
  q?: string;
  customerEmail?: string;
}): SupportTicket[] {
  let rows = read().tickets;
  if (filter?.status) rows = rows.filter((t) => t.status === filter.status);
  if (filter?.assignee) rows = rows.filter((t) => t.assignee === filter.assignee);
  if (filter?.customerEmail) {
    const e = filter.customerEmail.toLowerCase();
    rows = rows.filter((t) => t.customerEmail === e);
  }
  if (filter?.q) {
    const q = filter.q.toLowerCase();
    rows = rows.filter(
      (t) =>
        t.subject.toLowerCase().includes(q) ||
        t.customerEmail.includes(q) ||
        t.id.includes(q)
    );
  }
  return rows;
}

export function createSupportTicket(input: {
  customerEmail: string;
  subject: string;
  body: string;
  priority?: TicketPriority;
}): SupportTicket {
  const subject = input.subject.trim().slice(0, 200);
  const body = input.body.trim().slice(0, 10000);
  if (!subject || !body) {
    throw new Error("SUPPORT_TICKET_VALIDATION: subject and body are required");
  }
  const data = structuredClone(read());
  const ticket: SupportTicket = {
    id: id(),
    customerEmail: input.customerEmail.toLowerCase(),
    subject,
    body,
    priority: input.priority || "normal",
    status: "open",
    internalNotes: [],
    kbLinks: ["/portal/knowledge-base"],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  data.tickets.unshift(ticket);
  write(data);
  writeAudit({
    user: input.customerEmail,
    action: "support_action",
    ip: "portal",
    result: "success",
    detail: `ticket created ${ticket.id}`,
    resource: ticket.id,
  });
  return ticket;
}

export function updateSupportTicket(
  ticketId: string,
  patch: Partial<Pick<SupportTicket, "status" | "priority" | "assignee" | "resolution">>,
  actor: string,
  note?: string
): SupportTicket | null {
  const data = structuredClone(read());
  const t = data.tickets.find((x) => x.id === ticketId);
  if (!t) return null;
  const prevStatus = t.status;
  if (patch.status) t.status = patch.status;
  if (patch.priority) t.priority = patch.priority;
  if (patch.assignee !== undefined) t.assignee = patch.assignee;
  if (patch.resolution) t.resolution = patch.resolution;
  if (note) {
    t.internalNotes.unshift({ at: new Date().toISOString(), by: actor, note });
  }
  if (!t.firstRespondedAt && (patch.assignee || note)) {
    t.firstRespondedAt = new Date().toISOString();
  }
  if (patch.status === "resolved" || patch.status === "closed") {
    t.resolvedAt = t.resolvedAt || new Date().toISOString();
  }
  if (
    (prevStatus === "resolved" || prevStatus === "closed") &&
    (patch.status === "open" || patch.status === "pending")
  ) {
    t.reopenedCount = (t.reopenedCount || 0) + 1;
    t.resolvedAt = undefined;
  }
  t.updatedAt = new Date().toISOString();
  write(data);
  writeAudit({
    user: actor,
    action: "support_action",
    ip: "admin",
    result: "success",
    detail: `ticket ${ticketId} updated`,
    resource: ticketId,
  });
  return t;
}

/** Dev/admin seed only — never called from customer Support page; blocked in production. */
export function ensureDemoTickets(): void {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_TICKETS !== "true") return;
  const data = read();
  if (data.tickets.length > 0) return;
  const t1 = createSupportTicket({
    customerEmail: "demo@goldmind.local",
    subject: "How do I activate my license?",
    body: "I purchased monthly but need activation steps.",
    priority: "normal",
  });
  updateSupportTicket(
    t1.id,
    { assignee: "support@rtas.local", status: "resolved", resolution: "Sent KB activation guide" },
    "support@rtas.local",
    "First response + resolved"
  );
  const t2 = createSupportTicket({
    customerEmail: "pro.trader@goldmind.local",
    subject: "Update failed checksum",
    body: "Updater reported checksum mismatch then rolled back.",
    priority: "high",
  });
  updateSupportTicket(
    t2.id,
    { assignee: "support@rtas.local", status: "pending" },
    "support@rtas.local",
    "Acknowledged — collecting package version"
  );
}

export function supportStoreDurability(): { durableConfigured: boolean; warning?: string } {
  const durableConfigured = isDurableStoreConfigured();
  return {
    durableConfigured,
    warning:
      isDurableStoreRequired() && !durableConfigured
        ? "Support tickets will not survive serverless redeploys until Upstash Redis is configured."
        : undefined,
  };
}
