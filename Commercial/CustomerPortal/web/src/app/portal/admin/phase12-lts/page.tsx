import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase12Dashboard } from "@/server/phase12/suite";
import { actionRunPhase12Lts } from "@/server/phase12/actions";

export default async function Phase12LtsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase12Dashboard();
  const s = dash.scores;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Phase 12 — LTS Operations</h1>
        <p className="page-sub">
          Version 1.0 Long-Term Support · Core frozen · Operational excellence
        </p>
      </header>

      <div className="card" style={{ marginBottom: 20, padding: 20, borderLeft: "6px solid #166534" }}>
        <p style={{ margin: 0, fontWeight: 700 }}>
          Overall Platform Health: {s.overallPlatformHealth}
        </p>
        <p className="meta">
          Portal {dash.portalVersion} · Core SHA {dash.coreMatches ? "MATCH" : "FAIL"} · V2.x
          Engineering: NOT AUTHORIZED
        </p>
      </div>

      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Score</th>
              <th>Value</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Customer Success</td>
              <td>{s.customerSuccessScore}</td>
            </tr>
            <tr>
              <td>Support</td>
              <td>{s.supportScore}</td>
            </tr>
            <tr>
              <td>Business Growth</td>
              <td>{s.businessGrowthScore}</td>
            </tr>
            <tr>
              <td>Operational Excellence</td>
              <td>{s.operationalExcellenceScore}</td>
            </tr>
            <tr>
              <td>Infrastructure Health</td>
              <td>{s.infrastructureHealth}</td>
            </tr>
            <tr>
              <td>
                <strong>Overall Platform Health</strong>
              </td>
              <td>
                <strong>{s.overallPlatformHealth}</strong>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <form action={actionRunPhase12Lts} style={{ marginBottom: 20 }}>
        <button type="submit" className="btn">
          Re-run Phase 12 LTS suite
        </button>
      </form>

      <p className="meta" style={{ marginBottom: 12 }}>
        {dash.stopMessage}
      </p>

      <nav style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
        <Link href="/portal/admin/phase12-customer-success">Customer Success</Link>
        <Link href="/portal/admin/phase12-monthly">Monthly Reports</Link>
        <Link href="/portal/admin/phase12-v2-planning">V2 Planning</Link>
      </nav>
    </>
  );
}
