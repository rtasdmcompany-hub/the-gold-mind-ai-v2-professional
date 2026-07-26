import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import {
  BETA_GROUP_LABELS,
  ENROLLMENT_STEPS,
  ENROLLMENT_STEP_LABELS,
  ensureDemoBetaParticipants,
  enrollmentCompletionPct,
  getBetaSummary,
  getEnrollmentFunnel,
  listBetaParticipants,
  listCanonicalBetaGroups,
  type BetaGroup,
  type BetaStatus,
} from "@/server/launch/beta-store";
import {
  actionCompleteEnrollmentStep,
  actionInviteBeta,
  actionSetBetaCap,
  actionUpdateBeta,
} from "@/server/launch/actions";

export default async function AdminBetaPage({
  searchParams,
}: {
  searchParams: Promise<{ group?: string; status?: string; q?: string }>;
}) {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && actor !== "admin@goldmind.local") {
    redirect("/portal/admin");
  }

  ensureDemoBetaParticipants();
  const sp = await searchParams;
  const participants = listBetaParticipants({
    group: sp.group as BetaGroup | undefined,
    status: sp.status as BetaStatus | undefined,
    q: sp.q,
  });
  const summary = getBetaSummary();
  const funnel = getEnrollmentFunnel();
  const groups = listCanonicalBetaGroups();
  const canWrite = hasPermission(role, "admin.launch.write") || actor === "admin@goldmind.local";

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Beta Participant Management</h1>
        <p className="page-sub">
          Invite-only · {summary.active} active · DAU {summary.dau} · seats {summary.seatsRemaining}/{summary.cohortCap} ·
          avg enrollment {summary.avgEnrollmentPct}%
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        {groups.map((g) => (
          <div className="card" key={g}>
            <h3>{BETA_GROUP_LABELS[g]}</h3>
            <div className="value">{summary.byGroup[g] || 0}</div>
          </div>
        ))}
      </div>

      <h2 style={{ fontSize: 16 }}>Enrollment funnel</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Step</th>
              <th>Completed</th>
              <th>%</th>
            </tr>
          </thead>
          <tbody>
            {funnel.map((f) => (
              <tr key={f.step}>
                <td>{f.label}</td>
                <td>{f.completed}</td>
                <td>{f.pct}%</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div className="field">
          <label htmlFor="q">Search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} />
        </div>
        <div className="field">
          <label htmlFor="group">Group</label>
          <select id="group" name="group" defaultValue={sp.group || ""}>
            <option value="">All</option>
            {groups.map((g) => (
              <option key={g} value={g}>
                {BETA_GROUP_LABELS[g]}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="status">Status</label>
          <select id="status" name="status" defaultValue={sp.status || ""}>
            <option value="">All</option>
            <option value="invited">Invited</option>
            <option value="accepted">Accepted</option>
            <option value="active">Active</option>
            <option value="paused">Paused</option>
            <option value="exited">Exited</option>
          </select>
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
      </form>

      {canWrite && (
        <>
          <form action={actionInviteBeta} className="card" style={{ marginBottom: 16 }}>
            <h3>Invite participant</h3>
            <div className="stack" style={{ marginTop: 8 }}>
              <div className="field">
                <label htmlFor="email">Email</label>
                <input id="email" name="email" type="email" required />
              </div>
              <div className="field">
                <label htmlFor="name">Name</label>
                <input id="name" name="name" />
              </div>
              <div className="field">
                <label htmlFor="groupInvite">Group</label>
                <select id="groupInvite" name="group" defaultValue="content_creators">
                  {groups.map((g) => (
                    <option key={g} value={g}>
                      {BETA_GROUP_LABELS[g]}
                    </option>
                  ))}
                </select>
              </div>
              <div className="field">
                <label htmlFor="notes">Notes</label>
                <input id="notes" name="notes" />
              </div>
              <button type="submit" className="btn btn-primary">
                Send invite
              </button>
            </div>
          </form>
          <form action={actionSetBetaCap} className="card" style={{ marginBottom: 16 }}>
            <h3>Cohort cap</h3>
            <div className="field">
              <label htmlFor="cap">Max participants</label>
              <input id="cap" name="cap" type="number" min={1} max={500} defaultValue={summary.cohortCap} />
            </div>
            <button type="submit" className="btn">
              Update cap
            </button>
          </form>
        </>
      )}

      <div className="stack">
        {participants.map((p) => (
          <div className="card" key={p.id}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{p.name}</strong>
              <StatusBadge status={p.status} />
              <span className="meta">
                {BETA_GROUP_LABELS[p.group]} · {enrollmentCompletionPct(p)}% enrolled ·{" "}
                <code>{p.inviteCode}</code>
              </span>
            </div>
            <p className="meta">{p.email}</p>
            <div className="meta" style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 8 }}>
              {ENROLLMENT_STEPS.map((step) => (
                <span key={step} className={`badge ${p.enrollment[step] ? "badge-ok" : "badge-info"}`}>
                  {ENROLLMENT_STEP_LABELS[step]}
                </span>
              ))}
            </div>
            {canWrite && (
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                <form action={actionUpdateBeta} style={{ display: "flex", gap: 6 }}>
                  <input type="hidden" name="id" value={p.id} />
                  <select name="status" defaultValue={p.status}>
                    <option value="invited">Invited</option>
                    <option value="accepted">Accepted</option>
                    <option value="active">Active</option>
                    <option value="paused">Paused</option>
                    <option value="exited">Exited</option>
                  </select>
                  <button type="submit" className="btn">
                    Save status
                  </button>
                </form>
                <form action={actionCompleteEnrollmentStep} style={{ display: "flex", gap: 6 }}>
                  <input type="hidden" name="id" value={p.id} />
                  <select name="step" defaultValue="activation">
                    {ENROLLMENT_STEPS.map((step) => (
                      <option key={step} value={step}>
                        {ENROLLMENT_STEP_LABELS[step]}
                      </option>
                    ))}
                  </select>
                  <button type="submit" className="btn btn-primary">
                    Mark step done
                  </button>
                </form>
              </div>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
