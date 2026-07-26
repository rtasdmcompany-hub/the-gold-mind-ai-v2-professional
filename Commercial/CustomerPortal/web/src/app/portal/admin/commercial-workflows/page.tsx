import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint8Evidence } from "@/server/website-launch/dashboard";
import { latestWebsiteLaunchRun } from "@/server/website-launch/store";
import { actionRunWorkflows } from "@/server/website-launch/actions";
import type { WorkflowCheck } from "@/server/website-launch/workflows";

export default async function CommercialWorkflowsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint8Evidence();
  const payload = latestWebsiteLaunchRun("workflows")?.payload as
    | { checks: WorkflowCheck[]; score: number }
    | undefined;
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Commercial Workflow Validation</h1>
        <p className="page-sub">Score {payload?.score ?? "—"}</p>
      </header>
      {canWrite && (
        <form action={actionRunWorkflows} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run workflow validation
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Workflow</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.checks || []).map((c) => (
              <tr key={c.id}>
                <td>{c.label}</td>
                <td>
                  <StatusBadge status={c.status} />
                </td>
                <td className="meta">{c.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
