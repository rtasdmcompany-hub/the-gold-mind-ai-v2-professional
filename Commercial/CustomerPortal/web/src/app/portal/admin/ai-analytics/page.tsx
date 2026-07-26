import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint7Dashboard } from "@/server/ai-assistant/suite";

export default async function AiAnalyticsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint7Dashboard();
  const a = dash.admin;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">AI Analytics</h1>
        <p className="page-sub">Feedback · unanswered · health · audit</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>CSAT average</h3>
          <div className="value">{a.feedback.averageCsat || "—"}</div>
        </div>
        <div className="card">
          <h3>Feedback count</h3>
          <div className="value">{a.feedback.count}</div>
        </div>
        <div className="card">
          <h3>Unanswered</h3>
          <div className="value">{a.unanswered.length}</div>
        </div>
        <div className="card">
          <h3>Blocked replies</h3>
          <div className="value">{a.usage.blockedReplies}</div>
        </div>
        <div className="card">
          <h3>Health</h3>
          <div className="value">{a.health.status}</div>
        </div>
        <div className="card">
          <h3>Audit entries</h3>
          <div className="value">{a.health.auditEntries}</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Unanswered questions</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Surface</th>
              <th>Question</th>
              <th>At</th>
            </tr>
          </thead>
          <tbody>
            {a.unanswered.map((u) => (
              <tr key={u.id}>
                <td>{u.surface}</td>
                <td>{u.question.slice(0, 80)}</td>
                <td>{u.at.slice(0, 19)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>By surface</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Surface</th>
              <th>Conversations</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(a.usage.bySurface).map(([s, n]) => (
              <tr key={s}>
                <td>{s}</td>
                <td>{n}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Recent audit</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Action</th>
              <th>Actor</th>
              <th>Detail</th>
              <th>At</th>
            </tr>
          </thead>
          <tbody>
            {a.recentAudit.map((r) => (
              <tr key={r.id}>
                <td>{r.action}</td>
                <td>{r.actor}</td>
                <td>{r.detail.slice(0, 60)}</td>
                <td>{r.at.slice(0, 19)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/ai-assistant">
          Back to AI Assistant
        </Link>
      </p>
    </>
  );
}
