"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { customerNav } from "@/lib/nav";

export function PortalNav({ showAdmin = false }: { showAdmin?: boolean }) {
  const pathname = usePathname();
  const items = showAdmin
    ? [...customerNav, { href: "/portal/admin", label: "Admin Console" }]
    : [...customerNav];

  return (
    <aside className="nav" aria-label="Customer Portal">
      <div className="brand">
        <p className="brand-mark">RTAS</p>
        <p className="brand-name">THE GOLD MIND</p>
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
