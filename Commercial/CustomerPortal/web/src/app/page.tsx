import type { Metadata } from "next";
import Link from "next/link";
import { SiteNav } from "@/components/SiteNav";
import { AiAssistantWidget } from "@/components/AiAssistantWidget";

export const metadata: Metadata = {
  title: "THE GOLD MIND PROFESSIONAL — Official Website",
  description:
    "THE GOLD MIND PROFESSIONAL by RTAS — systematic MetaTrader 5 Expert Advisor with certified Core. Customer Portal, licensing, and updates. Trading involves risk of loss.",
  openGraph: {
    title: "THE GOLD MIND PROFESSIONAL",
    description: "Official Website Edition — Customer Portal, licensing, and certified Core.",
    type: "website",
  },
};

export default function HomePage() {
  return (
    <div style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      <SiteNav />
      <section
        style={{
          flex: 1,
          minHeight: "78vh",
          display: "flex",
          flexDirection: "column",
          justifyContent: "flex-end",
          padding: "48px 28px 64px",
          background:
            "radial-gradient(ellipse 90% 70% at 70% 20%, rgba(198,167,94,0.18), transparent 55%), linear-gradient(165deg, #0b0b0c 0%, #1c1c1f 45%, #0b0b0c 100%)",
          borderBottom: "1px solid var(--gm-border)",
        }}
      >
        <p className="brand-mark" style={{ marginBottom: 12 }}>
          WEBSITE EDITION
        </p>
        <h1
          style={{
            fontFamily: "Georgia, 'Times New Roman', serif",
            fontSize: "clamp(40px, 8vw, 72px)",
            fontWeight: 400,
            margin: "0 0 16px",
            letterSpacing: "-0.02em",
            color: "var(--gm-ivory-100)",
            maxWidth: 900,
            lineHeight: 1.05,
          }}
        >
          THE GOLD MIND
          <span style={{ display: "block", color: "var(--gm-gold-300)", fontSize: "0.55em", marginTop: 8 }}>
            PROFESSIONAL
          </span>
        </h1>
        <p style={{ maxWidth: 480, color: "var(--gm-ivory-300)", fontSize: 17, marginBottom: 28 }}>
          Certified Core on MetaTrader 5. License, download, and update through the official Customer Portal.
        </p>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
          <Link className="btn btn-primary" href="/pricing">
            View pricing
          </Link>
          <Link className="btn" href="/login">
            Sign in
          </Link>
        </div>
      </section>
      <footer style={{ padding: "20px 28px", fontSize: 12, color: "var(--gm-ivory-300)" }}>
        <Link href="/risk">Risk disclosure</Link>
        {" · "}
        <Link href="/privacy">Privacy</Link>
        {" · "}
        <Link href="/terms">Terms</Link>
        {" · "}
        <Link href="/refund">Refunds</Link>
        {" · "}
        Trading involves substantial risk of loss.
      </footer>
      <AiAssistantWidget surface="website" role="anonymous" title="Ask AI" />
    </div>
  );
}
