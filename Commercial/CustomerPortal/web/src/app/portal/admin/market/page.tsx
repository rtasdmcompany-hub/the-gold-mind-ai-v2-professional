import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getExecutiveMarketDashboard } from "@/server/market/dashboard";
import { actionRunFullMarketSuite } from "@/server/market/actions";

export default async function MarketDashboardPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.releases.read") && !isDevAdminBypass(actor)) {
    redirect("/portal/admin");
  }
  const dash = await getExecutiveMarketDashboard();
  const canWrite = hasPermission(role, "admin.releases.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">MQL5 Market Edition</h1>
        <p className="page-sub">
          Sprint 7 · readiness <StatusBadge status={dash.storeSubmissionReadiness} /> · Core{" "}
          {dash.coreMatchesCert ? "SHA MATCH" : "SHA FAIL"}
        </p>
      </header>
      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation}
      </div>
      {canWrite && (
        <form action={actionRunFullMarketSuite} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Run full Sprint 7 Market suite
          </button>
        </form>
      )}
      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>MQL5 Readiness</h3>
          <div className="value">{dash.mql5ReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Commercial Packaging</h3>
          <div className="value">{dash.commercialPackagingScore}</div>
        </div>
        <div className="card">
          <h3>Documentation</h3>
          <div className="value">{dash.documentationScore}</div>
        </div>
        <div className="card">
          <h3>Compliance</h3>
          <div className="value">{dash.complianceScore}</div>
        </div>
        <div className="card">
          <h3>Release Readiness</h3>
          <div className="value">{dash.releaseReadinessScore}</div>
        </div>
        <div className="card">
          <h3>Customer Readiness</h3>
          <div className="value">{dash.customerReadinessScore}</div>
        </div>
      </div>
      <h2 style={{ fontSize: 16 }}>Remaining blockers</h2>
      <ul>
        {dash.remainingBlockers.map((b) => (
          <li key={b}>{b}</li>
        ))}
      </ul>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 16 }}>
        <Link className="btn" href="/portal/admin/mql5-compliance">
          Compliance
        </Link>
        <Link className="btn" href="/portal/admin/store-assets">
          Store Assets
        </Link>
        <Link className="btn" href="/portal/admin/store-metadata">
          Metadata
        </Link>
      </div>
      <p className="meta" style={{ marginTop: 12 }}>
        Generated {dash.generatedAt}
      </p>
    </>
  );
}
