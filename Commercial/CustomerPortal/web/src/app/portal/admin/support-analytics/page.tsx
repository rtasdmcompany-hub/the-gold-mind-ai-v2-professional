import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getSupportAnalytics } from "@/server/success/support-analytics";
import { ensureDemoTickets } from "@/server/admin/support-store";

export default async function SupportAnalyticsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (
    !hasPermission(role, "admin.support.read") &&
    !hasPermission(role, "admin.launch.read") &&
    actor !== "admin@goldmind.local"
  ) {
    redirect("/portal/admin");
  }

  ensureDemoTickets();
  const a = getSupportAnalytics();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Support Analytics</h1>
        <p className="page-sub">
          SLA · satisfaction · reopen · escalation · KB usage · FR met{" "}
          <StatusBadge status={a.slaFirstResponseMet ? "ok" : "warn"} />
        </p>
      </header>

      <div className="grid grid-3">
        <div className="card">
          <h3>First Response Time</h3>
          <div className="value">{a.firstResponseTimeHrs} h</div>
          <div className="meta">Target ≤ {a.slaTargetHrs.firstResponse}h · met {a.slaFirstResponseMet ? "yes" : "no"}</div>
        </div>
        <div className="card">
          <h3>Resolution Time</h3>
          <div className="value">{a.resolutionTimeHrs} h</div>
          <div className="meta">Target ≤ {a.slaTargetHrs.resolution}h · met {a.slaResolutionMet ? "yes" : "no"}</div>
        </div>
        <div className="card">
          <h3>Customer Satisfaction</h3>
          <div className="value">{a.customerSatisfaction ?? "—"}</div>
        </div>
        <div className="card">
          <h3>Reopened Tickets</h3>
          <div className="value">{a.reopenedTickets}</div>
        </div>
        <div className="card">
          <h3>Escalation Rate</h3>
          <div className="value">{a.escalationRate}%</div>
        </div>
        <div className="card">
          <h3>Knowledge Base Usage</h3>
          <div className="value">{a.knowledgeBaseUsage}</div>
          <div className="meta">article views</div>
        </div>
        <div className="card">
          <h3>Open / Total</h3>
          <div className="value">
            {a.openTickets} / {a.totalTickets}
          </div>
          <div className="meta">Resolved {a.resolvedTickets}</div>
        </div>
      </div>
    </>
  );
}
