import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import {
  mobileEmailLogin,
  mobileGoogleOAuthLogin,
  complete2fa,
  refreshMobileSession,
  secureLogout,
  markTrustedDevice,
} from "@/server/mobile/auth";
import { bearerFromRequest } from "@/server/mobile/http";

/** POST /api/mobile/auth — login · google · 2fa · refresh · logout · trust */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 30, windowSec: 60, bucket: "mobile_auth" },
      auditAction: "api_request",
    },
    async (ctx) => {
      const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
      const action = String(body.action || "email_login");

      try {
        if (action === "email_login") {
          const result = mobileEmailLogin({
            email: String(body.email || ""),
            password: String(body.password || ""),
            totpCode: body.totpCode ? String(body.totpCode) : undefined,
            device: body.device as Parameters<typeof mobileEmailLogin>[0]["device"],
          });
          return apiSuccess({ auth: result }, ctx.requestId);
        }
        if (action === "google") {
          const result = mobileGoogleOAuthLogin({
            email: String(body.email || ""),
            googleIdToken: String(body.googleIdToken || ""),
            device: body.device as Parameters<typeof mobileGoogleOAuthLogin>[0]["device"],
          });
          return apiSuccess({ auth: result }, ctx.requestId);
        }
        if (action === "complete_2fa") {
          const result = complete2fa(
            String(body.sessionId || ""),
            String(body.email || ""),
            String(body.totpCode || "")
          );
          return apiSuccess({ auth: result }, ctx.requestId);
        }
        if (action === "refresh") {
          const result = refreshMobileSession(String(body.refreshToken || ""));
          return apiSuccess({ auth: result }, ctx.requestId);
        }
        if (action === "logout") {
          const token = bearerFromRequest(req) || String(body.accessToken || "");
          return apiSuccess({ ok: secureLogout(token) }, ctx.requestId);
        }
        if (action === "trust_device") {
          const device = markTrustedDevice(
            String(body.deviceId || ""),
            String(body.email || ""),
            String(body.label || "Trusted device")
          );
          return apiSuccess({ device }, ctx.requestId);
        }
        return apiError("UNKNOWN_ACTION", "Unknown auth action", 400, ctx.requestId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "AUTH_FAILED";
        return apiError(msg, msg, 401, ctx.requestId);
      }
    }
  );
}
