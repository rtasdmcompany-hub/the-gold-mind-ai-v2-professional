import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import { isResendConfigured, sendTransactionalEmail } from "@/server/accounts/mailer";

/**
 * POST /api/admin/test-email
 * Body: { "to"?: "user@example.com" }
 * Sends a one-shot Resend probe so operators can verify production mail config.
 */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "admin",
      permission: "admin.dashboard",
      rateLimit: { limit: 10, windowSec: 60 },
      auditAction: "admin_action",
    },
    async (ctx) => {
      let to = ctx.email || "";
      try {
        const body = (await req.json()) as { to?: string };
        if (body?.to?.includes("@")) to = body.to.trim().toLowerCase();
      } catch {
        /* optional body */
      }
      if (!to.includes("@")) {
        return apiError("VALIDATION", "Provide a recipient email (or sign in with one).", 400, ctx.requestId);
      }

      if (!isResendConfigured()) {
        return apiError(
          "EMAIL_NOT_CONFIGURED",
          "RESEND_API_KEY and RESEND_FROM_EMAIL must both be set on this deployment.",
          503,
          ctx.requestId
        );
      }

      const subject = "Test email — THE GOLD MIND PROFESSIONAL";
      const text = [
        "This is a Resend delivery test from THE GOLD MIND Customer Portal.",
        `Recipient: ${to}`,
        `Time: ${new Date().toISOString()}`,
        "",
        "If you received this, outbound email is working.",
      ].join("\n");
      const html = `<p>This is a <strong>Resend delivery test</strong> from THE GOLD MIND Customer Portal.</p>
<p>Recipient: <code>${to}</code><br/>Time: ${new Date().toISOString()}</p>
<p>If you received this, outbound email is working.</p>`;

      const sent = await sendTransactionalEmail({
        to,
        subject,
        html,
        text,
        template: "support_ticket",
      });

      if (!sent.ok) {
        return apiError("EMAIL_SEND_FAILED", sent.error || "Resend rejected the message.", 502, ctx.requestId);
      }

      return apiSuccess(
        {
          emailed: true,
          to,
          providerId: sent.providerId,
          outboxId: sent.outboxId,
          mode: sent.mode,
        },
        ctx.requestId
      );
    }
  );
}

export async function GET(req: Request) {
  return withApiGateway(
    req,
    { auth: "admin", permission: "admin.dashboard", rateLimit: { limit: 30, windowSec: 60 } },
    async (ctx) => {
      return apiSuccess(
        {
          resendConfigured: isResendConfigured(),
          fromConfigured: !!(process.env.RESEND_FROM_EMAIL || "").trim(),
          hint: "POST /api/admin/test-email with optional JSON { \"to\": \"you@example.com\" }",
        },
        ctx.requestId
      );
    }
  );
}
