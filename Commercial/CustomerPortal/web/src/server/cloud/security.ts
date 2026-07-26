/**
 * Node-runtime cloud security — brute force · secrets · output encoding.
 * Import from Route Handlers / auth — NOT from Edge middleware.
 */
import { cacheGet, cacheIncr, cacheDel, CacheKeys } from "./cache";
import { writeAudit } from "./audit";
export {
  applySecurityHeaders,
  applyCors,
  enforceHttps,
  checkCsrf,
} from "./security-headers";

const BRUTE_LIMIT = Number(process.env.AUTH_BRUTE_FORCE_LIMIT || 8);
const BRUTE_WINDOW = Number(process.env.AUTH_BRUTE_FORCE_WINDOW_SEC || 900);

export async function recordLoginFailure(email: string, ip: string): Promise<boolean> {
  const key = CacheKeys.bruteForce(email.toLowerCase());
  const n = await cacheIncr(key, BRUTE_WINDOW);
  writeAudit({
    user: email,
    action: "login_failed",
    ip,
    result: "failure",
    detail: `attempt ${n}`,
  });
  return n >= BRUTE_LIMIT;
}

export async function isLoginBlocked(email: string): Promise<boolean> {
  const n = Number((await cacheGet(CacheKeys.bruteForce(email.toLowerCase()))) || "0");
  return n >= BRUTE_LIMIT;
}

export async function clearLoginFailures(email: string): Promise<void> {
  await cacheDel(CacheKeys.bruteForce(email.toLowerCase()));
}

export function encodeOutput(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export function validateSecretsPresent(): { ok: boolean; missing: string[] } {
  const required = ["NEXTAUTH_SECRET"];
  const recommended = ["LICENSE_STORE_SECRET", "BILLING_STORE_SECRET", "AUDIT_STORE_SECRET"];
  const missing: string[] = [];
  for (const k of required) {
    if (!process.env[k]) missing.push(k);
  }
  for (const k of recommended) {
    if (!process.env[k] && process.env.NODE_ENV === "production") missing.push(k);
  }
  return { ok: missing.length === 0, missing };
}
