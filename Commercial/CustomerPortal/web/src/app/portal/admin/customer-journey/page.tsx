import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint8Evidence } from "@/server/website-launch/dashboard";
import { latestWebsiteLaunchRun } from "@/server/website-launch/store";
import { actionRunJourney } from "@/server/website-launch/actions";
import type { JourneyStep } from "@/server/website-launch/journey";

export default async function CustomerJourneyPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint8Evidence();
  const payload = latestWebsiteLaunchRun("journey")?.payload as { steps: JourneyStep[]; score: number } | undefined;
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Customer Journey Validation</h1>
        <p className="page-sub">Score {payload?.score ?? "—"}</p>
      </header>
      {canWrite && (
        <form action={actionRunJourney} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Re-run journey validation
          </button>
        </form>
      )}
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Step</th>
              <th>Status</th>
              <th>Detail</th>
            </tr>
          </thead>
          <tbody>
            {(payload?.steps || []).map((s) => (
              <tr key={s.id}>
                <td>{s.label}</td>
                <td>
                  <StatusBadge status={s.status} />
                </td>
                <td className="meta">{s.detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
