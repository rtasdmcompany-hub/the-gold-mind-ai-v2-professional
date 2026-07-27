/**
 * Encrypted AI assistant store — conversations, feedback, audit, unanswered.
 */
import fs from "fs";
import path from "path";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "crypto";
import { commercialDataRoot } from "@/server/cloud/data-root";
import type {
  AiAuditEntry,
  AiFeedback,
  Conversation,
  KnowledgeDocument,
  UnansweredQuestion,
} from "./types";

const ALGO = "aes-256-gcm";

function masterKey(): Buffer {
  const raw =
    process.env.AI_STORE_SECRET ||
    process.env.PHASE11_STORE_SECRET ||
    process.env.NEXTAUTH_SECRET ||
    "dev-ai-store";
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

export interface AiStore {
  version: 1;
  conversations: Conversation[];
  feedback: AiFeedback[];
  audit: AiAuditEntry[];
  unanswered: UnansweredQuestion[];
  knowledge: KnowledgeDocument[];
  rateBuckets: Record<string, { count: number; windowStart: number }>;
}

const EMPTY: AiStore = {
  version: 1,
  conversations: [],
  feedback: [],
  audit: [],
  unanswered: [],
  knowledge: [],
  rateBuckets: {},
};

let cache: AiStore | null = null;

function storePath(): string {
  const dir = commercialDataRoot("ai-assistant");
  return path.join(dir, "assistant.enc");
}

export function readAiStore(): AiStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  try {
    cache = decryptJson<AiStore>(fs.readFileSync(p, "utf8"));
  } catch {
    cache = structuredClone(EMPTY);
  }
  for (const k of Object.keys(EMPTY) as (keyof AiStore)[]) {
    if (cache[k] === undefined) (cache as unknown as Record<string, unknown>)[k] = structuredClone(EMPTY[k]);
  }
  return cache;
}

export function writeAiStore(data: AiStore): void {
  if (data.conversations.length > 500) data.conversations = data.conversations.slice(0, 500);
  if (data.audit.length > 2000) data.audit = data.audit.slice(0, 2000);
  if (data.feedback.length > 1000) data.feedback = data.feedback.slice(0, 1000);
  if (data.unanswered.length > 500) data.unanswered = data.unanswered.slice(0, 500);
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

export function newAiId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(3).toString("hex")}`;
}

export function appendAiAudit(entry: Omit<AiAuditEntry, "id" | "at">): AiAuditEntry {
  const store = readAiStore();
  const row: AiAuditEntry = {
    ...entry,
    id: newAiId("aia"),
    at: new Date().toISOString(),
  };
  store.audit.unshift(row);
  writeAiStore(store);
  return row;
}
