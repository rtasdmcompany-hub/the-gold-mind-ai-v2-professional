import Link from "next/link";
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
        <Link href="/developers" style={{ fontWeight: 700, textDecoration: "none" }}>
          THE GOLD MIND Developer Portal
        </Link>
        <span className="meta">API v1 · commercial only</span>
        <nav style={{ display: "flex", flexWrap: "wrap", gap: 8, marginLeft: "auto" }}>
          {nav.map((n) => (
            <Link key={n.href} href={n.href} className="btn">
              {n.label}
            </Link>
          ))}
        </nav>
      </header>
      <main style={{ flex: 1, padding: "24px" }}>{children}</main>
      <footer style={{ padding: "16px 24px", fontSize: 12, opacity: 0.75 }}>
        Core Trading Engine is never exposed through the Public API.
      </footer>
    </div>
  );
}
