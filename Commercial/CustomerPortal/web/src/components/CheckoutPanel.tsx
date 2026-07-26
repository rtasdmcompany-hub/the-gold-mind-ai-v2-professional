"use client";

import { useState, useTransition } from "react";
import { actionCompleteSandboxCheckout, actionStartCheckout } from "@/server/billing/actions";
import type { PlanCode, PaymentProviderId } from "@/server/billing/types";

const PLANS: { code: PlanCode; label: string; price: string }[] = [
  { code: "trial", label: "Trial", price: "USD 0.00" },
  { code: "monthly", label: "Monthly", price: "USD 99.00" },
  { code: "yearly", label: "Yearly", price: "USD 899.00" },
  { code: "lifetime", label: "Lifetime", price: "USD 2,499.00" },
];

const PROVIDERS: { id: PaymentProviderId | ""; label: string }[] = [
  { id: "", label: "Primary (env)" },
  { id: "paddle", label: "Paddle" },
  { id: "paypal", label: "PayPal" },
  { id: "sandbox", label: "Sandbox" },
];

/**
 * Website Edition checkout entry.
 * Business logic goes through PaymentPort (actionStartCheckout) — never PSP SDKs.
 * MQL5 Market Edition is not connected to this panel.
 */
export function CheckoutPanel() {
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);
  const [key, setKey] = useState<string | null>(null);
  const [provider, setProvider] = useState<PaymentProviderId | "">("");

  return (
    <div className="card" style={{ marginBottom: 16 }}>
      <h3>Checkout · Website Edition</h3>
      <p className="meta" style={{ marginBottom: 12 }}>
        Provider-abstracted checkout (Paddle primary · PayPal secondary · Sandbox for local · Stripe future). MQL5
        Market is not connected to this flow.
      </p>
      <label className="meta" style={{ display: "block", marginBottom: 8 }}>
        Provider{" "}
        <select
          value={provider}
          onChange={(e) => setProvider(e.target.value as PaymentProviderId | "")}
          disabled={pending}
          style={{ marginLeft: 8 }}
        >
          {PROVIDERS.map((p) => (
            <option key={p.label} value={p.id}>
              {p.label}
            </option>
          ))}
        </select>
      </label>
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
                if (provider) fd.set("provider", provider);
                const session = await actionStartCheckout(fd);
                setMsg(`Checkout ${session.checkoutId} via ${session.provider} · ${session.currency} ${(session.amountCents / 100).toFixed(2)}`);
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
      <p className="meta" style={{ marginTop: 12 }}>
        Dev shortcut (skips hosted page — still runs authenticated sandbox webhook pipeline):
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
