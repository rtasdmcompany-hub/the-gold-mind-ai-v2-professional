"use client";

import { useEffect, useState } from "react";
import { product } from "@/lib/product";

type ReadyState = {
  ready: boolean;
  durable: boolean;
  backend: string;
  message: string;
};

/**
 * Shows whether the production license store can accept {product.installer.name} activations.
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
            durable: !!(j.durableConfigured ?? j.durable),
            backend: String(j.backend || (j.durableConfigured ? "upstash" : "ephemeral")),
            message: String(j.detail || j.message || ""),
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
          Generate a key below → run {product.installer.name} → paste the same email + key. Setup will not finish until
          this portal confirms <strong>Active</strong> (trial and lifetime, same rule). Store:{" "}
          {state.backend}.
        </p>
      </div>
    );
  }

  return (
    <div className="card" style={{ marginBottom: 16, borderColor: "#a44" }}>
      <h3 style={{ marginBottom: 6 }}>License activation temporarily unavailable</h3>
      <p className="meta">
        Installer activation needs durable license storage (Upstash Redis) on this host. You can still view
        and generate keys in the portal; Setup activation may fail until storage is configured.
        {state.message ? (
          <>
            {" "}
            <span className="mono">{state.message}</span>
          </>
        ) : null}
      </p>
    </div>
  );
}
