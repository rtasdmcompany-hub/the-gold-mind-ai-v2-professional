import Image from "next/image";
import Link from "next/link";
import { brand } from "@/lib/brand";

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
  const social = [
    brand.social.x || brand.social.twitter
      ? { href: brand.social.x || brand.social.twitter, label: "X" }
      : null,
    brand.social.linkedin ? { href: brand.social.linkedin, label: "LinkedIn" } : null,
    brand.social.youtube ? { href: brand.social.youtube, label: "YouTube" } : null,
    brand.social.facebook ? { href: brand.social.facebook, label: "Facebook" } : null,
  ].filter(Boolean) as { href: string; label: string }[];

  return (
    <footer className="e-footer e-footer--compact">
      <div className="e-container">
        <div className="e-footer-grid e-footer-grid--compact">
          <div className="e-footer-brand">
            <div
              className="e-footer-logos e-footer-logos--brand"
              aria-label={`${brand.brandName}, RTAS Group, and RTAS Digital logos`}
            >
              <div className="e-footer-logo-cell">
                <Image
                  src={brand.assets.footer}
                  alt={`${brand.brandName} ${brand.tagline}`}
                  width={88}
                  height={88}
                  className="e-footer-logo-img"
                />
              </div>
              <div className="e-footer-logo-cell">
                <Image
                  src={brand.assets.footerRtasGroup}
                  alt="RTAS Group of Companies"
                  width={88}
                  height={88}
                  className="e-footer-logo-img"
                />
              </div>
              <div className="e-footer-logo-cell">
                <Image
                  src={brand.assets.footerRtasDigital}
                  alt="RTAS Digital Marketing Company"
                  width={88}
                  height={88}
                  className="e-footer-logo-img"
                />
              </div>
            </div>
            <p className="e-footer-desc">
              {brand.productFullName} — institutional automated trading software for MetaTrader 5.
            </p>
            {social.length > 0 ? (
              <ul className="e-footer-social" style={{ listStyle: "none", padding: 0, display: "flex", gap: 12, marginTop: 12 }}>
                {social.map((s) => (
                  <li key={s.href}>
                    <a href={s.href} rel="noopener noreferrer" target="_blank">
                      {s.label}
                    </a>
                  </li>
                ))}
              </ul>
            ) : null}
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
          <span>{brand.copyrightProduct}</span>
          <span className="e-footer-risk">{brand.riskLine}</span>
        </div>
      </div>
    </footer>
  );
}
