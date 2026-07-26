import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import {
  gatewayAsk,
  gatewayEscalate,
  gatewayFeedback,
  gatewayGet,
  gatewayStart,
} from "@/server/ai-assistant/gateway";
import type { AiRole, AiSurface } from "@/server/ai-assistant/types";

/** POST /api/ai/chat */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 40, windowSec: 60, bucket: "ai_chat" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
        const action = String(body.action || "ask");

        if (action === "start") {
          const conv = gatewayStart({
            surface: (body.surface as AiSurface) || "website",
            role: (body.role as AiRole) || "anonymous",
            customerEmail: body.customerEmail ? String(body.customerEmail) : undefined,
            locale: body.locale ? String(body.locale) : "en",
          });
          return apiSuccess({ conversation: conv }, ctx.requestId);
        }
        if (action === "ask") {
          const result = gatewayAsk({
            conversationId: String(body.conversationId || ""),
            message: String(body.message || ""),
            escalateIfLow: body.escalateIfLow !== false,
            actor: ctx.email || String(body.actor || "anonymous"),
          });
          return apiSuccess(result, ctx.requestId);
        }
        if (action === "escalate") {
          const escalation = gatewayEscalate(
            String(body.conversationId || ""),
            body.note ? String(body.note) : undefined
          );
          return apiSuccess({ escalation }, ctx.requestId);
        }
        if (action === "feedback") {
          const rating = Number(body.rating) as 1 | 2 | 3 | 4 | 5;
          if (![1, 2, 3, 4, 5].includes(rating)) {
            return apiError("INVALID_RATING", "Rating must be 1-5", 400, ctx.requestId);
          }
          return apiSuccess(
            {
              feedback: gatewayFeedback(
                String(body.conversationId || ""),
                rating,
                body.note ? String(body.note) : undefined
              ),
            },
            ctx.requestId
          );
        }
        if (action === "get") {
          return apiSuccess(
            { conversation: gatewayGet(String(body.conversationId || "")) },
            ctx.requestId
          );
        }
        return apiError("UNKNOWN_ACTION", "Unknown chat action", 400, ctx.requestId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "AI_ERROR";
        const status = msg === "RATE_LIMITED" ? 429 : msg.includes("FORBIDDEN") ? 403 : 400;
        return apiError(msg, msg, status, ctx.requestId);
      }
    }
  );
}
