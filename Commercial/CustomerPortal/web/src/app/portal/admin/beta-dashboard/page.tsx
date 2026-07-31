import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getExecutiveBetaDashboard } from "@/server/launch/beta-dashboard";

export default async function ExecutiveBetaDashboardPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.read")) {
    redirect("/portal/admin");
  }

  const dash = await getExecutiveBetaDashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Beta Dashboard</h1>
        <p className="page-sub">
          Invite-only beta · feature freeze on · Core {dash.corePolicy} · mode {dash.launchMode}
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Invited Users</h3>
          <div className="value">{dash.invitedUsers}</div>
        </div>
        <div className="card">
          <h3>Active Users</h3>
          <div className="value">{dash.activeUsers}</div>
        </div>
        <div className="card">
          <h3>Daily Active Users</h3>
          <div className="value">{dash.dailyActiveUsers}</div>
        </div>
        <div className="card">
          <h3>Install Success</h3>
          <div className="value">{dash.installSuccess}%</div>
        </div>
        <div className="card">
          <h3>Activation Success</h3>
          <div className="value">{dash.activationSuccess}%</div>
        </div>
        <div className="card">
          <h3>Crash Rate</h3>
          <div className="value">{dash.crashRate}%</div>
        </div>
        <div className="card">
          <h3>Open Issues</h3>
          <div className="value">{dash.openIssues}</div>
          <div className="meta">P0: {dash.p0Open} · Resolved: {dash.resolvedIssues}</div>
        </div>
        <div className="card">
          <h3>Average Satisfaction</h3>
          <div className="value">{dash.averageSatisfaction ?? "—"}</div>
        </div>
        <div className="card">
          <h3>System Health</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={dash.systemHealth} />
          </div>
          <div className="meta">
            Enrollment avg {dash.avgEnrollmentPct}% · fully enrolled {dash.fullyEnrolled}
          </div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Enrollment funnel</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Step</th>
              <th>Completed</th>
              <th>%</th>
            </tr>
          </thead>
          <tbody>
            {dash.enrollmentFunnel.map((f) => (
              <tr key={f.step}>
                <td>{f.label}</td>
                <td>{f.completed}</td>
                <td>{f.pct}%</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Commercial review</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Area</th>
              <th>Rating</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(dash.commercialReview).map(([k, v]) => (
              <tr key={k}>
                <td>{k}</td>
                <td>
                  <StatusBadge status={String(v)} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        <Link className="btn btn-primary" href="/portal/admin/beta">
          Participants
        </Link>
        <Link className="btn" href="/portal/admin/issues">
          Issues
        </Link>
        <Link className="btn" href="/portal/admin/metrics">
          Metrics
        </Link>
        <Link className="btn" href="/portal/admin/feedback">
          Feedback
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
