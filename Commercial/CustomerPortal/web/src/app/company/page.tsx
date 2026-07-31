import type { Metadata } from "next";
import Link from "next/link";
import { brand } from "@/lib/brand";
import { brandPageMetadata } from "@/lib/brand-metadata";

export const metadata: Metadata = brandPageMetadata({
  title: "Company",
  description: `About ${brand.brandName} — the commercial product behind ${brand.productName}.`,
});

export default function CompanyPage() {
  return (
    <main className="legal-page">
      <div className="legal-inner">
        <p className="eyebrow">COMPANY</p>
        <h1>{brand.brandName}</h1>
        <p className="legal-lead">
          {brand.brandName} is an independent commercial product offering professional MT5 Expert Advisor
          licensing, customer portal access, billing, and support for {brand.productName}.
        </p>

        <section className="legal-section">
          <h2>What we sell</h2>
          <p>
            We sell licenses and access to {brand.productName} — a trading-automation product for
            MetaTrader 5 — through our Customer Portal. Infrastructure partners may power email, auth,
            billing, and hosting behind the scenes; customer-facing identity remains {brand.brandName} only.
          </p>
        </section>

        <section className="legal-section">
          <h2>Product focus</h2>
          <ul>
            <li>Professional MT5 Expert Advisor distribution and licensing</li>
            <li>Secure Customer Portal for account, license, and billing management</li>
            <li>Transparent commercial policies and support channels</li>
          </ul>
        </section>

        <section className="legal-section">
          <h2>Contact</h2>
          <p>
            Product and support:{" "}
            <a href={`mailto:${brand.emails.support}`}>{brand.emails.support}</a>
          </p>
          <p>
            Billing: <a href={`mailto:${brand.emails.billing}`}>{brand.emails.billing}</a>
          </p>
          <p>
            <Link href="/contact">Contact page →</Link>
          </p>
        </section>

        <p className="legal-updated">
          {brand.copyright} · Version {brand.version}
        </p>
      </div>
    </main>
  );
}
