import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint7Dashboard } from "@/server/ai-assistant/suite";
import { actionRunAiSuite } from "@/server/ai-assistant/actions";

export default async function AiAssistantAdminPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint7Dashboard();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">AI Customer Assistant</h1>
        <p className="page-sub">Phase 11 Sprint 7 · commercial support only (no trading)</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"} · Trading prohibited:{" "}
        {dash.tradingProhibited ? "YES" : "NO"}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>AI Readiness</h3>
          <div className="value">{dash.aiReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Knowledge Base</h3>
          <div className="value">{dash.knowledgeBaseScore}</div>
        </div>
        <div className="card">
          <h3>Support Automation</h3>
          <div className="value">{dash.supportAutomationScore}</div>
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
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunAiSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh AI suite
          </button>
        </form>
      )}

      <h2 style={{ fontSize: 16 }}>Usage</h2>
      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Conversations</h3>
          <div className="value">{dash.admin.usage.conversations}</div>
        </div>
        <div className="card">
          <h3>Avg confidence</h3>
          <div className="value">{dash.admin.usage.avgConfidence}</div>
        </div>
        <div className="card">
          <h3>Escalated</h3>
          <div className="value">{dash.admin.usage.escalated}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Knowledge coverage</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Category</th>
              <th>Docs</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(dash.coverage.byCategory).map(([cat, n]) => (
              <tr key={cat}>
                <td>{cat}</td>
                <td>{n}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p>
        <Link className="btn" href="/portal/admin/ai-analytics">
          AI Analytics
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 8.
      </p>
    </>
  );
}
