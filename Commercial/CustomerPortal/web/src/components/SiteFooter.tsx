import Link from "next/link";
import { BrandLogo, RtasDigitalBadge, RtasGroupBadge } from "@/components/BrandLogo";

export function SiteFooter() {
  return (
    <footer
      style={{
        padding: "28px 28px 36px",
        borderTop: "1px solid var(--gm-border)",
        background: "linear-gradient(180deg, #0b0b0c 0%, #141416 100%)",
      }}
    >
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: 24,
          alignItems: "center",
          justifyContent: "space-between",
          marginBottom: 18,
        }}
      >
        <BrandLogo variant="footer" href="/" />
        <div style={{ display: "flex", flexWrap: "wrap", gap: 16, alignItems: "center" }}>
          <RtasGroupBadge height={52} />
          <RtasDigitalBadge height={44} />
        </div>
      </div>
      <p style={{ margin: 0, fontSize: 12, color: "var(--gm-ivory-300)", lineHeight: 1.6 }}>
        THE GOLD MIND AI v2.0 PROFESSIONAL · A project of RTAS GROUP OF COMPANIES · Developed by RTAS Digital Marketing
        Company.
        <br />
        <Link href="/risk">Risk disclosure</Link>
        {" · "}
        <Link href="/privacy">Privacy</Link>
        {" · "}
        <Link href="/terms">Terms</Link>
        {" · "}
        <Link href="/refund">Refunds</Link>
        {" · "}
        Trading involves substantial risk of loss.
      </p>
    </footer>
  );
}
