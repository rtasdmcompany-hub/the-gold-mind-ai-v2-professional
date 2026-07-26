import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getPartnerByEmail, getPartnerPortalDashboard } from "@/server/partners/portal";

export default async function PartnerCampaignsPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const partner = getPartnerByEmail(session.user.email);
  if (!partner) redirect("/portal/partner");
  const dash = getPartnerPortalDashboard(partner.id)!;

  return (
    <>
      <h1 className="page-title">Campaign Center</h1>
      <p className="page-sub">Active bonus / promotional campaigns</p>
      {dash.campaigns.length === 0 ? (
        <p className="meta">No active campaigns — standard commission rules apply.</p>
      ) : (
        <ul>
          {dash.campaigns.map((c) => (
            <li key={c.id}>
              {c.name} ({c.type}) · {c.startsAt.slice(0, 10)} → {c.endsAt.slice(0, 10)}
            </li>
          ))}
        </ul>
      )}
      <p style={{ marginTop: 16 }}>
        <Link className="btn" href="/portal/partner">
          Dashboard
        </Link>
      </p>
    </>
  );
}
