import { createClient } from "@supabase/supabase-js";

// Memory cache fallback
const memoryCache = new Map<string, { value: string; expiresAt: number }>();

function isUsableEnvValue(val: string): boolean {
  return val.length > 10 && !val.includes("your-") && !val.includes("change-me");
}

function upstashConfigured(): boolean {
  const url = (process.env.UPSTASH_REDIS_REST_URL || "").trim();
  const token = (process.env.UPSTASH_REDIS_REST_TOKEN || "").trim();
  if (!isUsableEnvValue(url) || !isUsableEnvValue(token)) return false;
  if (!/^https:\/\/[a-z0-9.-]+\.upstash\.io\/?/i.test(url)) return false;
  return true;
}

function supabaseConfigured(): boolean {
  const url = (process.env.NEXT_PUBLIC_SUPABASE_URL || "").trim();
  const key = (process.env.SUPABASE_SERVICE_ROLE_KEY || "").trim();
  return isUsableEnvValue(url) && isUsableEnvValue(key);
}

let supabaseClient: any = null;
function getSupabaseClient() {
  if (!supabaseClient && supabaseConfigured()) {
    supabaseClient = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );
  }
  return supabaseClient;
}

export function getCacheBackend(): "upstash" | "supabase" | "memory" {
  if (upstashConfigured()) return "upstash";
  if (supabaseConfigured()) return "supabase";
  return "memory";
}

export function isDurableStoreConfigured(): boolean {
  // FIX: Ab ye Upstash YA Supabase dono mein se kisi ek ko accept karega
  return upstashConfigured() || supabaseConfigured();
}

export function isDurableStoreRequired(): boolean {
  return !!(process.env.VERCEL || process.env.COMMERCIAL_REQUIRE_DURABLE_LICENSE === "true");
}

export function assertDurableStoreForLicensing(): void {
  // FIX: Ab ye error tab hi throw hoga jab Upstash AUR Supabase dono missing hon
  if (isDurableStoreRequired() && !isDurableStoreConfigured()) {
    throw new Error(
      "DURABLE_STORE_REQUIRED: Please configure either Upstash Redis OR Supabase environment variables on Vercel so license keys survive redeploys."
    );
  }
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

export async function durableGet(key: string): Promise<string | null> {
  if (upstashConfigured()) {
    try {
      const result = await upstashCommand(["GET", key]);
      return result == null ? null : String(result);
    } catch {
      return null;
    }
  }
  
  // Supabase Fallback
  if (supabaseConfigured()) {
    try {
      const { data, error } = await getSupabaseClient()
        .from("durable_cache")
        .select("value")
        .eq("key", key)
        .single();
      if (error || !data) return null;
      return data.value;
    } catch {
      return null;
    }
  }
  
  return null;
}

export async function durableSet(key: string, value: string): Promise<void> {
  if (upstashConfigured()) {
    await upstashCommand(["SET", key, value]);
    return;
  }

  // Supabase Fallback
  if (supabaseConfigured()) {
    try {
      await getSupabaseClient()
        .from("durable_cache")
        .upsert({ key, value }, { onConflict: "key" });
    } catch {
      // Non-fatal fallback
    }
  }
}

// ... (باقی میموری کیچ فنکشنز جیسے کے تھے ویسے ہی رہیں گے) ...
export function memoryGet(key: string): string | null {
  const item = memoryCache.get(key);
  if (!item) return null;
  if (Date.now() > item.expiresAt) {
    memoryCache.delete(key);
    return null;
  }
  return item.value;
}

export function memorySet(key: string, value: string, ttlSec = 300): void {
  memoryCache.set(key, { value, expiresAt: Date.now() + ttlSec * 1000 });
}

export function memoryDel(key: string): void {
  memoryCache.delete(key);
}