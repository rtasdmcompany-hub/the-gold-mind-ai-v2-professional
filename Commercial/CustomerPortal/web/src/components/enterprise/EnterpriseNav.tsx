"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { BrandLogo } from "@/components/BrandLogo";
import { brand } from "@/lib/brand";

const LINKS = [
  { href: "/", label: "Home" },
  { href: "/about", label: "About" },
  { href: "/pricing", label: "Pricing" },
  { href: "/docs", label: "Docs" },
  { href: "/portal/downloads", label: "Download" },
  { href: "/contact", label: "Contact" },
  { href: "/register", label: "Register" },
];

export function EnterpriseNav({ transparent = false }: { transparent?: boolean }) {
  const pathname = usePathname();
  const [scrolled, setScrolled] = useState(false);
  const [shrunk, setShrunk] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => {
      const y = window.scrollY;
      setScrolled(y > 32);
      setShrunk(y > 120);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const solid = scrolled || !transparent;

  return (
    <header
      className={`e-nav ${solid ? "e-nav--solid" : "e-nav--transparent"} ${shrunk ? "e-nav--shrunk" : ""}`}
    >
      <div className="e-nav-inner">
        <Link href="/" className="e-brand-lockup" onClick={() => setMenuOpen(false)}>
          <BrandLogo variant="header" priority className="e-brand-logo e-brand-logo--header" />
          <span className="e-brand-wordmark">
            <span className="e-brand-wordmark-title">{brand.brandName}</span>
            <span className="e-brand-wordmark-sub">Professional</span>
          </span>
        </Link>
        <nav>
          <ul className={`e-nav-links ${menuOpen ? "e-open" : ""}`}>
            {LINKS.map((l) => (
              <li key={l.href}>
                <Link
                  href={l.href}
                  className={
                    l.href === "/portal/downloads"
                      ? `e-nav-download${pathname.startsWith("/portal/downloads") ? " e-active" : ""}`
                      : pathname === l.href
                        ? "e-active"
                        : ""
                  }
                  onClick={() => setMenuOpen(false)}
                >
                  {l.label}
                </Link>
              </li>
            ))}
            <li>
              <Link href="/login" className="e-nav-cta" onClick={() => setMenuOpen(false)}>
                User Portal
              </Link>
            </li>
          </ul>
        </nav>
        <button
          type="button"
          className="e-nav-toggle"
          aria-label="Toggle menu"
          aria-expanded={menuOpen}
          onClick={() => setMenuOpen((o) => !o)}
        >
          {menuOpen ? "✕" : "☰"}
        </button>
      </div>
    </header>
  );
}
