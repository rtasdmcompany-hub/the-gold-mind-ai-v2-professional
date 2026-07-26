import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase12Dashboard } from "@/server/phase12/suite";

export default async function Phase12V2PlanningPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase12Dashboard();
  const v2 = dash.v2Planning as {
    rule?: string;
    backlog?: Array<{ id: string; category: string; title: string; detail: string }>;
    backlogCount?: number;
    implementationBlocked?: boolean;
  } | null;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Phase 12 — Version 2.0 Planning</h1>
        <p className="page-sub">Collect only · DO NOT IMPLEMENT · Core remains frozen</p>
      </header>

      <div
        className="card"
        style={{ marginBottom: 20, padding: 20, borderLeft: "6px solid #b45309" }}
      >
        <p style={{ margin: 0, fontWeight: 700 }}>V2.x Engineering: NOT AUTHORIZED</p>
        <p className="meta" style={{ marginBottom: 0 }}>
          {v2?.rule || dash.stopMessage}
        </p>
      </div>

      <p className="meta" style={{ marginBottom: 16 }}>
        Backlog items: {v2?.backlogCount ?? 0} · Implementation blocked:{" "}
        {v2?.implementationBlocked ? "YES" : "NO"} ·{" "}
        <Link href="/portal/admin/phase12-lts">LTS Hub</Link>
      </p>

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Category</th>
              <th>Title</th>
              <th>Detail</th>
              <th>Phase 12</th>
            </tr>
          </thead>
          <tbody>
            {(v2?.backlog || []).map((b) => (
              <tr key={b.id}>
                <td>{b.id}</td>
                <td>{b.category}</td>
                <td>{b.title}</td>
                <td>{b.detail}</td>
                <td>NO BUILD</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
