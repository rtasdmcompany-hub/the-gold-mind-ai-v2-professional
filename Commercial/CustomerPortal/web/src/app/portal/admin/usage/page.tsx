import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { ensureDemoUsage, getUsageAnalytics } from "@/server/observability/usage-analytics";
import { actionRecordUsage } from "@/server/observability/actions";

export default async function UsageAnalyticsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.observability.read")) {
    redirect("/portal/admin");
  }

  ensureDemoUsage();
  const u = getUsageAnalytics();
  const canWrite = hasPermission(role, "admin.observability.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Customer Usage Analytics</h1>
        <p className="page-sub">Anonymized identities (SHA-256) · no Core trade data · retention 90d</p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Daily Active Users</h3>
          <div className="value">{u.dailyActiveUsers}</div>
        </div>
        <div className="card">
          <h3>Weekly Active Users</h3>
          <div className="value">{u.weeklyActiveUsers}</div>
        </div>
        <div className="card">
          <h3>Monthly Active Users</h3>
          <div className="value">{u.monthlyActiveUsers}</div>
        </div>
        <div className="card">
          <h3>Session Duration</h3>
          <div className="value">{u.sessionDurationMin}</div>
          <div className="meta">minutes avg</div>
        </div>
        <div className="card">
          <h3>Download Counts</h3>
          <div className="value">{u.downloadCounts}</div>
        </div>
        <div className="card">
          <h3>Activation Counts</h3>
          <div className="value">{u.activationCounts}</div>
        </div>
        <div className="card">
          <h3>Retention Trends</h3>
          <div className="value">{u.retentionTrends}%</div>
          <div className="meta">week-over-week return</div>
        </div>
      </div>

      <h2 style={{ fontSize: 16 }}>Most used pages</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Page</th>
              <th>Views</th>
            </tr>
          </thead>
          <tbody>
            {u.mostUsedPages.map((p) => (
              <tr key={p.page}>
                <td>{p.page}</td>
                <td>{p.count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Feature usage</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Feature</th>
              <th>Count</th>
            </tr>
          </thead>
          <tbody>
            {u.featureUsage.map((f) => (
              <tr key={f.feature}>
                <td>{f.feature}</td>
                <td>{f.count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {canWrite && (
        <form action={actionRecordUsage} className="card">
          <h3>Record anonymized usage event</h3>
          <div className="stack" style={{ marginTop: 8 }}>
            <div className="field">
              <label htmlFor="type">Type</label>
              <select id="type" name="type" defaultValue="page_view">
                <option value="page_view">page_view</option>
                <option value="feature_use">feature_use</option>
                <option value="session_end">session_end</option>
                <option value="download">download</option>
                <option value="activation">activation</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="page">Page</label>
              <input id="page" name="page" placeholder="/portal/licenses" />
            </div>
            <div className="field">
              <label htmlFor="feature">Feature</label>
              <input id="feature" name="feature" />
            </div>
            <div className="field">
              <label htmlFor="durationMin">Duration (min)</label>
              <input id="durationMin" name="durationMin" type="number" />
            </div>
            <div className="field">
              <label htmlFor="email">Email (hashed, optional)</label>
              <input id="email" name="email" type="email" />
            </div>
            <button type="submit" className="btn btn-primary">
              Record
            </button>
          </div>
        </form>
      )}
    </>
  );
}
