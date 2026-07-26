import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { getProductionStabilization } from "@/server/success/production-stabilization";

export default async function StabilizationPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (
    !hasPermission(role, "admin.observability.read") &&
    !hasPermission(role, "admin.launch.read") &&
    actor !== "admin@goldmind.local"
  ) {
    redirect("/portal/admin");
  }

  const s = await getProductionStabilization();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Production Stabilization</h1>
        <p className="page-sub">
          Commercial reliability review · stability score {s.productStabilityScore} · platform{" "}
          <StatusBadge status={s.platformHealth} /> · Core isolated
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {s.coreIsolation}
      </div>

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Area</th>
              <th>Rating</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {s.areas.map((a) => (
              <tr key={a.id}>
                <td>{a.label}</td>
                <td>
                  <StatusBadge status={a.rating} />
                </td>
                <td className="meta">{a.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Crash rate {s.crashRate}% · Critical alerts {s.criticalAlerts} · Reviewed {s.reviewedAt}
      </p>
    </>
  );
}
