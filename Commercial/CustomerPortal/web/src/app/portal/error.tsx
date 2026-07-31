"use client";

import Link from "next/link";
import { useEffect } from "react";

export default function PortalErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("[portal] unhandled route error", error.digest || error.message);
  }, [error]);

  return (
    <div className="card" style={{ textAlign: "center", padding: 40 }}>
      <h1 className="page-title">Something went wrong</h1>
      <p className="page-sub">
        We hit an unexpected error loading this page. Please try again, or return to the Dashboard.
      </p>
      <div style={{ display: "flex", gap: 12, justifyContent: "center", marginTop: 20, flexWrap: "wrap" }}>
        <button type="button" className="btn btn-primary" onClick={() => reset()}>
          Try again
        </button>
        <Link href="/portal" className="btn">
          Back to Dashboard
        </Link>
      </div>
    </div>
  );
}
