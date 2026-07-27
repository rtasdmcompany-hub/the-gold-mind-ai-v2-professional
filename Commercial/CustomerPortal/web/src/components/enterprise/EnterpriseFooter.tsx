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
  resources: [
    { href: "/docs", label: "Knowledge Base" },
    { href: "/developers", label: "Developer Portal" },
    { href: "/developers/docs", label: "API Reference" },
    { href: "/developers/changelog", label: "Changelog" },
  ],
  support: [
    { href: "/contact", label: "Contact" },
    { href: "/login", label: "Support Center" },
    { href: "/docs#faq", label: "FAQ" },
    { href: "/risk", label: "Risk Disclosure" },
  ],
  legal: [
    { href: "/privacy", label: "Privacy" },
    { href: "/terms", label: "Terms" },
    { href: "/refund", label: "Refunds" },
    { href: "/cookies", label: "Cookies" },
  ],
  partners: [
    { href: "/partners/apply", label: "Partner Program" },
    { href: "/developers", label: "Integrations" },
    { href: "/contact", label: "Enterprise Sales" },
  ],
};

const SOCIAL = [
  { href: "https://github.com/rtasdmcompany-hub/the-gold-mind-ai-v2-professional", label: "GitHub", external: true },
  { href: "/contact", label: "LinkedIn", external: false },
  { href: "/contact", label: "X / Twitter", external: false },
];

export function EnterpriseFooter() {
  return (
    <footer className="e-footer">
      <div className="e-container-wide">
        <div className="e-footer-top">
          <div className="e-footer-brand">
            <BrandLogo variant="footer" href="/" className="e-brand-logo e-brand-logo--footer" />
            <p className="e-footer-desc">
              THE GOLD MIND AI v2.0 PROFESSIONAL — institutional-grade automated trading software by RTAS GROUP OF
              COMPANIES.
            </p>
            <div className="e-footer-badges">
              <RtasGroupBadge height={44} className="e-brand-logo e-brand-logo--badge" />
              <RtasDigitalBadge height={36} className="e-brand-logo e-brand-logo--badge" />
            </div>
          </div>

          <div className="e-footer-newsletter">
            <h4>Newsletter</h4>
            <p>Product updates and institutional research briefings.</p>
            <form className="e-footer-newsletter-form" action="/contact" method="get">
              <input type="email" name="topic" placeholder="Email address" aria-label="Email for newsletter" />
              <button type="submit" className="e-btn e-btn-primary e-btn--sm">Subscribe</button>
            </form>
          </div>
        </div>

        <div className="e-footer-grid">
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
            <h4>Resources</h4>
            <ul>
              {FOOTER.resources.map((l) => (
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
            <h4>Legal</h4>
            <ul>
              {FOOTER.legal.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="e-footer-col">
            <h4>Partners</h4>
            <ul>
              {FOOTER.partners.map((l) => (
                <li key={l.href}>
                  <Link href={l.href}>{l.label}</Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="e-footer-col">
            <h4>Social</h4>
            <ul>
              {SOCIAL.map((l) => (
                <li key={l.label}>
                  <Link href={l.href} target={l.external ? "_blank" : undefined} rel={l.external ? "noopener noreferrer" : undefined}>
                    {l.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <hr className="e-divider-glass" />
        <div className="e-footer-bottom">
          <span>© {new Date().getFullYear()} RTAS GROUP OF COMPANIES · RTAS Digital Marketing Company</span>
          <span className="e-footer-risk">
            Trading involves substantial risk of loss. Past performance is not indicative of future results.
          </span>
        </div>
      </div>
    </footer>
  );
}
