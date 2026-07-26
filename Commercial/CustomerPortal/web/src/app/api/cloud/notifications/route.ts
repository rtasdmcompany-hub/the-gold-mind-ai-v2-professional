import { withApiGateway, apiSuccess, apiError, validateFields } from "@/server/cloud/gateway";
import { writeAudit } from "@/server/cloud/audit";
import { queueCommercialEmail } from "@/server/billing/email";
import type { EmailTemplate } from "@/server/billing/email";

/**
 * Notification service — commercial email outbox.
 * Independently deployable; never talks to Trading Engine.
 */
export async function GET(req: Request) {
  return withApiGateway(req, { auth: "session", rateLimit: { limit: 60, windowSec: 60 } }, async (ctx) => {
    const { listEmailsForCustomer } = await import("@/server/billing/email");
    return apiSuccess({ notifications: listEmailsForCustomer(ctx.email || "") });
  });
}

export async function POST(req: Request) {
  return withApiGateway(
    req,
    { auth: "admin", rateLimit: { limit: 30, windowSec: 60 }, auditAction: "admin_action" },
    async (ctx) => {
      const body = (await req.json()) as Record<string, unknown>;
      const err = validateFields(body, ["to", "template", "body"]);
      if (err) return apiError("VALIDATION", err, 400, ctx.requestId);
      const template = String(body.template) as EmailTemplate;
      queueCommercialEmail({
        to: String(body.to),
        template,
        body: String(body.body),
        subject: body.subject ? String(body.subject) : undefined,
      });
      writeAudit({
        user: ctx.email || "admin",
        action: "admin_action",
        ip: ctx.ip,
        result: "success",
        detail: `notification queued → ${body.to}`,
        resource: template,
      });
      return apiSuccess({ queued: true }, ctx.requestId);
    }
  );
}
