"use client";

import Link from "next/link";
import { useEffect } from "react";
import { brand } from "@/lib/brand";

export default function GlobalErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("[portal-web] unhandled route error", error.digest || error.message);
  }, [error]);

  return (
    <div className="e-container" style={{ maxWidth: 560, padding: "96px 24px", textAlign: "center" }}>
      <p className="e-eyebrow">{brand.productName}</p>
      <h1 className="e-section-title" style={{ fontSize: 32 }}>
        Something went wrong
      </h1>
      <p className="e-section-sub">
        We hit an unexpected error loading this page. Please try again, or return to the homepage.
      </p>
      <div style={{ display: "flex", gap: 12, justifyContent: "center", marginTop: 24, flexWrap: "wrap" }}>
        <button type="button" className="e-btn e-btn-primary" onClick={() => reset()}>
          Try again
        </button>
        <Link href="/" className="e-btn">
          Back to homepage
        </Link>
      </div>
    </div>
  );
}
