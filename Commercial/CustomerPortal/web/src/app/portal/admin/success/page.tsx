import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getSuccessExecutiveDashboard } from "@/server/success/cs-dashboard";

export default async function SuccessExecutivePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (
    !hasPermission(role, "admin.launch.read") &&
    !hasPermission(role, "admin.support.read") &&
    actor !== "admin@goldmind.local"
  ) {
    redirect("/portal/admin");
  }

  const dash = await getSuccessExecutiveDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Customer Success Executive Dashboard</h1>
        <p className="page-sub">
          Stabilization · feedback-backed improvements only · Core {dash.corePolicy} · feature freeze{" "}
          {dash.featureFreeze ? "ON" : "OFF"}
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Customer Satisfaction</h3>
          <div className="value">{dash.customerSatisfaction ?? "—"}</div>
        </div>
        <div className="card">
          <h3>Resolved Issues</h3>
          <div className="value">{dash.resolvedIssues}</div>
        </div>
        <div className="card">
          <h3>Open P0</h3>
          <div className="value">{dash.openP0}</div>
        </div>
        <div className="card">
          <h3>Open P1</h3>
          <div className="value">{dash.openP1}</div>
        </div>
        <div className="card">
          <h3>Support SLA</h3>
          <div className="value" style={{ fontSize: 16 }}>
            FR {dash.supportSla.firstResponseHrs}h · Res {dash.supportSla.resolutionHrs}h
          </div>
          <div className="meta">
            FR met: {dash.supportSla.firstResponseMet ? "yes" : "no"} · Res met:{" "}
            {dash.supportSla.resolutionMet ? "yes" : "no"}
          </div>
        </div>
        <div className="card">
          <h3>Product Stability</h3>
          <div className="value">{dash.productStability}</div>
        </div>
        <div className="card">
          <h3>Platform Health</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={dash.platformHealth} />
          </div>
        </div>
        <div className="card">
          <h3>Retention</h3>
          <div className="value">{dash.retention}%</div>
        </div>
        <div className="card">
          <h3>Avg Customer Health</h3>
          <div className="value">{dash.avgCustomerHealth}</div>
          <div className="meta">
            {dash.customersTracked} tracked · {dash.atRiskCustomers} at risk · KB {dash.kbArticles} / {dash.kbViews}{" "}
            views
          </div>
        </div>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        <Link className="btn btn-primary" href="/portal/admin/customer-success">
          Customer Health
        </Link>
        <Link className="btn" href="/portal/admin/feedback">
          Feedback
        </Link>
        <Link className="btn" href="/portal/admin/issues">
          Issues
        </Link>
        <Link className="btn" href="/portal/admin/support-analytics">
          Support Analytics
        </Link>
        <Link className="btn" href="/portal/admin/stabilization">
          Stabilization
        </Link>
        <Link className="btn" href="/portal/knowledge-base">
          Knowledge Base
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
