import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getPhase11Sprint2Dashboard } from "@/server/phase11/bi/dashboard";

export default async function BiSubscriptionsPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getPhase11Sprint2Dashboard();
  const s = dash.subscriptions;
  const o = dash.operations;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Subscription & Operational Analytics</h1>
        <p className="page-sub">Phase 11 Sprint 2 · ACTUAL subscription + ops telemetry</p>
      </header>

      {s && (
        <div className="grid grid-3" style={{ marginBottom: 16 }}>
          <div className="card">
            <h3>New Subscriptions</h3>
            <div className="value">{s.newSubscriptions}</div>
          </div>
          <div className="card">
            <h3>Renewals</h3>
            <div className="value">{s.renewals}</div>
          </div>
          <div className="card">
            <h3>Expired Licenses</h3>
            <div className="value">{s.expiredLicenses}</div>
          </div>
          <div className="card">
            <h3>Cancelled</h3>
            <div className="value">{s.cancelledPlans}</div>
          </div>
          <div className="card">
            <h3>Upgrade Rate</h3>
            <div className="value">{s.upgradeRate.value}%</div>
            <p className="meta">{s.upgradeRate.basis}</p>
          </div>
          <div className="card">
            <h3>Downgrade Rate</h3>
            <div className="value">{s.downgradeRate.value}%</div>
          </div>
          <div className="card">
            <h3>Renewal Success</h3>
            <div className="value">{s.renewalSuccessRate}%</div>
          </div>
          <div className="card">
            <h3>Retention</h3>
            <div className="value">{s.subscriptionRetention}%</div>
          </div>
        </div>
      )}

      {o && (
        <>
          <h2 style={{ fontSize: 16 }}>Operational</h2>
          <div className="grid grid-3">
            <div className="card">
              <h3>Portal ms</h3>
              <div className="value">{o.portalPerformance.loadMs}</div>
            </div>
            <div className="card">
              <h3>API ms</h3>
              <div className="value">{o.apiPerformance.responseMs}</div>
            </div>
            <div className="card">
              <h3>Auth success</h3>
              <div className="value">{o.authenticationSuccess.rate}%</div>
            </div>
            <div className="card">
              <h3>Payment success</h3>
              <div className="value">{o.paymentSuccess.rate}%</div>
            </div>
            <div className="card">
              <h3>Update success</h3>
              <div className="value">{o.updateSuccess.rate}%</div>
            </div>
            <div className="card">
              <h3>Support SLA proxy</h3>
              <div className="value">{o.supportSla.resolvedRatePct}%</div>
            </div>
          </div>
        </>
      )}

      <p style={{ marginTop: 24 }}>
        <Link className="btn" href="/portal/admin/bi-executive">
          BI Executive
        </Link>
      </p>
    </>
  );
}
