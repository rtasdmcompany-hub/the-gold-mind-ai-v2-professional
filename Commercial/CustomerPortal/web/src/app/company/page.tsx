import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Company",
  description: "About THE GOLD MIND — the commercial product behind THE GOLD MIND PROFESSIONAL.",
};

export default function CompanyPage() {
  return (
    <main className="legal-page">
      <div className="legal-inner">
        <p className="eyebrow">COMPANY</p>
        <h1>THE GOLD MIND</h1>
        <p className="legal-lead">
          THE GOLD MIND is an independent commercial product offering professional MT5 Expert Advisor
          licensing, customer portal access, billing, and support for THE GOLD MIND PROFESSIONAL.
        </p>

        <section className="legal-section">
          <h2>What we sell</h2>
          <p>
            We sell licenses and access to THE GOLD MIND PROFESSIONAL — a trading-automation product for
            MetaTrader 5 — through our Customer Portal. Infrastructure partners may power email, auth,
            billing, and hosting behind the scenes; customer-facing identity remains THE GOLD MIND only.
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
            Product and support: <a href="mailto:support@thegoldmind.ai">support@thegoldmind.ai</a>
          </p>
          <p>
            Billing: <a href="mailto:billing@thegoldmind.ai">billing@thegoldmind.ai</a>
          </p>
          <p>
            <Link href="/contact">Contact page →</Link>
          </p>
        </section>

        <p className="legal-updated">Last updated: July 31, 2026</p>
      </div>
    </main>
  );
}
