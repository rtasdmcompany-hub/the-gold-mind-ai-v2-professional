"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { customerNav } from "@/lib/nav";
import { BrandLogo } from "@/components/BrandLogo";

export function PortalNav({ showAdmin = false }: { showAdmin?: boolean }) {
  const pathname = usePathname();
  const items = showAdmin
    ? [...customerNav, { href: "/portal/admin", label: "Admin Console" }]
    : [...customerNav];

  return (
    <aside className="nav" aria-label="Customer Portal">
      <div className="brand">
        <BrandLogo variant="nav" href="/portal" priority />
        <p className="brand-sub">Customer Portal · Professional</p>
      </div>
      {items.map((item) => {
        const active =
          item.href === "/portal"
            ? pathname === "/portal"
            : pathname === item.href || pathname.startsWith(item.href + "/");
        return (
          <Link
            key={item.href}
            href={item.href}
            className={`nav-link${active ? " active" : ""}`}
          >
            {item.label}
          </Link>
        );
      })}
    </aside>
  );
}
