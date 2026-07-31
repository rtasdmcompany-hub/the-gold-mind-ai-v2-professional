import { auth } from "@/auth";
import type { Session } from "next-auth";
import Link from "next/link";
import { PortalNav } from "@/components/PortalNav";
import { PortalUserBar } from "@/components/PortalUserBar";
import { BrandLogo } from "@/components/BrandLogo";
import { canAccessAdminConsole } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { getParticipantByEmail } from "@/server/launch/beta-store";
import { getPartnerByEmail } from "@/server/partners/portal";
import { redirect } from "next/navigation";
import { brand } from "@/lib/brand";

export default async function PortalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  let session: Session | null = null;
  try {
    session = await auth();
  } catch {
    redirect("/login");
  }
  if (!session?.user) redirect("/login");
  const role = (session.user as { role?: string }).role;
  const showAdmin = canAccessAdminConsole(role) || isDevAdminBypass(session.user.email);
  // Beta Onboarding stays out of the default customer nav — only invited/enrolled participants see it.
  const showBeta = !!(session.user.email && getParticipantByEmail(session.user.email));
  // Partner Portal stays out of the default customer nav — only enrolled partners see it.
  const showPartner = !!(session.user.email && getPartnerByEmail(session.user.email.toLowerCase()));

  return (
    <div className="shell portal-shell">
      <PortalNav showAdmin={!!showAdmin} showBeta={showBeta} showPartner={showPartner} />
      <div className="main">
        <div className="portal-site-bar">
          <Link href="/" className="portal-site-bar-brand">
            {brand.brandName} · Official Website
          </Link>
          <div className="portal-site-bar-links">
            <Link href="/">Home</Link>
            <Link href="/pricing">Pricing</Link>
            <Link href="/docs">Docs</Link>
            <Link href="/contact">Contact</Link>
          </div>
        </div>
        <div className="topbar portal-topbar">
          <PortalUserBar
            name={session.user.name}
            email={session.user.email}
            image={session.user.image}
            role={role}
          />
        </div>
        {children}
        <footer className="portal-footer-block">
          <div className="portal-footer-brands">
            <BrandLogo variant="footer" href="/" />
          </div>
          <p className="footer-note">
            {brand.productFullName} · Customer Portal · Commercial service only · Core Trading Engine is not
            connected to this application.
          </p>
          <div className="portal-footer-links">
            <Link href="/">← Back to Official Website</Link>
            <Link href="/privacy">Privacy</Link>
            <Link href="/terms">Terms</Link>
            <Link href="/eula">EULA</Link>
            <Link href="/cookies">Cookies</Link>
            <Link href="/refund">Refunds</Link>
            <Link href="/disclaimer">Disclaimer</Link>
            <Link href="/risk">Risk</Link>
            <Link href="/contact">Support</Link>
          </div>
        </footer>
      </div>
    </div>
  );
}

