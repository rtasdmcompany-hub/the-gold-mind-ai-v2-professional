import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import { requireMobileSession } from "@/server/mobile/http";
import {
  listKnowledgeArticles,
  listFaqs,
  listTicketsForCustomer,
  createSupportTicket,
  liveChatPlaceholder,
  aiSupportEntryPoint,
  submitDiagnosticReport,
} from "@/server/mobile/support";
import type { MobilePlatform } from "@/server/mobile/types";

/** GET /api/mobile/support */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 60, windowSec: 60, bucket: "mobile_support" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        return apiSuccess(
          {
            knowledge: listKnowledgeArticles(),
            faqs: listFaqs(),
            tickets: listTicketsForCustomer(session.customerEmail),
            liveChat: liveChatPlaceholder(),
            ai: aiSupportEntryPoint(),
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

/** POST /api/mobile/support */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 20, windowSec: 60, bucket: "mobile_support_write" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
        const action = String(body.action || "ticket");
        if (action === "ticket") {
          return apiSuccess(
            {
              ticket: createSupportTicket({
                email: session.customerEmail,
                subject: String(body.subject || "Support request"),
                channel: (body.channel as "ticket" | "chat_placeholder" | "ai_entry") || "ticket",
              }),
            },
            ctx.requestId
          );
        }
        if (action === "diagnostic") {
          return apiSuccess(
            {
              report: submitDiagnosticReport({
                email: session.customerEmail,
                deviceId: String(body.deviceId || session.deviceId),
                appVersion: String(body.appVersion || "1.0.0"),
                platform: (body.platform as MobilePlatform) || "android",
                summary: String(body.summary || ""),
              }),
            },
            ctx.requestId
          );
        }
        return apiError("UNKNOWN_ACTION", "Unknown support action", 400, ctx.requestId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "ERROR";
        return apiError(msg, msg, 400, ctx.requestId);
      }
    }
  );
}
