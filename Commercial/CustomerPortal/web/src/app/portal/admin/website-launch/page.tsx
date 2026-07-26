import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getExecutiveWebsiteLaunchDashboard } from "@/server/website-launch/dashboard";
import { actionRunFullWebsiteLaunch } from "@/server/website-launch/actions";

export default async function WebsiteLaunchPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getExecutiveWebsiteLaunchDashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Launch Dashboard</h1>
        <p className="page-sub">
          Website Professional · <StatusBadge status={dash.launchStatus} /> · Core{" "}
          {dash.coreMatches ? "SHA MATCH" : "SHA FAIL"}
        </p>
      </header>
      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation}
      </div>
      {canWrite && (
        <form action={actionRunFullWebsiteLaunch} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Run full Sprint 8 website launch suite
          </button>
        </form>
      )}
      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Website Status</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {dash.websiteStatus}
          </div>
        </div>
        <div className="card">
          <h3>Portal Status</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {dash.portalStatus}
          </div>
        </div>
        <div className="card">
          <h3>API Status</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={dash.apiStatus} />
          </div>
        </div>
        <div className="card">
          <h3>Payments</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.payments}
          </div>
        </div>
        <div className="card">
          <h3>License Activations</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.licenseActivations}
          </div>
        </div>
        <div className="card">
          <h3>Downloads</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.downloads}
          </div>
        </div>
        <div className="card">
          <h3>Support Queue</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.supportQueue}
          </div>
        </div>
        <div className="card">
          <h3>Revenue</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.revenue}
          </div>
        </div>
        <div className="card">
          <h3>System Health</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={dash.systemHealth} />
          </div>
        </div>
        <div className="card">
          <h3>Customer Satisfaction</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.customerSatisfaction}
          </div>
        </div>
        <div className="card">
          <h3>Launch Readiness</h3>
          <div className="value">{dash.launchReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Website Production</h3>
          <div className="value">{dash.websiteProductionScore}</div>
        </div>
      </div>
      <h2 style={{ fontSize: 16 }}>Remaining risks</h2>
      <ul>
        {dash.remainingRisks.map((r) => (
          <li key={r}>{r}</li>
        ))}
      </ul>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 16 }}>
        <Link className="btn" href="/portal/admin/customer-journey">
          Customer Journey
        </Link>
        <Link className="btn" href="/portal/admin/commercial-workflows">
          Commercial Workflows
        </Link>
        <Link className="btn" href="/portal/admin/production-deployment">
          Deployment
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
