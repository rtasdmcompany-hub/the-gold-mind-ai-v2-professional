"use client";

import Link from "next/link";
import { useState } from "react";
import { brand } from "@/lib/brand";
import { product } from "@/lib/product";

const SECTIONS = [
  {
    title: "Getting Started",
    items: [
      { href: "#overview", label: "Overview" },
      { href: "#installation", label: "Installation Guide" },
      { href: "#activation", label: "License Activation" },
      { href: "#first-run", label: "First Run Checklist" },
    ],
  },
  {
    title: "User Guides",
    items: [
      { href: "#portal", label: "Customer Portal" },
      { href: "#downloads", label: "Downloads & Updates" },
      { href: "#devices", label: "Device Management" },
      { href: "#billing", label: "Billing & Subscriptions" },
    ],
  },
  {
    title: "Verified Performance",
    items: [
      { href: "#myfxbook", label: "Myfxbook Track Record" },
      { href: "#mql5", label: "MQL5 Market" },
    ],
  },
  {
    title: "Developer Docs",
    items: [
      { href: "/developers", label: "Developer Portal" },
      { href: "/developers/docs", label: "API Reference" },
      { href: "/developers/quickstart", label: "Quickstart" },
      { href: "/developers/webhooks", label: "Webhooks" },
    ],
  },
  {
    title: "Legal & Compliance",
    items: [
      { href: "/risk", label: "Risk Disclosure" },
      { href: "/privacy", label: "Privacy Policy" },
      { href: "/terms", label: "Terms / EULA" },
      { href: "/refund", label: "Refund Policy" },
    ],
  },
];

const FAQ = [
  {
    q: "How do I activate my license?",
    a: "Sign in to the Customer Portal, navigate to Licenses, and enter your license key. Device binding occurs automatically on first MT5 connection. Ensure you are running the latest MT5 build.",
  },
  {
    q: "Where do I download the installer?",
    a: "Authenticated customers can download checksum-verified installers from Portal → Downloads. Each package includes SHA-256 checksums and release notes. Always verify the checksum before installation.",
  },
  {
    q: "Is the Trading Engine modified by the portal?",
    a: "No. The verified Core Expert Advisor operates exclusively on MetaTrader 5. The portal handles licensing, billing, and updates only. The EA file is never altered by the web infrastructure.",
  },
  {
    q: "What payment methods are supported?",
    a: "We support major credit/debit cards (Visa, Mastercard, Amex) and select digital payment methods through our secure payment provider (Paddle). All transactions are encrypted.",
  },
  {
    q: "Can I use this on multiple devices?",
    a: "Each license is bound to one device at a time. If you need to switch devices, contact support to deactivate the current binding. Enterprise multi-device licenses are available on request.",
  },
  {
    q: "What brokers are compatible?",
    a: `${brand.brandName} works with any MT5-compatible broker. We recommend ECN/Raw spread accounts for optimal execution. Ensure XAUUSD is available on your broker's platform.`,
  },
  {
    q: "How do I update the software?",
    a: "Updates are distributed through the Customer Portal → Downloads section. Each update includes release notes and a new SHA-256 checksum. Yearly and Lifetime plans include all future updates.",
  },
  {
    q: "What is the minimum account size?",
    a: "We recommend a minimum of $500 for standard lot sizing. For micro-lot accounts, $200 minimum. The EA includes dynamic position sizing based on account equity.",
  },
];

const CONTENT: Record<string, { title: string; body: string }> = {
  overview: {
    title: "Overview",
    body: `${brand.productFullName} is a verified MetaTrader 5 Expert Advisor with enterprise licensing, updates, and support delivered through the official Customer Portal. This documentation covers installation, activation, portal usage, and developer integration.`,
  },
  installation: {
    title: "Installation Guide",
    body: `Step 1: Download the latest checksum-verified installer from Portal → Downloads. Step 2: Verify SHA-256 checksum matches the one provided in Portal. Step 3: Run ${product.installer.name} as administrator. Step 4: The installer deploys the EA to your MT5 Experts directory. Step 5: Do not modify Core files — the SHA is verified and frozen. Step 6: Attach EA to XAUUSD chart and enable AutoTrading.`,
  },
  activation: {
    title: "License Activation",
    body: `Before Setup finishes: sign in to the Customer Portal → My Licenses → generate a key (trial or paid) → copy email + key into ${product.installer.name}. Installation will not complete until the portal confirms activation on this PC. Trial and lifetime keys use the same activation standard.`,
  },
  "first-run": {
    title: "First Run Checklist",
    body: `1. Create portal account and generate a license key. 2. Run ${product.installer.name} and paste email + key (required). 3. Wait for License: ACTIVATED. 4. Attach EA to XAUUSD chart. 5. Confirm Active on Portal Dashboard / Devices. 6. Ensure AutoTrading button is enabled (green). 7. Monitor via Journal/Experts tabs. 8. Use VPS for 24/7 operation.`,
  },
  portal: {
    title: "Customer Portal",
    body: "The portal provides dashboard, license management, downloads, billing, support tickets, and knowledge base access. Sign in via Google OAuth (when configured) or your verified email and password.",
  },
  downloads: {
    title: "Downloads & Updates",
    body: "Portal → Downloads lists all published installers with version, channel, checksum, and signature status. Portal → Updates shows update history and compatibility matrix.",
  },
  devices: {
    title: "Device Management",
    body: "Portal → Devices shows bound MT5 installations. Each device has a fingerprint hash. Deactivation frees a seat for reassignment per your plan limits.",
  },
  billing: {
    title: "Billing & Subscriptions",
    body: "Portal → Billing shows current plan, invoices, and checkout. Subscription renewals are processed via the configured payment provider.",
  },
  myfxbook: {
    title: "Myfxbook Verified Track Record",
    body: `${brand.brandName} maintains an independently verified trading track record on Myfxbook. You can view live, real-time performance data including win rate, drawdown, profit factor, and trade history. Visit our verified Myfxbook portfolio at: https://www.myfxbook.com/portfolio/gold-mind-ai/12200748 — All performance claims should be independently verified through third-party tracking services before making any purchasing decisions.`,
  },
  mql5: {
    title: "MQL5 Market",
    body: `${brand.productFullName} is available on the official MQL5 Market — the MetaTrader marketplace. You can find product details, user reviews, and signal data at: https://www.mql5.com/en/market/product/183685 — The MQL5 Market listing provides verified product information and community feedback.`,
  },
};

export function DocsClient() {
  const [search, setSearch] = useState("");
  const [active, setActive] = useState("overview");

  const filteredFaq = FAQ.filter(
    (f) =>
      !search ||
      f.q.toLowerCase().includes(search.toLowerCase()) ||
      f.a.toLowerCase().includes(search.toLowerCase())
  );

  const content = CONTENT[active] || CONTENT.overview;

  return (
    <div className="e-container-wide e-docs-layout">
      <aside className="e-docs-sidebar">
        <input
          type="search"
          className="e-docs-search"
          placeholder="Search documentation…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search documentation"
        />
        {SECTIONS.map((sec) => (
          <div key={sec.title} style={{ marginBottom: 24 }}>
            <h4 style={{ fontSize: 11, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--e-gold)", margin: "0 0 8px" }}>
              {sec.title}
            </h4>
            <ul className="e-docs-nav">
              {sec.items.map((item) => {
                const id = item.href.replace("#", "");
                const isExternal = item.href.startsWith("/");
                if (isExternal) {
                  return (
                    <li key={item.href}>
                      <Link href={item.href}>{item.label}</Link>
                    </li>
                  );
                }
                return (
                  <li key={item.href}>
                    <a
                      href={item.href}
                      className={active === id ? "e-active" : ""}
                      onClick={(e) => {
                        e.preventDefault();
                        setActive(id);
                      }}
                    >
                      {item.label}
                    </a>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </aside>

      <article>
        <h1 className="e-section-title" style={{ textAlign: "left", fontSize: "2rem" }}>
          {content.title}
        </h1>
        <div className="e-prose" style={{ maxWidth: "none" }}>
          <p>{content.body}</p>
        </div>

        {active === "myfxbook" && (
          <div style={{ marginTop: 24 }}>
            <a
              href="https://www.myfxbook.com/portfolio/gold-mind-ai/12200748"
              target="_blank"
              rel="noopener noreferrer"
              className="e-btn e-btn-primary"
              style={{ display: "inline-flex", alignItems: "center", gap: 8 }}
            >
              View Live Track Record on Myfxbook ↗
            </a>
          </div>
        )}

        {active === "mql5" && (
          <div style={{ marginTop: 24 }}>
            <a
              href="https://www.mql5.com/en/market/product/183685"
              target="_blank"
              rel="noopener noreferrer"
              className="e-btn e-btn-primary"
              style={{ display: "inline-flex", alignItems: "center", gap: 8 }}
            >
              View on MQL5 Market ↗
            </a>
          </div>
        )}

        <hr className="e-divider-glass" id="faq" />

        <h2 className="e-section-title" style={{ textAlign: "left", fontSize: "1.5rem" }}>
          Frequently Asked Questions
        </h2>
        <div style={{ display: "grid", gap: 16, marginTop: 24 }}>
          {(search ? filteredFaq : FAQ).map((f) => (
            <div key={f.q} className="e-glass-card">
              <h3 style={{ textTransform: "none", letterSpacing: 0, color: "var(--e-text)", fontSize: 15 }}>
                {f.q}
              </h3>
              <p>{f.a}</p>
            </div>
          ))}
        </div>

        <p style={{ marginTop: 32, fontSize: 13, color: "var(--e-text-dim)" }}>
          Full knowledge base available after sign-in:{" "}
          <Link href="/login">Customer Portal → Knowledge Base</Link>
        </p>
      </article>
    </div>
  );
}
