import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getClosureDashboard } from "@/server/closure/dashboard";
import { actionRunClosureSuite } from "@/server/closure/actions";

export default async function Phase10ClosurePage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getClosureDashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Phase 10 Closure</h1>
        <p className="page-sub">
          Sprint 10 · Final Executive Review · Controlled Launch certification · Phase 11 authorization
        </p>
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
          FINAL EXECUTIVE DECISION
        </p>
        <div style={{ fontFamily: "Georgia, serif", fontSize: 28 }}>{dash.decision}</div>
        <p className="meta" style={{ marginTop: 12 }}>
          Phase 11 planning: {dash.phase11Authorized ? "AUTHORIZED" : "NOT AUTHORIZED"} · Global
          Commercial Release: {dash.globalReleaseAuthorized ? "AUTHORIZED" : "NOT AUTHORIZED"}
        </p>
      </div>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"} ·{" "}
        <code style={{ fontSize: 11 }}>{dash.coreSha}</code>
      </div>

      {canWrite && (
        <form action={actionRunClosureSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run Sprint 10 closure suite
          </button>
        </form>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Overall Product</h3>
          <div className="value">{dash.overallProductScore}</div>
        </div>
        <div className="card">
          <h3>Engineering</h3>
          <div className="value">{dash.engineeringScore}</div>
        </div>
        <div className="card">
          <h3>Commercial</h3>
          <div className="value">{dash.commercialScore}</div>
        </div>
        <div className="card">
          <h3>Operational</h3>
          <div className="value">{dash.operationalScore}</div>
        </div>
        <div className="card">
          <h3>Security</h3>
          <div className="value">{dash.securityScore}</div>
        </div>
        <div className="card">
          <h3>Customer Experience</h3>
          <div className="value">{dash.customerExperienceScore}</div>
        </div>
        <div className="card">
          <h3>Production Readiness</h3>
          <div className="value">{dash.productionReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Phase 10 Progress</h3>
          <div className="value">{dash.phase10Progress}%</div>
        </div>
        <div className="card">
          <h3>Final Rating</h3>
          <div className="value" style={{ fontSize: 14 }}>
            {dash.finalExecutiveRating}
          </div>
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
              <th>Blocks</th>
            </tr>
          </thead>
          <tbody>
            {dash.conditions.map((c) => (
              <tr key={c.id}>
                <td>{c.id}</td>
                <td>{c.priority}</td>
                <td>{c.title}</td>
                <td className="meta">{c.owner}</td>
                <td className="meta">{c.blocks}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Phase roll-up</h2>
      <ul>
        {dash.phases.map((p) => (
          <li key={p.phase}>
            Phase {p.phase} — {p.title}: {p.status}
          </li>
        ))}
      </ul>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/go-no-go">
          Sprint 9 Go / No-Go
        </Link>{" "}
        <Link className="btn" href="/portal/admin/executive-scorecard">
          Exec Scorecard
        </Link>
      </p>

      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before beginning Phase 11.
      </p>
    </>
  );
}
