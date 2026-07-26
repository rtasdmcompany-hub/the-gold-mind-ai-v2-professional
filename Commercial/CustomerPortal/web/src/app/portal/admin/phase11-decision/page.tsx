import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint10Dashboard } from "@/server/phase11-closure/suite";

export default async function Phase11DecisionPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint10Dashboard();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Executive Board Decision</h1>
        <p className="page-sub">Phase 11 final certification</p>
      </header>

      <div
        className="card"
        style={{
          marginBottom: 20,
          padding: 24,
          borderLeft: "6px solid #166534",
        }}
      >
        <h2 style={{ marginTop: 0 }}>FINAL DECISION</h2>
        <p style={{ fontSize: 22, fontWeight: 700 }}>{dash.decision}</p>
        <p className="meta">
          Phase 12 authorized: {dash.phase12Authorized ? "YES" : "NO"} · Core SHA{" "}
          {dash.coreMatches ? "MATCH" : "FAIL"}
        </p>
      </div>

      <h2 style={{ fontSize: 16 }}>Rationale</h2>
      <ul style={{ marginBottom: 20 }}>
        {dash.rationale.map((r) => (
          <li key={r}>{r}</li>
        ))}
      </ul>

      <h2 style={{ fontSize: 16 }}>Residual conditions</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Severity</th>
              <th>Title</th>
              <th>Owner</th>
              <th>Target</th>
            </tr>
          </thead>
          <tbody>
            {dash.conditions.map((c) => (
              <tr key={c.id}>
                <td>{c.id}</td>
                <td>{c.severity}</td>
                <td>{c.title}</td>
                <td>{c.owner}</td>
                <td>{c.targetCompletion}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Mitigation</h2>
      <ul>
        {dash.conditions.map((c) => (
          <li key={c.id}>
            <strong>{c.id}:</strong> {c.mitigation}
          </li>
        ))}
      </ul>

      <h2 style={{ fontSize: 16, marginTop: 24 }}>Gates</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Gate</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {dash.gates.map((g) => (
              <tr key={g.id}>
                <td>{g.label}</td>
                <td>{g.status}</td>
                <td>{g.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/phase11-certification">
          Back to Certification
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before beginning Phase 12.
      </p>
    </>
  );
}
