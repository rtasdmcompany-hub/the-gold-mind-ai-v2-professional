"use client";

import Image from "next/image";
import Link from "next/link";
import { brand } from "@/lib/brand";
import { useSiteContent } from "./SiteContentProvider";

const FOOTER = {
  product: [
    { href: "/about", label: "About" },
    { href: "/pricing", label: "Pricing" },
    { href: "/technology", label: "Technology" },
    { href: "/security", label: "Security" },
    { href: "/docs", label: "Documentation" },
  ],
  portal: [
    { href: "/login", label: "User Portal" },
    { href: "/portal/downloads", label: "Download" },
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

function MediaImage({
  src,
  alt,
  width,
  height,
  className,
}: {
  src: string;
  alt: string;
  width: number;
  height: number;
  className?: string;
}) {
  const remote = /^https?:\/\//i.test(src);
  return (
    <Image
      src={src}
      alt={alt}
      width={width}
      height={height}
      className={className}
      unoptimized={remote || src.startsWith("/api/site-content/media/")}
    />
  );
}

export function EnterpriseFooter() {
  const site = useSiteContent();
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
              aria-label={`${site.header.brandName || brand.brandName}, RTAS Group, and RTAS Digital logos`}
            >
              <div className="e-footer-logo-cell">
                <MediaImage
                  src={site.logos.footerGoldMind || brand.assets.footer}
                  alt={`${site.header.brandName || brand.brandName} ${brand.tagline}`}
                  width={88}
                  height={88}
                  className="e-footer-logo-img"
                />
              </div>
              <div className="e-footer-logo-cell">
                <MediaImage
                  src={site.logos.footerRtasGroup || brand.assets.footerRtasGroup}
                  alt="RTAS Group of Companies"
                  width={88}
                  height={88}
                  className="e-footer-logo-img"
                />
              </div>
              <div className="e-footer-logo-cell">
                <MediaImage
                  src={site.logos.footerRtasDigital || brand.assets.footerRtasDigital}
                  alt="RTAS Digital Marketing Company"
                  width={88}
                  height={88}
                  className="e-footer-logo-img"
                />
              </div>
            </div>
            <p className="e-footer-desc">{site.footer.description}</p>
            <div className="e-footer-admin-wrap">
              <Link href="/admin" className="e-footer-admin-btn e-nav-cta">
                Admin Only
              </Link>
            </div>
            {social.length > 0 ? (
              <ul
                className="e-footer-social"
                style={{ listStyle: "none", padding: 0, display: "flex", gap: 12, marginTop: 8 }}
              >
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
        <div className="e-footer-bottom e-footer-bottom--legal">
          <span className="e-footer-copy">{site.footer.copyrightLine}</span>
          <span className="e-footer-risk">{site.footer.riskLine}</span>
        </div>

        <div
          style={{
            textAlign: "center",
            paddingTop: 16,
            paddingBottom: 8,
            borderTop: "1px solid rgba(255,255,255,0.06)",
            marginTop: 12,
          }}
        >
          <p style={{ fontSize: 12, color: "rgba(255,255,255,0.5)", margin: "4px 0" }}>
            Site created and managed by{" "}
            <strong style={{ color: "rgba(255,255,255,0.7)" }}>
              RTAS Digital Marketing Company
            </strong>
          </p>
          <p style={{ fontSize: 12, color: "rgba(255,255,255,0.5)", margin: "4px 0" }}>
            A Project By:{" "}
            <strong style={{ color: "rgba(255,255,255,0.7)" }}>
              RTAS Group Of Companies
            </strong>
          </p>
        </div>
      </div>
    </footer>
  );
}
