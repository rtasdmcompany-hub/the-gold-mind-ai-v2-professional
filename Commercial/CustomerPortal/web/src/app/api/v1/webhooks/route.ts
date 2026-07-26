import { withPublicApi, apiSuccess, apiError } from "@/server/api-platform/public-gateway";
import { listWebhooks, registerWebhook, webhookCatalog } from "@/server/api-platform/webhooks";
import type { WebhookEventType } from "@/server/api-platform/types";

/** GET /api/v1/webhooks */
export async function GET(req: Request) {
  return withPublicApi(req, { scope: "webhooks:manage" }, async (ctx) =>
    apiSuccess(
      { webhooks: listWebhooks(ctx.email), catalog: webhookCatalog() },
      ctx.requestId
    )
  );
}

/** POST /api/v1/webhooks */
export async function POST(req: Request) {
  return withPublicApi(req, { scope: "webhooks:manage" }, async (ctx) => {
    const body = (await req.json().catch(() => ({}))) as {
      url?: string;
      events?: WebhookEventType[];
    };
    if (!body.url) return apiError("INVALID_BODY", "url required", 400, ctx.requestId);
    const endpoint = registerWebhook({
      ownerEmail: ctx.email,
      url: body.url,
      events: body.events?.length ? body.events : ["license.activated", "payment.received"],
    });
    return apiSuccess(
      {
        webhook: {
          id: endpoint.id,
          url: endpoint.url,
          events: endpoint.events,
          secret: endpoint.secret,
          active: endpoint.active,
        },
      },
      ctx.requestId
    );
  });
}
