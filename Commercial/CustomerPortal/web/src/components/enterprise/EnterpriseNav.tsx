"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { BrandLogo } from "@/components/BrandLogo";

const LINKS = [
  { href: "/", label: "Home" },
  { href: "/about", label: "About" },
  { href: "/pricing", label: "Pricing" },
  { href: "/docs", label: "Docs" },
  { href: "/developers", label: "Developers" },
  { href: "/contact", label: "Contact" },
];

export function EnterpriseNav({ transparent = false }: { transparent?: boolean }) {
  const pathname = usePathname();
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 48);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const solid = scrolled || !transparent;

  return (
    <header className={`e-nav ${solid ? "e-nav--solid" : "e-nav--transparent"}`}>
      <div className="e-nav-inner">
        <BrandLogo variant="header" href="/" priority />
        <nav>
          <ul className={`e-nav-links ${menuOpen ? "e-open" : ""}`}>
            {LINKS.map((l) => (
              <li key={l.href}>
                <Link
                  href={l.href}
                  className={pathname === l.href ? "e-active" : ""}
                  onClick={() => setMenuOpen(false)}
                >
                  {l.label}
                </Link>
              </li>
            ))}
            <li>
              <Link href="/login" className="e-nav-cta" onClick={() => setMenuOpen(false)}>
                Customer Portal
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
