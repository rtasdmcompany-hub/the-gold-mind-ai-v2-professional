/**
 * Support console ticket store — commercial ops.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import { writeAudit } from "@/server/cloud/audit";
import { commercialDataRoot } from "@/server/cloud/data-root";

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
  return path.join(dir, "tickets.enc");
}

let cache: SupportStore | null = null;

function read(): SupportStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<SupportStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.tickets)) cache.tickets = [];
  return cache;
}

function write(data: SupportStore): void {
  cache = data;
  if (data.tickets.length > 5000) data.tickets.length = 5000;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

function id(): string {
  return `tkt_${Date.now().toString(36)}_${randomBytes(2).toString("hex")}`;
}

export function listSupportTickets(filter?: {
  status?: TicketStatus;
  assignee?: string;
  q?: string;
}): SupportTicket[] {
  let rows = read().tickets;
  if (filter?.status) rows = rows.filter((t) => t.status === filter.status);
  if (filter?.assignee) rows = rows.filter((t) => t.assignee === filter.assignee);
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
  const data = structuredClone(read());
  const ticket: SupportTicket = {
    id: id(),
    customerEmail: input.customerEmail.toLowerCase(),
    subject: input.subject,
    body: input.body,
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
  // First response when assignee set or first note
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

export function ensureDemoTickets(): void {
  const data = read();
  if (data.tickets.length > 0) return;
  const t1 = createSupportTicket({
    customerEmail: "demo@goldmind.local",
    subject: "How do I activate my license?",
    body: "I purchased monthly but need activation steps.",
    priority: "normal",
  });
  updateSupportTicket(t1.id, { assignee: "support@rtas.local", status: "resolved", resolution: "Sent KB activation guide" }, "support@rtas.local", "First response + resolved");
  const t2 = createSupportTicket({
    customerEmail: "pro.trader@goldmind.local",
    subject: "Update failed checksum",
    body: "Updater reported checksum mismatch then rolled back.",
    priority: "high",
  });
  updateSupportTicket(t2.id, { assignee: "support@rtas.local", status: "pending" }, "support@rtas.local", "Acknowledged — collecting package version");
}
