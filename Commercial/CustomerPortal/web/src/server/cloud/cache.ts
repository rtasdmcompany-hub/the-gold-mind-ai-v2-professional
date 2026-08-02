import { product } from "@/lib/product";
/**
 * Enterprise cache — Upstash Redis REST when configured, memory fallback otherwise.
 * Used for: session hints · rate limiting · config · performance.
 * Commercial layer only — Trading Engine never depends on this cache.
 */

type CacheEntry = { value: string; expiresAt: number };

const memory = new Map<string, CacheEntry>();

function now(): number {
  return Date.now();
}

function memoryGet(key: string): string | null {
  const e = memory.get(key);
  if (!e) return null;
  if (e.expiresAt < now()) {
    memory.delete(key);
    return null;
  }
  return e.value;
}

function memorySet(key: string, value: string, ttlSec: number): void {
  memory.set(key, { value, expiresAt: now() + ttlSec * 1000 });
  // Cap memory map
  if (memory.size > 5000) {
    const first = memory.keys().next().value;
    if (first) memory.delete(first);
  }
}

function memoryDel(key: string): void {
  memory.delete(key);
}

function isUsableEnvValue(raw: string | undefined): boolean {
  const v = (raw || "").trim();
  if (!v) return false;
  const lower = v.toLowerCase();
  if (
    lower === "replace_if_available" ||
    lower === "changeme" ||
    lower === "your_token_here" ||
    lower === "todo" ||
    lower.startsWith("replace_")
  ) {
    return false;
  }
  return true;
}

function upstashConfigured(): boolean {
  const url = (process.env.UPSTASH_REDIS_REST_URL || "").trim();
  const token = (process.env.UPSTASH_REDIS_REST_TOKEN || "").trim();
  if (!isUsableEnvValue(url) || !isUsableEnvValue(token)) return false;
  // Real Upstash REST endpoints are https://*.upstash.io
  if (!/^https:\/\/[a-z0-9.-]+\.upstash\.io\/?/i.test(url)) return false;
  return true;
}

export function getCacheBackend(): "upstash" | "memory" {
  return upstashConfigured() ? "upstash" : "memory";
}

async function upstashCommand(args: (string | number)[]): Promise<unknown> {
  const url = process.env.UPSTASH_REDIS_REST_URL!;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN!;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(args),
  });
  if (!res.ok) throw new Error(`UPSTASH_${res.status}`);
  const json = (await res.json()) as { result?: unknown };
  return json.result;
}

export async function cacheGet(key: string): Promise<string | null> {
  if (!upstashConfigured()) return memoryGet(key);
  try {
    const result = await upstashCommand(["GET", key]);
    return result == null ? null : String(result);
  } catch {
    return memoryGet(key);
  }
}

export async function cacheSet(key: string, value: string, ttlSec = 300): Promise<void> {
  if (!upstashConfigured()) {
    memorySet(key, value, ttlSec);
    return;
  }
  try {
    await upstashCommand(["SET", key, value, "EX", ttlSec]);
  } catch {
    memorySet(key, value, ttlSec);
  }
}

export async function cacheDel(key: string): Promise<void> {
  if (!upstashConfigured()) {
    memoryDel(key);
    return;
  }
  try {
    await upstashCommand(["DEL", key]);
  } catch {
    memoryDel(key);
  }
}

/** Permanent Redis GET (no TTL). Used for licensing / commercial durable state on Vercel. */
export async function durableGet(key: string): Promise<string | null> {
  if (!upstashConfigured()) return null;
  try {
    const result = await upstashCommand(["GET", key]);
    return result == null ? null : String(result);
  } catch {
    return null;
  }
}

/** Permanent Redis SET (no expiry). Survives serverless cold starts when Upstash is configured. */
export async function durableSet(key: string, value: string): Promise<void> {
  if (!upstashConfigured()) return;
  await upstashCommand(["SET", key, value]);
}

export function isDurableStoreConfigured(): boolean {
  return upstashConfigured();
}

/** Production/Vercel must persist licenses across cold starts — otherwise activation is "in the air". */
export function isDurableStoreRequired(): boolean {
  return !!(process.env.VERCEL || process.env.COMMERCIAL_REQUIRE_DURABLE_LICENSE === "true");
}

export function assertDurableStoreForLicensing(): void {
  if (isDurableStoreRequired() && !isDurableStoreConfigured()) {
    throw new Error(
      "DURABLE_STORE_REQUIRED: Set UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN on Vercel so license keys survive redeploys. Without this, install activation cannot be guaranteed."
    );
  }
}

/** Public readiness for {product.installer.name} /api/licenses/ready */
export function licensingStoreReadiness(): {
  ready: boolean;
  durableConfigured: boolean;
  durableRequired: boolean;
  detail: string;
} {
  const durableConfigured = isDurableStoreConfigured();
  const durableRequired = isDurableStoreRequired();
  const ready = !durableRequired || durableConfigured;
  return {
    ready,
    durableConfigured,
    durableRequired,
    detail: ready
      ? durableConfigured
        ? "Durable licensing store ready (Upstash)"
        : "Local licensing store ready (durable not required)"
      : "DURABLE_STORE_REQUIRED: configure UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN",
  };
}

export async function cacheIncr(key: string, ttlSec = 60): Promise<number> {
  if (!upstashConfigured()) {
    const cur = Number(memoryGet(key) || "0") + 1;
    memorySet(key, String(cur), ttlSec);
    return cur;
  }
  try {
    const n = Number(await upstashCommand(["INCR", key]));
    if (n === 1) await upstashCommand(["EXPIRE", key, ttlSec]);
    return n;
  } catch {
    const cur = Number(memoryGet(key) || "0") + 1;
    memorySet(key, String(cur), ttlSec);
    return cur;
  }
}

/** Invalidate by exact key or prefix (memory scans; Upstash deletes exact key only unless KEYS allowed). */
export async function cacheInvalidate(keyOrPrefix: string): Promise<void> {
  if (keyOrPrefix.endsWith("*")) {
    const prefix = keyOrPrefix.slice(0, -1);
    for (const k of [...memory.keys()]) {
      if (k.startsWith(prefix)) memory.delete(k);
    }
    return;
  }
  await cacheDel(keyOrPrefix);
}

export const CacheKeys = {
  session: (email: string) => `tgm:session:${email}`,
  rateLimit: (bucket: string) => `tgm:rl:${bucket}`,
  config: (name: string) => `tgm:cfg:${name}`,
  perf: (name: string) => `tgm:perf:${name}`,
  bruteForce: (email: string) => `tgm:bf:${email}`,
} as const;
