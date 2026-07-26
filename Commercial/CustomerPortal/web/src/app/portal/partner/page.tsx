import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getPartnerByEmail, getPartnerPortalDashboard } from "@/server/partners/portal";
import { actionRequestPayout } from "@/server/partners/actions";
import { ensureDemoPartner } from "@/server/partners/operations";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { AiAssistantWidget } from "@/components/AiAssistantWidget";

export default async function PartnerPortalHome() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email.toLowerCase();
  let partner = getPartnerByEmail(email);
  if (!partner && (isDevAdminBypass(email) || email === "partner@goldmind.local")) {
    partner = ensureDemoPartner();
  }
  if (!partner) {
    return (
      <>
        <h1 className="page-title">Partner Portal</h1>
        <p className="page-sub">No partner profile for this account.</p>
        <p>
          <Link className="btn btn-primary" href="/partners/apply">
            Apply to become a partner
          </Link>
        </p>
      </>
    );
  }

  const dash = getPartnerPortalDashboard(partner.id);
  if (!dash) redirect("/portal");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Partner Dashboard</h1>
        <p className="page-sub">
          {dash.profile.name} · {dash.profile.tier} · {dash.profile.status}
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16, borderLeft: "4px solid #166534" }}>
        {dash.coreIsolation}
      </div>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Referral Code</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {dash.referralCode}
          </div>
        </div>
        <div className="card">
          <h3>Clicks</h3>
          <div className="value">{dash.clicks}</div>
        </div>
        <div className="card">
          <h3>Approved Commission</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.commissionSummary.approvedFormatted}
          </div>
        </div>
        <div className="card">
          <h3>Pending Commission</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.commissionSummary.pendingFormatted}
          </div>
        </div>
        <div className="card">
          <h3>Paid</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.commissionSummary.paidFormatted}
          </div>
        </div>
        <div className="card">
          <h3>Contract</h3>
          <div className="value" style={{ fontSize: 16 }}>
            {dash.profile.contractStatus}
          </div>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Referral Link</h3>
        <code style={{ fontSize: 13, wordBreak: "break-all" }}>{dash.referralLink}</code>
      </div>

      <form action={actionRequestPayout} style={{ marginBottom: 16 }}>
        <button type="submit" className="btn btn-primary">
          Request payout
        </button>
      </form>

      <p>
        <Link className="btn" href="/portal/partner/profile">
          Profile
        </Link>{" "}
        <Link className="btn" href="/portal/partner/campaigns">
          Campaigns
        </Link>{" "}
        <Link className="btn" href="/portal/partner/resources">
          Resources
        </Link>{" "}
        <Link className="btn" href="/portal/partner/training">
          Training
        </Link>{" "}
        <Link className="btn" href="/portal/partner/commissions">
          Commissions
        </Link>{" "}
        <Link className="btn" href="/portal/support">
          Support
        </Link>
      </p>
      <AiAssistantWidget surface="partner_portal" role="partner" customerEmail={email} title="Partner AI" />
    </>
  );
}
