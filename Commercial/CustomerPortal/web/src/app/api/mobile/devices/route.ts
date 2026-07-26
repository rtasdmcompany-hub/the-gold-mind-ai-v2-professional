import { withApiGateway, apiSuccess, apiError } from "@/server/cloud/gateway";
import { requireMobileSession } from "@/server/mobile/http";
import { listDevicesForCustomer, listSessionsForCustomer, remoteRevokeSession } from "@/server/mobile/auth";
import { mobileListLicenseDevices } from "@/server/mobile/licenses";
import { setBiometricEnabled, recordDeviceIntegrity } from "@/server/mobile/security";

/** GET /api/mobile/devices */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 60, windowSec: 60, bucket: "mobile_dev" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        return apiSuccess(
          {
            mobileDevices: listDevicesForCustomer(session.customerEmail),
            licenseDevices: mobileListLicenseDevices(session.customerEmail),
            sessions: listSessionsForCustomer(session.customerEmail).filter((s) => !s.revokedAt),
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

/** POST /api/mobile/devices */
export async function POST(req: Request) {
  return withApiGateway(
    req,
    {
      auth: "public",
      rateLimit: { limit: 30, windowSec: 60, bucket: "mobile_dev_write" },
      auditAction: "api_request",
    },
    async (ctx) => {
      try {
        const session = requireMobileSession(req);
        const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
        const action = String(body.action || "");
        if (action === "biometric") {
          return apiSuccess(
            {
              device: setBiometricEnabled(
                String(body.deviceId || session.deviceId),
                session.customerEmail,
                !!body.enabled
              ),
            },
            ctx.requestId
          );
        }
        if (action === "integrity") {
          return apiSuccess(
            {
              device: recordDeviceIntegrity(
                String(body.deviceId || session.deviceId),
                session.customerEmail,
                body.ok !== false
              ),
            },
            ctx.requestId
          );
        }
        if (action === "revoke_session") {
          return apiSuccess(
            {
              ok: remoteRevokeSession(String(body.sessionId || ""), session.customerEmail),
            },
            ctx.requestId
          );
        }
        return apiError("UNKNOWN_ACTION", "Unknown device action", 400, ctx.requestId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : "ERROR";
        return apiError(msg, msg, 400, ctx.requestId);
      }
    }
  );
}
