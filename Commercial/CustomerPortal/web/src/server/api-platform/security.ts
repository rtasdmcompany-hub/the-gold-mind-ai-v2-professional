/**
 * API platform security — TLS, signing, abuse, forbidden topics.
 */
import { createHmac } from "crypto";
import { FORBIDDEN_API_TOPICS, API_CORE_ISOLATION } from "./types";
import { readApiStore, writeApiStore, newApiId } from "./store";

export function isForbiddenPath(pathname: string): boolean {
  const p = pathname.toLowerCase();
  return FORBIDDEN_API_TOPICS.some((t) => p.includes(t));
}

export function enforceTls(req: Request): boolean {
  const proto = req.headers.get("x-forwarded-proto") || "";
  const host = req.headers.get("host") || "";
  if (host.includes("localhost") || host.startsWith("127.")) return true;
  if (proto && proto !== "https") return false;
  return true;
}

export function signRequestBody(secret: string, body: string, timestamp: string): string {
  return createHmac("sha256", secret).update(`${timestamp}.${body}`).digest("hex");
}

export function verifyRequestSignature(
  secret: string,
  body: string,
  timestamp: string,
  signature: string
): boolean {
  const expected = signRequestBody(secret, body, timestamp);
  return expected === signature;
}

export function checkIpAllowlist(allowlist: string[], ip: string): boolean {
  if (!allowlist.length) return true;
  return allowlist.includes(ip) || allowlist.includes("*");
}

export function detectAbuse(apiKeyId: string, status: number): boolean {
  void status;
  const store = readApiStore();
  const recent = store.usage.filter(
    (u) => u.apiKeyId === apiKeyId && Date.now() - new Date(u.at).getTime() < 60_000
  );
  const errors = recent.filter((u) => u.status >= 400).length;
  const abusive = recent.length > 200 || errors > 50;
  if (abusive) {
    store.errors.unshift({
      id: newApiId("err"),
      at: new Date().toISOString(),
      code: "ABUSE_DETECTED",
      path: "gateway",
      requestId: `abuse_${apiKeyId}`,
      detail: `key=${apiKeyId} req/min=${recent.length} errors=${errors}`,
    });
    writeApiStore(store);
  }
  return abusive;
}

export function securityPolicy() {
  return {
    oauth2: "client_credentials + refresh",
    apiKeys: "tgm_live_* hashed at rest",
    tokenRotation: true,
    requestSigning: "HMAC-SHA256 timestamp.body",
    tlsEnforcement: true,
    rateLimits: true,
    ipRestrictions: "optional per key",
    auditLogs: true,
    securityMonitoring: true,
    abuseDetection: true,
    coreIsolation: API_CORE_ISOLATION,
    tradingForbidden: true,
    forbiddenTopics: [...FORBIDDEN_API_TOPICS],
  };
}
