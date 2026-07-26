import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint8Dashboard } from "@/server/api-platform/suite";
import { actionRunApiSuite } from "@/server/api-platform/actions";

export default async function ApiPlatformAdminPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint8Dashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">API Platform</h1>
        <p className="page-sub">Phase 11 Sprint 8 · commercial APIs only (Core isolated)</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"} · Trading exposed:{" "}
        {dash.tradingExposed ? "YES" : "NO"}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>API Platform</h3>
          <div className="value">{dash.apiPlatformScore}</div>
        </div>
        <div className="card">
          <h3>Developer Experience</h3>
          <div className="value">{dash.developerExperienceScore}</div>
        </div>
        <div className="card">
          <h3>Security</h3>
          <div className="value">{dash.securityScore}</div>
        </div>
        <div className="card">
          <h3>Integration Readiness</h3>
          <div className="value">{dash.integrationReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Scalability</h3>
          <div className="value">{dash.scalabilityScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunApiSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh API suite
          </button>
        </form>
      )}

      <h2 style={{ fontSize: 16 }}>Endpoints ({dash.endpointCount})</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Method</th>
              <th>Path</th>
              <th>Scope</th>
            </tr>
          </thead>
          <tbody>
            {dash.catalog.endpoints.map((e) => (
              <tr key={`${e.method}${e.path}`}>
                <td>{e.method}</td>
                <td className="mono">{e.path}</td>
                <td>{e.scope}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>API keys</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Name</th>
              <th>Prefix</th>
              <th>Rate/min</th>
              <th>Revoked</th>
            </tr>
          </thead>
          <tbody>
            {dash.keys.map((k) => (
              <tr key={k.id}>
                <td>{k.name}</td>
                <td className="mono">{k.keyPrefix}</td>
                <td>{k.rateLimitPerMin}</td>
                <td>{k.revokedAt ? "yes" : "no"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p>
        <Link className="btn" href="/portal/admin/api-webhooks">
          Webhooks
        </Link>{" "}
        <Link className="btn" href="/developers">
          Developer Portal
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 9.
      </p>
    </>
  );
}
