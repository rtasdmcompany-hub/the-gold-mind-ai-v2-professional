"use client";

import { useEffect, useState } from "react";

type ReadyState = {
  ready: boolean;
  durable: boolean;
  backend: string;
  message: string;
};

/**
 * Shows whether the production license store can accept Setup.exe activations.
 * Trial and lifetime share the same readiness gate.
 */
export function LicenseStoreBanner() {
  const [state, setState] = useState<ReadyState | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetch("/api/licenses/ready")
      .then((r) => r.json())
      .then((j) => {
        if (!cancelled) {
          setState({
            ready: !!(j.ready || j.ok),
            durable: !!j.durable,
            backend: String(j.backend || "unknown"),
            message: String(j.message || ""),
          });
        }
      })
      .catch(() => {
        if (!cancelled) {
          setState({
            ready: false,
            durable: false,
            backend: "unreachable",
            message: "Cannot reach license readiness API.",
          });
        }
      });
    return () => {
      cancelled = true;
    };
  }, []);

  if (!state) return null;

  if (state.ready) {
    return (
      <div className="card" style={{ marginBottom: 16, borderColor: "var(--gm-gold-600)" }}>
        <h3 style={{ marginBottom: 6 }}>Install activation ready</h3>
        <p className="meta">
          Generate a key below → run Setup.exe → paste the same email + key. Setup will not finish until
          this portal confirms <strong>Active</strong> (trial and lifetime, same rule). Store:{" "}
          {state.backend}.
        </p>
      </div>
    );
  }

  return (
    <div className="card" style={{ marginBottom: 16, borderColor: "#a44" }}>
      <h3 style={{ marginBottom: 6 }}>License store not ready</h3>
      <p className="meta">{state.message}</p>
      <p className="meta" style={{ marginTop: 8 }}>
        Admin: add Upstash Redis (or Vercel KV) env vars on Vercel, then redeploy. Until then, Setup.exe
        correctly refuses to install — no empty activations.
      </p>
    </div>
  );
}
