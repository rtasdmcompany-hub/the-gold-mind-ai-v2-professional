import Link from "next/link";
import { BrandLogo } from "@/components/BrandLogo";
import { EnterpriseShell } from "@/components/enterprise/EnterpriseShell";
import { developerPortalNav } from "@/server/api-platform/catalog";

export default function DevelopersLayout({ children }: { children: React.ReactNode }) {
  const nav = developerPortalNav();
  return (
    <EnterpriseShell>
      <div className="e-container-wide" style={{ paddingTop: "calc(var(--e-nav-h) + var(--e-space-lg))" }}>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 16, alignItems: "center", marginBottom: "var(--e-space-lg)" }}>
          <BrandLogo variant="header" href="/developers" />
          <span style={{ fontSize: 13, color: "var(--e-text-muted)" }}>Developer Portal · API v1 · commercial only</span>
          <nav style={{ display: "flex", flexWrap: "wrap", gap: 8, marginLeft: "auto" }}>
            {nav.map((n) => (
              <Link key={n.href} href={n.href} className="e-btn e-btn-ghost" style={{ padding: "8px 14px", fontSize: 12 }}>
                {n.label}
              </Link>
            ))}
          </nav>
        </div>
        <main style={{ paddingBottom: "var(--e-space-2xl)" }}>{children}</main>
      </div>
    </EnterpriseShell>
  );
}
