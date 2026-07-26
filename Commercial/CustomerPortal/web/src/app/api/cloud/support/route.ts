import { withApiGateway, apiSuccess, apiError, validateFields } from "@/server/cloud/gateway";
import { writeAudit } from "@/server/cloud/audit";
import { queueCommercialEmail } from "@/server/billing/email";

/**
 * Support Service — ticket intake for Website Edition.
 * Support / admin roles can list; customers can create.
 */
export async function GET(req: Request) {
  return withApiGateway(req, { auth: "support", rateLimit: { limit: 60, windowSec: 60 } }, async () => {
    const { listAllEmailsAdmin } = await import("@/server/billing/email");
    const tickets = listAllEmailsAdmin(40).filter(
      (e) => e.template === "support_ticket" || e.template === "support_reply"
    );
    return apiSuccess({ tickets });
  });
}

export async function POST(req: Request) {
  return withApiGateway(
    req,
    { auth: "session", rateLimit: { limit: 20, windowSec: 60 }, auditAction: "support_action" },
    async (ctx) => {
      const body = (await req.json()) as Record<string, unknown>;
      const err = validateFields(body, ["subject", "body"]);
      if (err) return apiError("VALIDATION", err, 400, ctx.requestId);
      queueCommercialEmail({
        to: "support@goldmind.local",
        template: "support_ticket",
        subject: String(body.subject),
        body: `From: ${ctx.email}\n\n${String(body.body)}`,
      });
      writeAudit({
        user: ctx.email || "customer",
        action: "support_action",
        ip: ctx.ip,
        result: "success",
        detail: String(body.subject),
      });
      return apiSuccess({ submitted: true }, ctx.requestId);
    }
  );
}
