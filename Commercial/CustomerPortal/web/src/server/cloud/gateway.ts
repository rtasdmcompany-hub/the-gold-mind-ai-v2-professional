/**
 * API Gateway helpers — authz · versioning · rate limit · validation · standard responses · logging.
 * Wraps commercial route handlers. Does not control Trading Engine.
 */
import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { cacheIncr, CacheKeys, getCacheBackend } from "./cache";
import { writeAudit, clientIpFromHeaders } from "./audit";
import type { ApiVersion, CloudRole, StandardApiError, StandardApiSuccess } from "./types";
import { randomBytes } from "crypto";
import { canAccessAdminConsole, hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";

const API_VERSION: ApiVersion = "v1";
const startedAt = Date.now();

export function getUptimeSec(): number {
  return Math.floor((Date.now() - startedAt) / 1000);
}

export function newRequestId(): string {
  return `req_${Date.now().toString(36)}_${randomBytes(2).toString("hex")}`;
}

export function apiSuccess<T>(data: T, requestId = newRequestId()): NextResponse {
  const body: StandardApiSuccess<T> = {
    ok: true,
    data,
    meta: { version: API_VERSION, requestId, timestamp: new Date().toISOString() },
  };
  return NextResponse.json(body, {
    headers: {
      "X-TGM-API-Version": API_VERSION,
      "X-TGM-Request-Id": requestId,
    },
  });
}

export function apiError(
  code: string,
  message: string,
  status: number,
  requestId = newRequestId()
): NextResponse {
  const body: StandardApiError = {
    ok: false,
    error: { code, message },
    meta: { version: API_VERSION, requestId, timestamp: new Date().toISOString() },
  };
  return NextResponse.json(body, {
    status,
    headers: {
      "X-TGM-API-Version": API_VERSION,
      "X-TGM-Request-Id": requestId,
    },
  });
}

export type GatewayAuthMode = "public" | "session" | "admin" | "support";

export interface GatewayContext {
  requestId: string;
  ip: string;
  email?: string;
  role?: CloudRole;
  version: ApiVersion;
}

export interface GatewayOptions {
  auth?: GatewayAuthMode;
  /** Fine-grained permission (preferred over coarse auth modes). */
  permission?: import("@/server/admin/roles").AdminPermission;
  rateLimit?: { limit: number; windowSec: number; bucket?: string };
  auditAction?: Parameters<typeof writeAudit>[0]["action"];
}

function roleRank(role?: string): number {
  const r = role || "";
  if (r === "super_admin" || r === "admin") return 5;
  if (r === "commercial_manager" || r === "finance_manager" || r === "qa_manager") return 4;
  if (r === "support_agent" || r === "support" || r === "auditor") return 3;
  if (r === "customer") return 1;
  return 0;
}

export async function withApiGateway(
  req: Request,
  opts: GatewayOptions,
  handler: (ctx: GatewayContext) => Promise<NextResponse>
): Promise<NextResponse> {
  const requestId = newRequestId();
  const ip = clientIpFromHeaders(req.headers);
  const mode = opts.auth || "session";

  try {
    // Rate limiting
    if (opts.rateLimit) {
      const bucket =
        opts.rateLimit.bucket ||
        `${req.method}:${new URL(req.url).pathname}:${ip}`;
      const n = await cacheIncr(CacheKeys.rateLimit(bucket), opts.rateLimit.windowSec);
      if (n > opts.rateLimit.limit) {
        writeAudit({
          user: "anonymous",
          action: "rate_limited",
          ip,
          result: "denied",
          detail: bucket,
          meta: { requestId, backend: getCacheBackend() },
        });
        return apiError("RATE_LIMITED", "Too many requests", 429, requestId);
      }
    }

    let email: string | undefined;
    let role: CloudRole | undefined;

    if (mode !== "public") {
      const session = await auth();
      if (!session?.user?.email) {
        return apiError("UNAUTHORIZED", "Authentication required", 401, requestId);
      }
      email = session.user.email.toLowerCase();
      role = ((session.user as { role?: string }).role || "customer") as CloudRole;

      if (opts.permission && !isDevAdminBypass(email) && !hasPermission(role, opts.permission)) {
        writeAudit({
          user: email,
          action: "admin_action",
          ip,
          result: "denied",
          detail: `missing permission ${opts.permission}`,
          meta: { requestId },
        });
        return apiError("FORBIDDEN", "Insufficient permission", 403, requestId);
      }

      if (mode === "admin" && !canAccessAdminConsole(role) && !isDevAdminBypass(email)) {
        writeAudit({
          user: email,
          action: "admin_action",
          ip,
          result: "denied",
          detail: "admin console required",
          meta: { requestId },
        });
        return apiError("FORBIDDEN", "Admin role required", 403, requestId);
      }
      if (mode === "support" && roleRank(role) < 3 && !isDevAdminBypass(email)) {
        return apiError("FORBIDDEN", "Support or admin role required", 403, requestId);
      }
    }

    const ctx: GatewayContext = { requestId, ip, email, role, version: API_VERSION };
    const res = await handler(ctx);

    if (opts.auditAction) {
      writeAudit({
        user: email || "anonymous",
        action: opts.auditAction,
        ip,
        result: res.status < 400 ? "success" : "failure",
        detail: `${req.method} ${new URL(req.url).pathname}`,
        meta: { requestId, status: String(res.status) },
      });
    }

    res.headers.set("X-TGM-API-Version", API_VERSION);
    res.headers.set("X-TGM-Request-Id", requestId);
    return res;
  } catch (e) {
    const msg = e instanceof Error ? e.message : "INTERNAL";
    if (msg === "UNAUTHORIZED") return apiError("UNAUTHORIZED", "Authentication required", 401, requestId);
    if (msg === "FORBIDDEN") return apiError("FORBIDDEN", "Forbidden", 403, requestId);
    console.error("[api-gateway]", requestId, msg);
    writeAudit({
      user: "system",
      action: "api_request",
      ip,
      result: "error",
      detail: msg,
      meta: { requestId },
    });
    return apiError("INTERNAL", "Unexpected error", 500, requestId);
  }
}

/** Simple request body validation — required string fields. */
export function validateFields(
  body: Record<string, unknown>,
  required: string[]
): string | null {
  for (const key of required) {
    const v = body[key];
    if (v === undefined || v === null || (typeof v === "string" && !v.trim())) {
      return `Missing or empty field: ${key}`;
    }
  }
  return null;
}
