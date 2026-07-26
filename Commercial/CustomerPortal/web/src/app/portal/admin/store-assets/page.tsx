import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint7Evidence } from "@/server/market/dashboard";
import { latestMarketRun } from "@/server/market/store";
import { actionRunAssets } from "@/server/market/actions";
import type { AssetItem } from "@/server/market/assets";

export default async function StoreAssetsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.releases.read") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint7Evidence();
  const payload = latestMarketRun("assets")?.payload as { items: AssetItem[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.releases.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Store Assets</h1>
        <p className="page-sub">Score {payload?.score ?? "—"}</p>
      </header>
      {canWrite && (
        <form action={actionRunAssets} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh asset inventory
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Asset</th>
              <th>Status</th>
              <th>Path</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.items || []).map((i) => (
              <tr key={i.id}>
                <td>{i.label}</td>
                <td>
                  <StatusBadge status={i.status} />
                </td>
                <td className="meta">{i.path}</td>
                <td className="meta">{i.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
