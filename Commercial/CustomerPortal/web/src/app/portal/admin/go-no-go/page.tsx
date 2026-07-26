import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getExecutiveGoNoGoDashboard } from "@/server/executive/dashboard";
import { actionRunExecutiveSuite } from "@/server/executive/actions";

export default async function GoNoGoPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getExecutiveGoNoGoDashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Final Executive Go / No-Go</h1>
        <p className="page-sub">Phase 10 Sprint 9 · Core SHA verified · commercial review only</p>
      </header>

      <div
        className="card"
        style={{
          marginBottom: 16,
          borderLeft: "4px solid #c6a75e",
          padding: 20,
        }}
      >
        <p className="brand-mark" style={{ marginBottom: 8 }}>
          BOARD RECOMMENDATION
        </p>
        <div style={{ fontFamily: "Georgia, serif", fontSize: 28 }}>{dash.decision}</div>
      </div>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation}
      </div>

      {canWrite && (
        <form action={actionRunExecutiveSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run Sprint 9 executive suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Executive Readiness</h3>
          <div className="value">{dash.executiveReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Production Readiness</h3>
          <div className="value">{dash.productionReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Commercial Readiness</h3>
          <div className="value">{dash.commercialReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Operational Readiness</h3>
          <div className="value">{dash.operationalReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Launch Risk Score</h3>
          <div className="value">{dash.launchRiskScore}</div>
        </div>
        <div className="card">
          <h3>Overall Project</h3>
          <div className="value">{dash.overallProjectScore}</div>
        </div>
        <div className="card">
          <h3>Phase 10 Progress</h3>
          <div className="value">{dash.phase10Progress}%</div>
        </div>
        <div className="card">
          <h3>Critical Open</h3>
          <div className="value">{dash.criticalOpen}</div>
        </div>
        <div className="card">
          <h3>High Open</h3>
          <div className="value">{dash.highOpen}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Rationale</h2>
      <ul>
        {dash.rationale.map((r) => (
          <li key={r}>{r}</li>
        ))}
      </ul>

      <h2 style={{ fontSize: 16 }}>Conditions</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Priority</th>
              <th>Condition</th>
              <th>Owner</th>
            </tr>
          </thead>
          <tbody>
            {dash.conditions.map((c) => (
              <tr key={c.id}>
                <td>{c.id}</td>
                <td>{c.priority}</td>
                <td>{c.title}</td>
                <td className="meta">{c.owner}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        <Link className="btn" href="/portal/admin/executive-scorecard">
          Scorecard
        </Link>
        <Link className="btn" href="/portal/admin/website-launch">
          Website Launch
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
