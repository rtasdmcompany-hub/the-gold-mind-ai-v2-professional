import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import {
  ISSUE_LIFECYCLE,
  ISSUE_STATUS_LABELS,
  PRIORITY_LABELS,
  ensureDemoIssues,
  getIssueSummary,
  listIssues,
  type IssueKind,
  type IssuePriority,
  type IssueStatus,
} from "@/server/launch/issue-store";
import { actionCreateIssue, actionUpdateIssue } from "@/server/launch/actions";

export default async function AdminIssuesPage({
  searchParams,
}: {
  searchParams: Promise<{ priority?: string; status?: string; kind?: string; q?: string }>;
}) {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read")) {
    redirect("/portal/admin");
  }

  ensureDemoIssues();
  const sp = await searchParams;
  const issues = listIssues({
    priority: sp.priority as IssuePriority | undefined,
    status: sp.status as IssueStatus | undefined,
    kind: sp.kind as IssueKind | undefined,
    q: sp.q,
  });
  const summary = getIssueSummary();
  const canWrite = hasPermission(role, "admin.launch.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Issue Resolution Workflow</h1>
        <p className="page-sub">
          Reported → Triaged → Assigned → In Progress → QA → Released → Customer Confirmation · Open {summary.open} ·
          P0 {summary.p0Open} · P1 {summary.p1Open}
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #b45309" }}>
        Only feedback-backed commercial fixes. Feature requests are logged — not speculative sprint delivery. Core
        Trading Engine remains frozen.
      </div>

      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Lifecycle stage</th>
              <th>Count</th>
            </tr>
          </thead>
          <tbody>
            {summary.byLifecycle.map((s) => (
              <tr key={s.status}>
                <td>{s.label}</td>
                <td>{s.count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {canWrite && (
        <form action={actionCreateIssue} className="card" style={{ marginBottom: 16 }}>
          <h3>Log issue (from validated feedback)</h3>
          <div className="stack" style={{ marginTop: 8 }}>
            <div className="field">
              <label htmlFor="title">Title</label>
              <input id="title" name="title" required />
            </div>
            <div className="field">
              <label htmlFor="description">Description</label>
              <textarea id="description" name="description" rows={3} required />
            </div>
            <div className="field">
              <label htmlFor="priority">Priority</label>
              <select id="priority" name="priority" defaultValue="P2">
                <option value="P0">P0</option>
                <option value="P1">P1</option>
                <option value="P2">P2</option>
                <option value="P3">P3</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="kind">Kind</label>
              <select id="kind" name="kind" defaultValue="bug">
                <option value="bug">Bug</option>
                <option value="ui">UI</option>
                <option value="performance">Performance</option>
                <option value="documentation">Documentation</option>
                <option value="feature_request">Feature request (deferred)</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="owner">Owner</label>
              <input id="owner" name="owner" defaultValue={actor} />
            </div>
            <div className="field">
              <label htmlFor="releaseTarget">Release target</label>
              <input id="releaseTarget" name="releaseTarget" placeholder="Sprint 5 / date" />
            </div>
            <button type="submit" className="btn btn-primary">
              Create
            </button>
          </div>
        </form>
      )}

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div className="field">
          <label htmlFor="q">Search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} />
        </div>
        <div className="field">
          <label htmlFor="priority">Priority</label>
          <select id="priority" name="priority" defaultValue={sp.priority || ""}>
            <option value="">All</option>
            <option value="P0">P0</option>
            <option value="P1">P1</option>
            <option value="P2">P2</option>
            <option value="P3">P3</option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="status">Status</label>
          <select id="status" name="status" defaultValue={sp.status || ""}>
            <option value="">All</option>
            {ISSUE_LIFECYCLE.map((s) => (
              <option key={s} value={s}>
                {ISSUE_STATUS_LABELS[s]}
              </option>
            ))}
            <option value="blocked">Blocked</option>
            <option value="closed">Closed</option>
          </select>
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
      </form>

      <div className="stack">
        {issues.map((iss) => (
          <div className="card" key={iss.id}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{iss.title}</strong>
              <StatusBadge status={PRIORITY_LABELS[iss.priority]} />
              <StatusBadge status={ISSUE_STATUS_LABELS[iss.status] || iss.status} />
              <StatusBadge status={iss.kind} />
            </div>
            <p>{iss.description}</p>
            <p className="meta">
              Owner: {iss.owner} · Reporter: {iss.reporter} · Release: {iss.releaseTarget || "—"} · Verification:{" "}
              {iss.verification || "—"} · Confirmed: {iss.customerConfirmedAt || "—"}
            </p>
            {canWrite && (
              <form action={actionUpdateIssue} style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 8 }}>
                <input type="hidden" name="id" value={iss.id} />
                <select name="status" defaultValue={iss.status}>
                  {ISSUE_LIFECYCLE.map((s) => (
                    <option key={s} value={s}>
                      {ISSUE_STATUS_LABELS[s]}
                    </option>
                  ))}
                  <option value="blocked">Blocked</option>
                  <option value="closed">Closed</option>
                </select>
                <select name="priority" defaultValue={iss.priority}>
                  <option value="P0">P0</option>
                  <option value="P1">P1</option>
                  <option value="P2">P2</option>
                  <option value="P3">P3</option>
                </select>
                <input name="owner" defaultValue={iss.owner} placeholder="Owner" />
                <input name="releaseTarget" defaultValue={iss.releaseTarget || ""} placeholder="Release target" />
                <input name="verification" defaultValue={iss.verification || ""} placeholder="Verification" />
                <button type="submit" className="btn">
                  Advance
                </button>
              </form>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
