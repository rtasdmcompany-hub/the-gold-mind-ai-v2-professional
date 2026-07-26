import Link from "next/link";

const LINKS = [
  { href: "/", label: "Home" },
  { href: "/pricing", label: "Pricing" },
  { href: "/docs", label: "Documentation" },
  { href: "/developers", label: "Developers" },
  { href: "/contact", label: "Contact" },
  { href: "/risk", label: "Risk" },
];

export function SiteNav() {
  return (
    <header
      style={{
        display: "flex",
        flexWrap: "wrap",
        gap: 16,
        alignItems: "center",
        justifyContent: "space-between",
        padding: "20px 28px",
        borderBottom: "1px solid var(--gm-border)",
        background: "linear-gradient(180deg, #141416 0%, #0b0b0c 100%)",
      }}
    >
      <Link href="/" style={{ textDecoration: "none" }}>
        <div className="brand-mark">RTAS · PROFESSIONAL</div>
        <div style={{ fontFamily: "Georgia, 'Times New Roman', serif", fontSize: 22, color: "var(--gm-gold-300)" }}>
          THE GOLD MIND
        </div>
      </Link>
      <nav style={{ display: "flex", flexWrap: "wrap", gap: 14, alignItems: "center" }}>
        {LINKS.map((l) => (
          <Link key={l.href} href={l.href} style={{ fontSize: 13, letterSpacing: "0.04em" }}>
            {l.label}
          </Link>
        ))}
        <Link className="btn btn-primary" href="/login" style={{ marginLeft: 8 }}>
          Customer Portal
        </Link>
      </nav>
    </header>
  );
}
