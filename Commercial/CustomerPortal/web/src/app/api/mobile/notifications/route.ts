import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import { requireMobileSession } from "@/server/mobile/http";
import {
  listPushInbox,
  getPushPreferences,
  updatePushPreferences,
  markPushRead,
} from "@/server/mobile/push";
import type { PushCategory } from "@/server/mobile/types";

/** GET /api/mobile/notifications */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 60, windowSec: 60, bucket: "mobile_push" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        return apiSuccess(
          {
            inbox: listPushInbox(session.customerEmail),
            preferences: getPushPreferences(session.customerEmail),
          },
          ctx.requestId
        );
      } catch (e) {
        const msg = e instanceof Error ? e.message : "UNAUTHORIZED";
        return apiError(msg, msg, 401, ctx.requestId);
      }
    }
  );
}

/** POST /api/mobile/notifications */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 30, windowSec: 60, bucket: "mobile_push_write" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
        const action = String(body.action || "prefs");
        if (action === "read") {
          return apiSuccess(
            { ok: markPushRead(String(body.id || ""), session.customerEmail) },
            ctx.requestId
          );
        }
        if (action === "prefs") {
          const prefs = updatePushPreferences(
            session.customerEmail,
            (body.categories || {}) as Partial<Record<PushCategory, boolean>>
          );
          return apiSuccess({ preferences: prefs }, ctx.requestId);
        }
        return apiError("UNKNOWN_ACTION", "Unknown notification action", 400, ctx.requestId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "ERROR";
        return apiError(msg, msg, 400, ctx.requestId);
      }
    }
  );
}
