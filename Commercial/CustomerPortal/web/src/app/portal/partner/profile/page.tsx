import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getPartnerByEmail, getPartnerPortalDashboard } from "@/server/partners/portal";

export default async function PartnerProfilePage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const partner = getPartnerByEmail(session.user.email);
  if (!partner) redirect("/portal/partner");
  const dash = getPartnerPortalDashboard(partner.id)!;

  return (
    <>
      <h1 className="page-title">Partner Profile</h1>
      <div className="card">
        <p>
          <strong>Name:</strong> {dash.profile.name}
        </p>
        <p>
          <strong>Email:</strong> {dash.profile.email}
        </p>
        <p>
          <strong>Company:</strong> {dash.profile.company || "—"}
        </p>
        <p>
          <strong>Region / Country:</strong> {dash.profile.region || "—"} /{" "}
          {dash.profile.country || "—"}
        </p>
        <p>
          <strong>Tier:</strong> {dash.profile.tier}
        </p>
        <p>
          <strong>Status:</strong> {dash.profile.status}
        </p>
      </div>
      <p style={{ marginTop: 16 }}>
        <Link className="btn" href="/portal/partner">
          Dashboard
        </Link>
      </p>
    </>
  );
}
