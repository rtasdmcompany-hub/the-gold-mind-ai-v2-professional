import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase12Dashboard } from "@/server/phase12/suite";

export default async function Phase12CustomerSuccessPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase12Dashboard();
  const cs = dash.customerSuccess as {
    retention?: { retentionPct: number; activeLicenses: number; churnRiskCount: number };
    npsSample?: { score: number };
    journey?: { trial: number; paid: number; churned: number };
    healthBands?: { healthy: number; watch: number; atRisk: number };
    featureRequests?: Array<{ id: string; title: string; status: string; votes: number }>;
    topAtRisk?: Array<{ email: string; healthScore: number; openTickets: number }>;
    capabilities?: Array<{ label: string; status: string; detail: string }>;
  } | null;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Phase 12 — Customer Success</h1>
        <p className="page-sub">Health · journey · retention · NPS · churn · feature requests</p>
      </header>

      <p className="meta" style={{ marginBottom: 16 }}>
        Score: {dash.scores.customerSuccessScore} ·{" "}
        <Link href="/portal/admin/phase12-lts">LTS Hub</Link>
      </p>

      {cs?.capabilities && (
        <div className="table-wrap" style={{ marginBottom: 20 }}>
          <table className="data">
            <thead>
              <tr>
                <th>Capability</th>
                <th>Status</th>
                <th>Detail</th>
              </tr>
            </thead>
            <tbody>
              {cs.capabilities.map((c) => (
                <tr key={c.label}>
                  <td>{c.label}</td>
                  <td>{c.status}</td>
                  <td>{c.detail}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="card" style={{ marginBottom: 16, padding: 16 }}>
        <p style={{ margin: 0 }}>
          Retention {cs?.retention?.retentionPct ?? "—"}% · Active licenses{" "}
          {cs?.retention?.activeLicenses ?? "—"} · Churn risk {cs?.retention?.churnRiskCount ?? "—"} ·
          NPS {cs?.npsSample?.score ?? "—"}
        </p>
        <p className="meta" style={{ marginBottom: 0 }}>
          Journey — Trial {cs?.journey?.trial ?? 0} · Paid {cs?.journey?.paid ?? 0} · Churned{" "}
          {cs?.journey?.churned ?? 0}
        </p>
      </div>

      <h2 style={{ fontSize: 16 }}>Feature requests (V2 deferral allowed)</h2>
      <div className="table-wrap" style={{ marginBottom: 20 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Title</th>
              <th>Votes</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {(cs?.featureRequests || []).map((f) => (
              <tr key={f.id}>
                <td>{f.id}</td>
                <td>{f.title}</td>
                <td>{f.votes}</td>
                <td>{f.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>At-risk customers</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Email</th>
              <th>Health</th>
              <th>Open tickets</th>
            </tr>
          </thead>
          <tbody>
            {(cs?.topAtRisk || []).length === 0 ? (
              <tr>
                <td colSpan={3}>None in sample</td>
              </tr>
            ) : (
              (cs?.topAtRisk || []).map((r) => (
                <tr key={r.email}>
                  <td>{r.email}</td>
                  <td>{r.healthScore}</td>
                  <td>{r.openTickets}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </>
  );
}
