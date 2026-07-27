import Link from "next/link";
import { BrandLogo, RtasGroupBadge, RtasDigitalBadge } from "@/components/BrandLogo";

const FOOTER = {
  company: [
    { href: "/about", label: "About" },
    { href: "/company", label: "Company" },
    { href: "/technology", label: "Technology" },
    { href: "/infrastructure", label: "Infrastructure" },
    { href: "/security", label: "Security" },
  ],
  products: [
    { href: "/pricing", label: "Pricing" },
    { href: "/login", label: "Customer Portal" },
    { href: "/portal/downloads", label: "Downloads" },
    { href: "/docs", label: "Documentation" },
  ],
  support: [
    { href: "/contact", label: "Contact" },
    { href: "/login", label: "Support Center" },
    { href: "/docs#faq", label: "FAQ" },
    { href: "/risk", label: "Risk Disclosure" },
  ],
  developers: [
    { href: "/developers", label: "Developer Portal" },
    { href: "/developers/docs", label: "API Docs" },
    { href: "/developers/quickstart", label: "Quickstart" },
    { href: "/developers/webhooks", label: "Webhooks" },
  ],
  legal: [
    { href: "/privacy", label: "Privacy" },
    { href: "/terms", label: "Terms" },
    { href: "/refund", label: "Refunds" },
    { href: "/cookies", label: "Cookies" },
  ],
};

export function EnterpriseFooter() {
  return (
    <footer className="e-footer">
      <div className="e-container-wide">
        <div className="e-footer-grid">
          <div>
            <BrandLogo variant="footer" href="/" />
            <p style={{ margin: "16px 0 0", fontSize: 13, color: "var(--e-text-muted)", lineHeight: 1.7, maxWidth: 280 }}>
              THE GOLD MIND AI v2.0 PROFESSIONAL — institutional-grade automated trading software by RTAS GROUP OF
              COMPANIES.
            </p>
            <div className="e-footer-badges">
              <RtasGroupBadge height={44} />
              <RtasDigitalBadge height={36} />
            </div>
          </div>
          <div className="e-footer-col">
            <h4>Company</h4>
            <ul>
              {FOOTER.company.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="e-footer-col">
            <h4>Products</h4>
            <ul>
              {FOOTER.products.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="e-footer-col">
            <h4>Support</h4>
            <ul>
              {FOOTER.support.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="e-footer-col">
            <h4>Developers & Legal</h4>
            <ul>
              {[...FOOTER.developers, ...FOOTER.legal].map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
        </div>
        <hr className="e-divider-glass" />
        <div className="e-footer-bottom">
          <span>© {new Date().getFullYear()} RTAS GROUP OF COMPANIES · RTAS Digital Marketing Company</span>
          <span>Trading involves substantial risk of loss. Past performance is not indicative of future results.</span>
        </div>
      </div>
    </footer>
  );
}
