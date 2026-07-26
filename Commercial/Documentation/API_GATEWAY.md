# API_GATEWAY.md

**Phase:** 9 · Sprint 6  
**Code:** `CustomerPortal/web/src/server/cloud/gateway.ts`  
**Isolation:** Commercial API surface — never controls Trading Engine

---

## Responsibilities

| Capability | Implementation |
|------------|----------------|
| Authentication | NextAuth session via `withApiGateway` modes |
| Authorization | `public` · `session` · `support` · `admin` |
| API Versioning | `v1` · `X-TGM-API-Version` · response `meta.version` |
| Rate Limiting | Cache INCR buckets (Upstash or memory) |
| Request Validation | `validateFields()` |
| Response Standardization | `apiSuccess` / `apiError` |
| Error Handling | Mapped UNAUTHORIZED / FORBIDDEN / RATE_LIMITED / INTERNAL |
| API Monitoring | Request id headers · audit hooks |
| API Logging | Audit `api_request` / `rate_limited` |
| Health Endpoints | `GET /api/health` |

---

## Usage

```ts
export async function GET(req: Request) {
  return withApiGateway(req, {
    auth: "session",
    rateLimit: { limit: 120, windowSec: 60 },
    auditAction: "api_request",
  }, async (ctx) => apiSuccess({ hello: true }, ctx.requestId));
}
```

---

## Standard response shape

```json
{
  "ok": true,
  "data": {},
  "meta": { "version": "v1", "requestId": "req_…", "timestamp": "…" }
}
```

Errors: `{ "ok": false, "error": { "code", "message" }, "meta": {…} }`

---

## Public vs protected

Gateway modes compose with middleware public exceptions (webhooks, updater, health).

---

*End of API_GATEWAY.md*
