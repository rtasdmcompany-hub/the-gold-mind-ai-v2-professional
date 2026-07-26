import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint3Dashboard } from "@/server/partners/suite";
import {
  actionApproveApplication,
  actionApproveCommission,
  actionProcessPayout,
  actionReactivatePartner,
  actionRejectApplication,
  actionRunPartnerSuite,
  actionSuspendPartner,
  actionVerifyPartner,
} from "@/server/partners/actions";

export default async function AdminPartnersPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint3Dashboard();
  const canWrite =
    hasPermission(role, "admin.billing.write") ||
    hasPermission(role, "admin.launch.write") ||
    isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Partner Operations</h1>
        <p className="page-sub">Phase 11 Sprint 3 · applications · commissions · payouts</p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation} · SHA {dash.coreMatches ? "MATCH" : "FAIL"}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Partner Platform</h3>
          <div className="value">{dash.partnerPlatformScore}</div>
        </div>
        <div className="card">
          <h3>Affiliate Readiness</h3>
          <div className="value">{dash.affiliateReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Commission Engine</h3>
          <div className="value">{dash.commissionEngineScore}</div>
        </div>
        <div className="card">
          <h3>Commercial Growth</h3>
          <div className="value">{dash.commercialGrowthScore}</div>
        </div>
        <div className="card">
          <h3>Operational Readiness</h3>
          <div className="value">{dash.operationalReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Phase 11 Progress</h3>
          <div className="value">{dash.overallPhase11Progress}%</div>
        </div>
      </div>

      {canWrite && (
        <form action={actionRunPartnerSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh partner suite
          </button>
        </form>
      )}

      <h2 style={{ fontSize: 16 }}>Applications</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Email</th>
              <th>Name</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {dash.admin.applications.map((a) => (
              <tr key={a.id}>
                <td>{a.email}</td>
                <td>{a.name}</td>
                <td>{a.status}</td>
                <td>
                  {canWrite && a.status === "submitted" && (
                    <>
                      <form action={actionApproveApplication} style={{ display: "inline" }}>
                        <input type="hidden" name="applicationId" value={a.id} />
                        <button type="submit" className="btn">
                          Approve
                        </button>
                      </form>{" "}
                      <form action={actionRejectApplication} style={{ display: "inline" }}>
                        <input type="hidden" name="applicationId" value={a.id} />
                        <input type="hidden" name="notes" value="rejected by admin" />
                        <button type="submit" className="btn">
                          Reject
                        </button>
                      </form>
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Partners</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Name</th>
              <th>Code</th>
              <th>Tier</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {dash.admin.partners.map((p) => (
              <tr key={p.id}>
                <td>{p.name}</td>
                <td>{p.referralCode}</td>
                <td>{p.tier}</td>
                <td>{p.status}</td>
                <td>
                  {canWrite && (
                    <>
                      <form action={actionVerifyPartner} style={{ display: "inline" }}>
                        <input type="hidden" name="partnerId" value={p.id} />
                        <button type="submit" className="btn">
                          Verify
                        </button>
                      </form>{" "}
                      <form action={actionSuspendPartner} style={{ display: "inline" }}>
                        <input type="hidden" name="partnerId" value={p.id} />
                        <input type="hidden" name="reason" value="admin suspend" />
                        <button type="submit" className="btn">
                          Suspend
                        </button>
                      </form>{" "}
                      <form action={actionReactivatePartner} style={{ display: "inline" }}>
                        <input type="hidden" name="partnerId" value={p.id} />
                        <button type="submit" className="btn">
                          Reactivate
                        </button>
                      </form>
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Commissions pending approval</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Partner</th>
              <th>Amount</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {dash.admin.commissions
              .filter((c) => c.status === "pending_approval")
              .map((c) => (
                <tr key={c.id}>
                  <td className="meta">{c.id}</td>
                  <td className="meta">{c.partnerId}</td>
                  <td>USD {(c.amountCents / 100).toFixed(2)}</td>
                  <td>{c.status}</td>
                  <td>
                    {canWrite && (
                      <form action={actionApproveCommission}>
                        <input type="hidden" name="commissionId" value={c.id} />
                        <button type="submit" className="btn">
                          Approve
                        </button>
                      </form>
                    )}
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ fontSize: 16 }}>Payouts</h2>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>ID</th>
              <th>Amount</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {dash.admin.payouts.map((p) => (
              <tr key={p.id}>
                <td className="meta">{p.id}</td>
                <td>USD {(p.amountCents / 100).toFixed(2)}</td>
                <td>{p.status}</td>
                <td>
                  {canWrite && p.status === "requested" && (
                    <form action={actionProcessPayout}>
                      <input type="hidden" name="payoutId" value={p.id} />
                      <input type="hidden" name="decision" value="paid" />
                      <button type="submit" className="btn">
                        Mark paid
                      </button>
                    </form>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/partner-analytics">
          Partner Analytics
        </Link>
      </p>
      <p className="meta" style={{ marginTop: 24 }}>
        STOP — Await Owner approval before Sprint 4.
      </p>
    </>
  );
}
