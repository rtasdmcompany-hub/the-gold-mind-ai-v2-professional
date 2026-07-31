import Image from "next/image";
import Link from "next/link";

const FOOTER = {
  product: [
    { href: "/about", label: "About" },
    { href: "/pricing", label: "Pricing" },
    { href: "/technology", label: "Technology" },
    { href: "/security", label: "Security" },
    { href: "/docs", label: "Documentation" },
  ],
  portal: [
    { href: "/login", label: "Customer Portal" },
    { href: "/portal/downloads", label: "Downloads" },
    { href: "/developers", label: "Developers" },
    { href: "/contact", label: "Contact" },
  ],
  legal: [
    { href: "/privacy", label: "Privacy" },
    { href: "/terms", label: "Terms" },
    { href: "/eula", label: "EULA" },
    { href: "/cookies", label: "Cookies" },
    { href: "/refund", label: "Refunds" },
    { href: "/disclaimer", label: "Disclaimer" },
    { href: "/risk", label: "Risk Disclosure" },
  ],
};

export function EnterpriseFooter() {
  return (
    <footer className="e-footer e-footer--compact">
      <div className="e-container">
        <div className="e-footer-grid e-footer-grid--compact">
          <div className="e-footer-brand">
            <div className="e-footer-logos e-footer-logos--brand" aria-label="THE GOLD MIND brand">
              <div className="e-footer-logo-cell">
                <Image
                  src="/brand/footer-gold-mind.png"
                  alt="THE GOLD MIND Automated Trading Software"
                  width={88}
                  height={88}
                  className="e-footer-logo-img"
                />
              </div>
            </div>
            <p className="e-footer-desc">
              THE GOLD MIND AI v2.0 PROFESSIONAL — institutional automated trading software for MetaTrader 5.
            </p>
          </div>
          <div className="e-footer-col">
            <h4>Product</h4>
            <ul>
              {FOOTER.product.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="e-footer-col">
            <h4>Portal</h4>
            <ul>
              {FOOTER.portal.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="e-footer-col">
            <h4>Legal</h4>
            <ul>
              {FOOTER.legal.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <hr className="e-divider-glass" />
        <div className="e-footer-bottom">
          <span>© {new Date().getFullYear()} THE GOLD MIND PROFESSIONAL</span>
          <span className="e-footer-risk">Trading involves substantial risk of loss.</span>
        </div>
      </div>
    </footer>
  );
}
