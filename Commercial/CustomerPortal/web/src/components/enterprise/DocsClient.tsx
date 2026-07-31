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
    a: "Sign in to the Customer Portal, navigate to Licenses, and enter your license key. Device binding occurs automatically on first MT5 connection.",
  },
  {
    q: "Where do I download the installer?",
    a: "Authenticated customers can download checksum-verified installers from Portal → Downloads. Each package includes SHA-256 checksums and release notes.",
  },
  {
    q: "Is the Trading Engine modified by the portal?",
    a: "No. The certified Core Expert Advisor operates exclusively on MetaTrader 5. The portal handles licensing, billing, and updates only.",
  },
  {
    q: "What payment methods are supported?",
    a: "Paddle is the supported checkout provider once configured for your account plan.",
  },
];

const CONTENT: Record<string, { title: string; body: string }> = {
  overview: {
    title: "Overview",
    body: `${brand.productFullName} is a certified MetaTrader 5 Expert Advisor with enterprise licensing, updates, and support delivered through the official Customer Portal. This documentation covers installation, activation, portal usage, and developer integration.`,
  },
  installation: {
    title: "Installation Guide",
    body: `Download the latest checksum-verified installer from Portal → Downloads. Run ${product.installer.name} as administrator. The installer deploys the EA to your MT5 Experts directory. Verify SHA-256 checksum before installation. Do not modify Core files — the SHA is frozen.`,
  },
  activation: {
    title: "License Activation",
    body: `Before Setup finishes: sign in to the Customer Portal → My Licenses → generate a key (trial or paid) → copy email + key into ${product.installer.name}. Installation will not complete until the portal confirms activation on this PC. Trial and lifetime keys use the same activation standard.`,
  },
  "first-run": {
    title: "First Run Checklist",
    body: `1. Create portal account and generate a license key. 2. Run ${product.installer.name} and paste email + key (required). 3. Wait for License: ACTIVATED. 4. Attach EA to chart. 5. Confirm Active on Portal Dashboard / Devices.`,
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
