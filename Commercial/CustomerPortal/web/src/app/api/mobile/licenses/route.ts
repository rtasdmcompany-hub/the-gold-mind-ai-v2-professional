import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import { requireMobileSession } from "@/server/mobile/http";
import {
  mobileListLicenses,
  mobileDeactivateOldDevice,
  mobileTransferEligibleLicense,
  mobileActivateOnNewDevice,
  mobileActivationHistory,
  mobileRenameDevice,
} from "@/server/mobile/licenses";

/** GET /api/mobile/licenses */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 60, windowSec: 60, bucket: "mobile_lic" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        return apiSuccess(
          {
            licenses: mobileListLicenses(session.customerEmail),
            history: mobileActivationHistory(session.customerEmail),
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

/** POST /api/mobile/licenses — activate · deactivate · transfer · rename */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 30, windowSec: 60, bucket: "mobile_lic_write" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
        const action = String(body.action || "");
        if (action === "deactivate") {
          return apiSuccess(
            {
              ok: mobileDeactivateOldDevice(String(body.deviceId || ""), session.customerEmail),
            },
            ctx.requestId
          );
        }
        if (action === "transfer") {
          return apiSuccess(
            {
              ok: mobileTransferEligibleLicense(String(body.deviceId || ""), session.customerEmail),
            },
            ctx.requestId
          );
        }
        if (action === "activate") {
          return apiSuccess(
            {
              result: mobileActivateOnNewDevice({
                email: session.customerEmail,
                licenseKey: String(body.licenseKey || ""),
                deviceName: String(body.deviceName || "Mobile activation"),
                fingerprint: String(body.fingerprint || ""),
              }),
            },
            ctx.requestId
          );
        }
        if (action === "rename") {
          return apiSuccess(
            {
              device: mobileRenameDevice(
                String(body.deviceId || ""),
                session.customerEmail,
                String(body.name || "")
              ),
            },
            ctx.requestId
          );
        }
        return apiError("UNKNOWN_ACTION", "Unknown license action", 400, ctx.requestId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "ERROR";
        return apiError(msg, msg, 400, ctx.requestId);
      }
    }
  );
}
