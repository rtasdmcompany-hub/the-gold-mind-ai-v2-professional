/**
 * Public API gateway wrapper — API key / Bearer token auth for /api/v1/*.
 */
import { NextResponse } from "next/server";
import { apiError, apiSuccess, newRequestId } from "@/server/cloud/gateway";
import { clientIpFromHeaders } from "@/server/cloud/audit";
import { resolveAccessToken, resolveApiKey, keyHasScope } from "./keys";
import type { ApiScope } from "./types";
import { API_PLATFORM_VERSION, API_CORE_ISOLATION } from "./types";
import {
  checkIpAllowlist,
  detectAbuse,
  enforceTls,
  isForbiddenPath,
} from "./security";
import { checkPlatformRateLimit, logApiUsage } from "./usage";

export interface PublicApiContext {
  requestId: string;
  ip: string;
  email: string;
  apiKeyId: string;
  scopes: ApiScope[];
  version: string;
}

function extractCredential(req: Request): string | null {
  const h = req.headers.get("authorization") || "";
  const m = /^Bearer\s+(.+)$/i.exec(h.trim());
  if (m) return m[1].trim();
  const key = req.headers.get("x-api-key");
  return key?.trim() || null;
}

export async function withPublicApi(
  req: Request,
  opts: { scope: ApiScope; rateLimit?: number },
  handler: (ctx: PublicApiContext) => Promise<NextResponse>
): Promise<NextResponse> {
  const started = Date.now();
  const requestId = newRequestId();
  const ip = clientIpFromHeaders(req.headers);
  const path = new URL(req.url).pathname;

  if (isForbiddenPath(path)) {
    logApiUsage({
      method: req.method,
      path,
      status: 404,
      requestId,
      ip,
      latencyMs: Date.now() - started,
      errorCode: "FORBIDDEN_TOPIC",
    });
    return apiError("NOT_FOUND", "Resource not found", 404, requestId);
  }

  if (!enforceTls(req)) {
    return apiError("TLS_REQUIRED", "HTTPS required", 403, requestId);
  }

  const cred = extractCredential(req);
  if (!cred) {
    return apiError("UNAUTHORIZED", "Missing API key or Bearer token", 401, requestId);
  }

  let email = "";
  let apiKeyId = "";
  let scopes: ApiScope[] = [];
  let rateLimit = opts.rateLimit || 120;

  if (cred.startsWith("tgm_atk_")) {
    const token = resolveAccessToken(cred);
    if (!token) return apiError("UNAUTHORIZED", "Invalid or expired access token", 401, requestId);
    email = token.ownerEmail;
    apiKeyId = token.apiKeyId;
    scopes = token.scopes;
  } else {
    const key = resolveApiKey(cred);
    if (!key) return apiError("UNAUTHORIZED", "Invalid API key", 401, requestId);
    if (!checkIpAllowlist(key.ipAllowlist, ip)) {
      return apiError("IP_DENIED", "IP not allowlisted for this key", 403, requestId);
    }
    email = key.ownerEmail;
    apiKeyId = key.id;
    scopes = key.scopes;
    rateLimit = key.rateLimitPerMin;
  }

  if (!keyHasScope({ scopes }, opts.scope)) {
    logApiUsage({
      apiKeyId,
      ownerEmail: email,
      method: req.method,
      path,
      status: 403,
      requestId,
      ip,
      latencyMs: Date.now() - started,
      errorCode: "SCOPE_DENIED",
    });
    return apiError("FORBIDDEN", `Missing scope ${opts.scope}`, 403, requestId);
  }

  const rl = checkPlatformRateLimit(`${apiKeyId}:${path}`, rateLimit);
  if (!rl.ok) {
    logApiUsage({
      apiKeyId,
      ownerEmail: email,
      method: req.method,
      path,
      status: 429,
      requestId,
      ip,
      latencyMs: Date.now() - started,
      errorCode: "RATE_LIMITED",
    });
    return apiError("RATE_LIMITED", "Rate limit exceeded", 429, requestId);
  }

  if (detectAbuse(apiKeyId, 200)) {
    return apiError("ABUSE_DETECTED", "Temporarily blocked due to abuse signals", 429, requestId);
  }

  try {
    const res = await handler({
      requestId,
      ip,
      email,
      apiKeyId,
      scopes,
      version: API_PLATFORM_VERSION,
    });
    logApiUsage({
      apiKeyId,
      ownerEmail: email,
      method: req.method,
      path,
      status: res.status,
      requestId,
      ip,
      latencyMs: Date.now() - started,
    });
    res.headers.set("X-TGM-API-Version", API_PLATFORM_VERSION);
    res.headers.set("X-TGM-Core-Isolation", "commercial-only");
    return res;
  } catch (e) {
    const msg = e instanceof Error ? e.message : "INTERNAL";
    logApiUsage({
      apiKeyId,
      ownerEmail: email,
      method: req.method,
      path,
      status: 500,
      requestId,
      ip,
      latencyMs: Date.now() - started,
      errorCode: msg,
    });
    return apiError("INTERNAL", msg, 500, requestId);
  }
}

export function publicApiMeta() {
  return {
    version: API_PLATFORM_VERSION,
    isolation: API_CORE_ISOLATION,
    basePath: "/api/v1",
  };
}

export { apiSuccess, apiError };
