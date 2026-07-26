import Link from "next/link";
import { BrandLogo } from "@/components/BrandLogo";
import { SiteFooter } from "@/components/SiteFooter";
import { developerPortalNav } from "@/server/api-platform/catalog";

export default function DevelopersLayout({ children }: { children: React.ReactNode }) {
  const nav = developerPortalNav();
  return (
    <div style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      <header
        style={{
          padding: "16px 24px",
          borderBottom: "1px solid var(--gm-border, #333)",
          display: "flex",
          flexWrap: "wrap",
          gap: 12,
          alignItems: "center",
        }}
      >
        <BrandLogo variant="header" href="/developers" />
        <span className="meta">Developer Portal · API v1 · commercial only</span>
        <nav style={{ display: "flex", flexWrap: "wrap", gap: 8, marginLeft: "auto" }}>
          {nav.map((n) => (
            <Link key={n.href} href={n.href} className="btn">
              {n.label}
            </Link>
          ))}
        </nav>
      </header>
      <main style={{ flex: 1, padding: "24px" }}>{children}</main>
      <SiteFooter />
    </div>
  );
}
