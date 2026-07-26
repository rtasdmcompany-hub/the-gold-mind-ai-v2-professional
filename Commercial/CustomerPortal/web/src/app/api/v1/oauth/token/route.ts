import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import { issueOAuthToken, refreshOAuthToken } from "@/server/api-platform/keys";

/** POST /api/v1/oauth/token — client_credentials | refresh_token */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 30, windowSec: 60, bucket: "oauth_token" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const body = (await req.json().catch(() => ({}))) as Record<string, string>;
        const grant = body.grant_type || "client_credentials";
        if (grant === "refresh_token") {
          const result = refreshOAuthToken(body.refresh_token || "");
          return apiSuccess(
            {
              token_type: "Bearer",
              access_token: result.accessToken,
              refresh_token: result.refreshToken,
              expires_in: result.expiresIn,
            },
            ctx.requestId
          );
        }
        const apiKey = body.api_key || body.client_secret || "";
        const result = issueOAuthToken(apiKey);
        return apiSuccess(
          {
            token_type: "Bearer",
            access_token: result.accessToken,
            refresh_token: result.refreshToken,
            expires_in: result.expiresIn,
            scope: result.token.scopes.join(" "),
          },
          ctx.requestId
        );
      } catch (e) {
        const msg = e instanceof Error ? e.message : "OAUTH_ERROR";
        return apiError(msg, msg, 401, ctx.requestId);
      }
    }
  );
}
