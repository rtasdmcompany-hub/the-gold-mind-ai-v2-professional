import { withApiGateway, apiSuccess } from "@/server/cloud/gateway";
import { getEnterpriseDashboardWithHealth, getBusinessIntelligence, searchCustomers } from "@/server/admin/ops";
import { ensureDemoTickets } from "@/server/admin/support-store";
import { ensureSeedData } from "@/server/licensing/seed";

/** GET /api/admin/ops — enterprise dashboard / BI / customer search */
export async function GET(req: Request) {
  return withApiGateway(
    req,
    { auth: "admin", permission: "admin.dashboard", rateLimit: { limit: 60, windowSec: 60 }, auditAction: "admin_action" },
    async (ctx) => {
      // ✅ FIX: Yahan 'await' add kiya gaya hai
      await ensureSeedData();
      
      ensureDemoTickets();
      const url = new URL(req.url);
      const view = url.searchParams.get("view") || "dashboard";
      
      if (view === "bi") {
        return apiSuccess({ bi: getBusinessIntelligence() }, ctx.requestId);
      }
      if (view === "customers") {
        return apiSuccess({ customers: searchCustomers(url.searchParams.get("q") || "") }, ctx.requestId);
      }
      
      const dash = await getEnterpriseDashboardWithHealth();
      return apiSuccess({ dashboard: dash }, ctx.requestId);
    }
  );
}
