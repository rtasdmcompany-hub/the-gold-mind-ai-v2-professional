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

/** Upstash Redis REST, or Vercel KV (same REST shape via KV_REST_API_*). */
function redisRestUrl(): string {
  return (
    (process.env.UPSTASH_REDIS_REST_URL || "").trim() ||
    (process.env.KV_REST_API_URL || "").trim() ||
    (process.env.LICENSING_DURABLE_URL || "").trim()
  );
}

function redisRestToken(): string {
  return (
    (process.env.UPSTASH_REDIS_REST_TOKEN || "").trim() ||
    (process.env.KV_REST_API_TOKEN || "").trim() ||
    (process.env.LICENSING_DURABLE_TOKEN || "").trim()
  );
}

function upstashConfigured(): boolean {
  return !!(redisRestUrl() && redisRestToken());
}

export function getCacheBackend(): "upstash" | "memory" {
  return upstashConfigured() ? "upstash" : "memory";
}

async function upstashCommand(args: (string | number)[]): Promise<unknown> {
  const url = redisRestUrl();
  const token = redisRestToken();
  if (!url || !token) throw new Error("DURABLE_STORE_NOT_CONFIGURED");
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

function blobToken(): string {
  return (process.env.BLOB_READ_WRITE_TOKEN || "").trim();
}

function blobConfigured(): boolean {
  return !!blobToken();
}

function blobPathname(key: string): string {
  const safe = key.replace(/[^a-zA-Z0-9._:-]/g, "_");
  return `tgm-durable/${safe}.txt`;
}

async function blobGet(key: string): Promise<string | null> {
  const token = blobToken();
  if (!token) return null;
  const listRes = await fetch(
    `https://blob.vercel-storage.com?prefix=${encodeURIComponent(blobPathname(key))}`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  if (!listRes.ok) return null;
  const listed = (await listRes.json()) as { blobs?: { url: string; pathname: string }[] };
  const hit = (listed.blobs || []).find((b) => b.pathname === blobPathname(key));
  if (!hit?.url) return null;
  const getRes = await fetch(hit.url, { cache: "no-store" });
  if (!getRes.ok) return null;
  return getRes.text();
}

async function blobSet(key: string, value: string): Promise<void> {
  const token = blobToken();
  if (!token) throw new Error("BLOB_NOT_CONFIGURED");
  const res = await fetch(`https://blob.vercel-storage.com/${blobPathname(key)}`, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${token}`,
      "x-vercel-blob-access": "public",
      "Content-Type": "text/plain; charset=utf-8",
    },
    body: value,
  });
  if (!res.ok) throw new Error(`BLOB_${res.status}`);
}

/** Permanent GET — Redis/KV first, then Vercel Blob. Survives serverless cold starts. */
export async function durableGet(key: string): Promise<string | null> {
  if (upstashConfigured()) {
    try {
      const result = await upstashCommand(["GET", key]);
      if (result != null) return String(result);
    } catch {
      /* try blob */
    }
  }
  if (blobConfigured()) {
    try {
      return await blobGet(key);
    } catch {
      return null;
    }
  }
  return null;
}

/** Permanent SET — Redis/KV first, else Vercel Blob. */
export async function durableSet(key: string, value: string): Promise<void> {
  if (upstashConfigured()) {
    await upstashCommand(["SET", key, value]);
    return;
  }
  if (blobConfigured()) {
    await blobSet(key, value);
    return;
  }
}

export function isDurableStoreConfigured(): boolean {
  return upstashConfigured() || blobConfigured();
}

/**
 * Durable store is required when explicitly forced, or on Vercel once Upstash/KV/Blob is configured.
 * Without a durable backend, Setup may still activate into /tmp (ephemeral across cold starts) —
 * readiness stays true so install is not hard-blocked while owner wires Redis/Blob.
 */
export function isDurableStoreRequired(): boolean {
  if (process.env.COMMERCIAL_REQUIRE_DURABLE_LICENSE === "true") return true;
  if (process.env.COMMERCIAL_REQUIRE_DURABLE_LICENSE === "false") return false;
  // Only hard-require when a backend is already configured (prevents half-broken dual writes)
  return false;
}

export function assertDurableStoreForLicensing(): void {
  if (isDurableStoreRequired() && !isDurableStoreConfigured()) {
    throw new Error(
      "DURABLE_STORE_REQUIRED: Set UPSTASH_REDIS_REST_URL + UPSTASH_REDIS_REST_TOKEN, or KV_REST_API_*, or BLOB_READ_WRITE_TOKEN on Vercel so license keys survive redeploys."
    );
  }
}

/** Public readiness for Setup.exe — must be ready before install can activate a key. */
export function licensingStoreReadiness(): {
  ready: boolean;
  durable: boolean;
  required: boolean;
  backend: "upstash" | "blob" | "memory" | "none";
  message: string;
} {
  const durable = isDurableStoreConfigured();
  const required = isDurableStoreRequired();
  const ready = !required || durable;
  const backend: "upstash" | "blob" | "memory" | "none" = upstashConfigured()
    ? "upstash"
    : blobConfigured()
      ? "blob"
      : "memory";
  return {
    ready,
    durable,
    required,
    backend,
    message: durable
      ? "License store ready (durable) — installer may activate keys."
      : ready
        ? "License store ready (ephemeral memory/tmp) — installer may activate; set UPSTASH/KV/BLOB for persistence across redeploys."
        : "DURABLE_STORE_REQUIRED: Configure Upstash Redis, Vercel KV, or Vercel Blob on production before customers can activate licenses during Setup.",
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
