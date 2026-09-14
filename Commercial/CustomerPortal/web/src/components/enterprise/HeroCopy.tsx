"use client";

import Link from "next/link";
import { useSiteContent } from "./SiteContentProvider";

export function HeroCopy() {
  const { hero } = useSiteContent();

  return (
    <>
      <p className="e-eyebrow">{hero.eyebrow}</p>
      <h1 className="e-hero-title">{hero.title}</h1>
      <p className="e-lead">
        {(hero.lead || "").replace(/certified/gi, "verified")}
      </p>
      <div className="e-btn-group">
        <Link href={hero.ctaPrimaryHref || "/pricing"} className="e-btn e-btn-primary">
          {hero.ctaPrimaryLabel || "View Pricing"}
        </Link>
        <Link href={hero.ctaSecondaryHref || "/login"} className="e-btn e-btn-ghost">
          {hero.ctaSecondaryLabel || "User Portal"}
        </Link>
      </div>
    </>
  );
}
