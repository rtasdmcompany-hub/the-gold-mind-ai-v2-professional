import type { Metadata } from "next";
import Link from "next/link";
import { SiteNav } from "@/components/SiteNav";
import { PLAN_CATALOG, formatMoney } from "@/server/billing/util";

export const metadata: Metadata = {
  title: "Pricing — THE GOLD MIND PROFESSIONAL",
  description: "Professional Website Edition plans: trial, monthly, yearly, lifetime. Trading involves risk of loss.",
};

const ORDER: Array<keyof typeof PLAN_CATALOG> = ["trial", "monthly", "yearly", "lifetime"];

export default function PricingPage() {
  return (
    <div>
      <SiteNav />
      <main style={{ maxWidth: 960, margin: "0 auto", padding: "48px 24px 80px" }}>
        <p className="brand-mark">THE GOLD MIND PROFESSIONAL</p>
        <h1 style={{ fontFamily: "Georgia, serif", fontSize: 40, fontWeight: 400, margin: "8px 0 12px" }}>
          Pricing
        </h1>
        <p style={{ color: "var(--gm-ivory-300)", maxWidth: 560, marginBottom: 36 }}>
          Website Edition licensing via Customer Portal. No guaranteed profits. Past performance is not future results.
        </p>
        <div className="grid grid-3" style={{ gap: 16 }}>
          {ORDER.map((code) => {
            const p = PLAN_CATALOG[code];
            return (
              <div key={code} className="card" style={{ padding: 24 }}>
                <h2 style={{ fontSize: 18, marginTop: 0 }}>{p.label}</h2>
                <div className="value" style={{ fontSize: 28, margin: "12px 0" }}>
                  {p.amountCents === 0 ? "Free" : formatMoney(p.amountCents, p.currency)}
                </div>
                <p className="meta">Interval: {p.interval}</p>
              </div>
            );
          })}
        </div>
        <p style={{ marginTop: 32 }}>
          <Link className="btn btn-primary" href="/login">
            Continue to Portal
          </Link>
        </p>
        <p className="meta" style={{ marginTop: 16 }}>
          Live checkout uses PaymentPort when production PSP credentials are configured. Sandbox available for RC.
        </p>
      </main>
    </div>
  );
}
