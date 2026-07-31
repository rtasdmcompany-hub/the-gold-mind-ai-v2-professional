"use client";

import { useState, useTransition } from "react";
import { actionCompleteSandboxCheckout, actionStartCheckout } from "@/server/billing/actions";
import type { PlanCode } from "@/server/billing/types";

const PLANS: { code: PlanCode; label: string; price: string }[] = [
  { code: "trial", label: "Trial", price: "USD 0.00" },
  { code: "monthly", label: "Monthly", price: "USD 99.00" },
  { code: "yearly", label: "Yearly", price: "USD 899.00" },
  { code: "lifetime", label: "Lifetime", price: "USD 2,499.00" },
];

type Props = {
  sandboxAllowed: boolean;
  paddleConfigured: boolean;
};

/**
 * Website Edition checkout entry.
 * Business logic goes through PaymentPort (actionStartCheckout) — never PSP SDKs.
 * Only Paddle is offered to customers — Stripe / PayPal are not wired to a live checkout
 * flow yet and are never surfaced here. MQL5 Market Edition is not connected to this panel.
 */
export function CheckoutPanel({ sandboxAllowed, paddleConfigured }: Props) {
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);
  const [key, setKey] = useState<string | null>(null);

  const checkoutAvailable = paddleConfigured || sandboxAllowed;

  return (
    <div className="card" style={{ marginBottom: 16 }}>
      <h3>Checkout · Website Edition</h3>
      {!checkoutAvailable ? (
        <p className="meta" style={{ marginBottom: 0 }}>
          Payments are temporarily unavailable. Please check back shortly or contact Support.
        </p>
      ) : (
        <>
          <p className="meta" style={{ marginBottom: 12 }}>
            Secure checkout via Paddle. Licenses are issued only after a verified payment webhook. MQL5 Market is
            not connected.
          </p>
          {sandboxAllowed && !paddleConfigured && (
            <p className="meta" style={{ marginBottom: 12 }}>
              Live payments are not yet configured — sandbox checkout is available for local/dev testing only.
            </p>
          )}
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            {PLANS.map((p) => (
              <button
                key={p.code}
                type="button"
                className="btn btn-primary"
                disabled={pending}
                onClick={() =>
                  start(async () => {
                    setKey(null);
                    const fd = new FormData();
                    fd.set("plan", p.code);
                    fd.set("provider", "paddle");
                    const session = await actionStartCheckout(fd);
                    if ("error" in session && session.error) {
                      setMsg("Checkout is currently unavailable. Please try again shortly or contact Support.");
                      return;
                    }
                    setMsg(
                      `Checkout ${session.checkoutId} via ${session.provider} · ${session.currency} ${(session.amountCents / 100).toFixed(2)}`
                    );
                    if (typeof window !== "undefined" && session.checkoutUrl) {
                      window.location.href = session.checkoutUrl;
                    }
                  })
                }
              >
                Buy {p.label} ({p.price})
              </button>
            ))}
          </div>
          {sandboxAllowed && (
            <>
              <p className="meta" style={{ marginTop: 12 }}>
                Dev shortcut (skips hosted page — authenticated sandbox webhook pipeline only):
              </p>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                {PLANS.map((p) => (
                  <button
                    key={`quick-${p.code}`}
                    type="button"
                    className="btn"
                    disabled={pending}
                    onClick={() =>
                      start(async () => {
                        const fd = new FormData();
                        fd.set("plan", p.code);
                        const r = await actionCompleteSandboxCheckout(fd);
                        setMsg(r.detail);
                        setKey(r.plaintextKey || null);
                      })
                    }
                  >
                    Quick {p.label}
                  </button>
                ))}
              </div>
            </>
          )}
        </>
      )}
      {msg && (
        <p className="meta" style={{ marginTop: 12 }}>
          {msg}
        </p>
      )}
      {key && (
        <p className="mono" style={{ marginTop: 8, color: "var(--gm-gold-300)" }}>
          License key (once): {key}
        </p>
      )}
    </div>
  );
}
