import { createClient } from "@supabase/supabase-js";

// ✅ Table ka structure define kiya
type CacheRow = {
  key: string;
  value: string;
};

// ✅ Safe result type for Supabase queries
type SupabaseResult<T> = {
  data: T | null;
  error: unknown;
};

// ✅ Safe Supabase Table Builder (Bina 'any' ke, 100% ESLint compliant)
type SafeSupabaseTable = {
  select: (columns?: string) => {
    eq: (column: string, value: unknown) => {
      single: () => Promise<SupabaseResult<CacheRow>>;
    };
  };
  upsert: (payload: CacheRow, options?: { onConflict?: string }) => Promise<{ error: unknown }>;
  delete: () => {
    eq: (column: string, value: unknown) => Promise<{ error: unknown }>;
  };
};

// ✅ Safe Supabase Client Type
type SafeSupabaseClient = {
  from: (table: string) => SafeSupabaseTable;
};

// ✅ BULLETPROOF CACHEKEYS (Ab is mein bruteForce bhi shamil hai)
export const CacheKeys = {
  LICENSE_STORE: "tgm:license:store:v1",
  SUPPORT_STORE: "tgm:support:store:v1",
  BILLING_STORE: "tgm:billing:store:v1",
  AUDIT_STORE: "tgm:audit:store:v1",
  SESSION_PREFIX: "tgm:session:",
  DEVICE_PREFIX: "tgm:device:",
  CLOUD_METRICS: "tgm:cloud:metrics",
  MONITORING_PREFIX: "tgm:monitoring:",
  SECURITY_PREFIX: "tgm:security:",
  ACCOUNT_PREFIX: "tgm:account:",
  PERFORMANCE_PREFIX: "tgm:performance:",
  RELEASES_PREFIX: "tgm:releases:",
  TRADING_PREFIX: "tgm:trading:",
  PARTNER_PREFIX: "tgm:partner:",
  ENTERPRISE_PREFIX: "tgm:enterprise:",
  CLOSURE_PREFIX: "tgm:closure:",
  AI_ASSISTANT_PREFIX: "tgm:ai-assistant:",
  API_PLATFORM_PREFIX: "tgm:api-platform:",
  MARKET_PREFIX: "tgm:market:",
  MOBILE_PREFIX: "tgm:mobile:",
  OBSERVABILITY_PREFIX: "tgm:observability:",
  OPS_PREFIX: "tgm:ops:",
  PHASE11_PREFIX: "tgm:phase11:",
  PHASE12_PREFIX: "tgm:phase12:",
  WEBSITE_LAUNCH_PREFIX: "tgm:website-launch:",
  REGIONAL_PREFIX: "tgm:regional:",
  WORKFLOW_PREFIX: "tgm:workflow:",
  BETA_PREFIX: "tgm:beta:",
  FEEDBACK_PREFIX: "tgm:feedback:",
  INCIDENT_PREFIX: "tgm:incident:",
  ISSUE_PREFIX: "tgm:issue:",
  METRICS_PREFIX: "tgm:metrics:",
  COMPANION_PREFIX: "tgm:companion:",
  ALERT_PREFIX: "tgm:alert:",
  TELEMETRY_PREFIX: "tgm:telemetry:",
  USAGE_PREFIX: "tgm:usage:",
  RUNS_PREFIX: "tgm:runs:",
  
  session: (email: string) => `tgm:session:${email}`,
  rateLimit: (action: string) => `tgm:ratelimit:${action}`,
  perf: (action: string) => `tgm:perf:${action}`,
  audit: (action: string) => `tgm:audit:${action}`,
  monitor: (action: string) => `tgm:monitor:${action}`,
  bruteForce: (email: string) => `tgm:bruteforce:${email}`, // ✅ YE NAYA ADD KIYA GAYA HAI
} as const;

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

type SupabaseClient = ReturnType<typeof createClient>;
let supabaseClient: SupabaseClient | null = null;

function getSupabaseClient(): SupabaseClient | null {
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
  return upstashConfigured() || supabaseConfigured();
}

export function isDurableStoreRequired(): boolean {
  return !!(process.env.VERCEL || process.env.COMMERCIAL_REQUIRE_DURABLE_LICENSE === "true");
}

export function assertDurableStoreForLicensing(): void {
  if (isDurableStoreRequired() && !isDurableStoreConfigured()) {
    throw new Error(
      "DURABLE_STORE_REQUIRED: Please configure either Upstash Redis OR Supabase environment variables on Vercel so license keys survive redeploys."
    );
  }
}

export function licensingStoreReadiness(): {
  ready: boolean;
  durableConfigured: boolean;
  warning?: string;
} {
  const durableConfigured = isDurableStoreConfigured();
  return {
    ready: durableConfigured,
    durableConfigured,
    warning:
      isDurableStoreRequired() && !durableConfigured
        ? "License store requires durable storage. Configure Upstash Redis or Supabase."
        : undefined,
  };
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
  
  if (supabaseConfigured()) {
    try {
      const client = getSupabaseClient();
      if (!client) return null;
      
      const safeClient = client as unknown as SafeSupabaseClient;
      const result = await safeClient
        .from("durable_cache")
        .select("value")
        .eq("key", key)
        .single();
        
      if (result.error || !result.data) return null;
      return result.data.value;
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

  if (supabaseConfigured()) {
    try {
      const client = getSupabaseClient();
      if (!client) return;
      
      const safeClient = client as unknown as SafeSupabaseClient;
      await safeClient
        .from("durable_cache")
        .upsert({ key, value }, { onConflict: "key" });
    } catch {
      // Non-fatal fallback
    }
  }
}

export async function cacheIncr(key: string, ttlSec = 300): Promise<number> {
  if (upstashConfigured()) {
    try {
      const result = await upstashCommand(["INCR", key]);
      return Number(result);
    } catch {
      return memoryIncr(key, ttlSec);
    }
  }

  if (supabaseConfigured()) {
    try {
      const client = getSupabaseClient();
      if (!client) return memoryIncr(key, ttlSec);
      
      const safeClient = client as unknown as SafeSupabaseClient;
      const result = await safeClient
        .from("durable_cache")
        .select("value")
        .eq("key", key)
        .single();
      
      let currentVal = 0;
      if (!result.error && result.data) {
        currentVal = parseInt(result.data.value, 10) || 0;
      }
      
      const newVal = currentVal + 1;
      await safeClient
        .from("durable_cache")
        .upsert({ key, value: String(newVal) }, { onConflict: "key" });
      
      return newVal;
    } catch {
      return memoryIncr(key, ttlSec);
    }
  }

  return memoryIncr(key, ttlSec);
}

function memoryIncr(key: string, ttlSec = 300): number {
  const item = memoryCache.get(key);
  let currentVal = 0;
  if (item && Date.now() <= item.expiresAt) {
    currentVal = parseInt(item.value, 10) || 0;
  }
  const newVal = currentVal + 1;
  memoryCache.set(key, { value: String(newVal), expiresAt: Date.now() + ttlSec * 1000 });
  return newVal;
}

export async function cacheGet(key: string): Promise<string | null> {
  if (!upstashConfigured() && !supabaseConfigured()) return memoryGet(key);
  
  if (upstashConfigured()) {
    try {
      const result = await upstashCommand(["GET", key]);
      return result == null ? null : String(result);
    } catch {
      return memoryGet(key);
    }
  }

  if (supabaseConfigured()) {
    try {
      const client = getSupabaseClient();
      if (!client) return memoryGet(key);
      
      const safeClient = client as unknown as SafeSupabaseClient;
      const result = await safeClient
        .from("durable_cache")
        .select("value")
        .eq("key", key)
        .single();
        
      if (result.error || !result.data) return memoryGet(key);
      return result.data.value;
    } catch {
      return memoryGet(key);
    }
  }
  
  return memoryGet(key);
}

export async function cacheSet(key: string, value: string, ttlSec = 300): Promise<void> {
  if (!upstashConfigured() && !supabaseConfigured()) {
    memorySet(key, value, ttlSec);
    return;
  }
  
  if (upstashConfigured()) {
    try {
      await upstashCommand(["SET", key, value, "EX", ttlSec]);
    } catch {
      memorySet(key, value, ttlSec);
    }
    return;
  }

  if (supabaseConfigured()) {
    try {
      const client = getSupabaseClient();
      if (!client) {
        memorySet(key, value, ttlSec);
        return;
      }
      
      const safeClient = client as unknown as SafeSupabaseClient;
      await safeClient
        .from("durable_cache")
        .upsert({ key, value }, { onConflict: "key" });
    } catch {
      memorySet(key, value, ttlSec);
    }
  }
}

export async function cacheDel(key: string): Promise<void> {
  if (!upstashConfigured() && !supabaseConfigured()) {
    memoryDel(key);
    return;
  }
  
  if (upstashConfigured()) {
    try {
      await upstashCommand(["DEL", key]);
    } catch {
      memoryDel(key);
    }
    return;
  }

  if (supabaseConfigured()) {
    try {
      const client = getSupabaseClient();
      if (!client) {
        memoryDel(key);
        return;
      }
      
      const safeClient = client as unknown as SafeSupabaseClient;
      await safeClient.from("durable_cache").delete().eq("key", key);
    } catch {
      memoryDel(key);
    }
  }
}

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