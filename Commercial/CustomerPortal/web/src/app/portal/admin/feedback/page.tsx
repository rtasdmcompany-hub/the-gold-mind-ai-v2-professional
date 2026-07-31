import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import {
  FEEDBACK_CATEGORY_LABELS,
  getFeedbackSummary,
  listFeedback,
  type FeedbackCategory,
  type FeedbackStatus,
} from "@/server/launch/feedback-store";
import { actionTriageFeedback } from "@/server/launch/actions";

export default async function AdminFeedbackPage({
  searchParams,
}: {
  searchParams: Promise<{ category?: string; status?: string; q?: string }>;
}) {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.read")) {
    redirect("/portal/admin");
  }

  const sp = await searchParams;
  const items = listFeedback({
    category: sp.category as FeedbackCategory | undefined,
    status: sp.status as FeedbackStatus | undefined,
    q: sp.q,
  });
  const summary = getFeedbackSummary();
  const canWrite = hasPermission(role, "admin.launch.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Feedback Management</h1>
        <p className="page-sub">
          Bugs · Features · UI · Performance · Docs · P0–P3 · Owner · Verification · Release target · {summary.total}{" "}
          items · CSAT {summary.avgSatisfaction ?? "—"}
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        {(Object.keys(FEEDBACK_CATEGORY_LABELS) as FeedbackCategory[]).map((c) => (
          <div className="card" key={c}>
            <h3>{FEEDBACK_CATEGORY_LABELS[c]}</h3>
            <div className="value">{summary.byCategory[c] || 0}</div>
          </div>
        ))}
      </div>

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div className="field">
          <label htmlFor="q">Search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} />
        </div>
        <div className="field">
          <label htmlFor="category">Category</label>
          <select id="category" name="category" defaultValue={sp.category || ""}>
            <option value="">All</option>
            {(Object.keys(FEEDBACK_CATEGORY_LABELS) as FeedbackCategory[]).map((c) => (
              <option key={c} value={c}>
                {FEEDBACK_CATEGORY_LABELS[c]}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="status">Status</label>
          <select id="status" name="status" defaultValue={sp.status || ""}>
            <option value="">All</option>
            <option value="new">New</option>
            <option value="triaged">Triaged</option>
            <option value="in_progress">In progress</option>
            <option value="resolved">Resolved</option>
            <option value="wont_fix">Won&apos;t fix</option>
          </select>
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
      </form>

      <div className="stack">
        {items.length === 0 && <p className="meta">No feedback yet — customers submit via /portal/feedback</p>}
        {items.map((item) => (
          <div className="card" key={item.id}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{item.title}</strong>
              <StatusBadge status={item.category} />
              <StatusBadge status={item.status} />
              {item.priority ? <StatusBadge status={item.priority} /> : null}
              {item.satisfactionScore ? <span className="meta">★ {item.satisfactionScore}/5</span> : null}
            </div>
            <p className="meta">
              {item.customerEmail} · Owner: {item.owner || "—"} · Release: {item.releaseTarget || "—"} · Verify:{" "}
              {item.verification || "—"} · {item.createdAt}
            </p>
            <p>{item.detail}</p>
            {canWrite && (
              <form action={actionTriageFeedback} style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 8 }}>
                <input type="hidden" name="id" value={item.id} />
                <select name="status" defaultValue={item.status}>
                  <option value="new">New</option>
                  <option value="triaged">Triaged</option>
                  <option value="in_progress">In progress</option>
                  <option value="resolved">Resolved</option>
                  <option value="wont_fix">Won&apos;t fix</option>
                </select>
                <select name="priority" defaultValue={item.priority || "P2"}>
                  <option value="P0">P0</option>
                  <option value="P1">P1</option>
                  <option value="P2">P2</option>
                  <option value="P3">P3</option>
                </select>
                <input name="owner" placeholder="Owner" defaultValue={item.owner || ""} />
                <input name="releaseTarget" placeholder="Release target" defaultValue={item.releaseTarget || ""} />
                <input name="verification" placeholder="Verification" defaultValue={item.verification || ""} />
                <input name="adminNote" placeholder="Admin note" defaultValue={item.adminNote || ""} />
                <button type="submit" className="btn">
                  Triage
                </button>
              </form>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
