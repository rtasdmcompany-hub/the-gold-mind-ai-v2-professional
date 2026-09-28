"use client";

import { useState, useTransition } from "react";
import { actionCompleteSandboxCheckout, actionStartCheckout } from "@/server/billing/actions";
import type { PlanCode } from "@/server/billing/types";
import Link from "next/link";

const PLANS: { code: PlanCode; label: string; price: string }[] = [
  { code: "trial", label: "Trial", price: "USD 0.00" },
  { code: "monthly", label: "Monthly", price: "USD 99.00" },
  { code: "yearly", label: "Yearly", price: "USD 899.00" },
  { code: "lifetime", label: "Lifetime", price: "USD 2,499.00" },
];

type Props = {
  sandboxAllowed: boolean;
  paypalConfigured: boolean;
  hasUsedTrial?: boolean;
  hasActivePaidPlan?: boolean;
  activePlanExpiry?: string | null;
};

export function CheckoutPanel({ 
  sandboxAllowed, 
  paypalConfigured, 
  hasUsedTrial = false, 
  hasActivePaidPlan = false,
  activePlanExpiry = null
}: Props) {
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);
  const [key, setKey] = useState<string | null>(null);
  const [showPaidPlanModal, setShowPaidPlanModal] = useState(false);

  const checkoutAvailable = paypalConfigured || sandboxAllowed;

  const handlePlanClick = (planCode: PlanCode) => {
    if (planCode === "trial" && hasUsedTrial) {
      setMsg("You have already used your one-time free trial for this email/IP. Please purchase a paid plan.");
      return;
    }
    
    if (planCode !== "trial" && hasActivePaidPlan) {
      setShowPaidPlanModal(true);
      return;
    }

    start(async () => {
      setKey(null);
      const fd = new FormData();
      fd.set("plan", planCode);
      fd.set("provider", "paypal");
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
    });
  };

  return (
    <>
      {/* ✅ NEW: Paid Plan Already Active Modal */}
      {showPaidPlanModal && (
        <div style={{
          position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: "rgba(0,0,0,0.7)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000
        }}>
          <div className="card" style={{ maxWidth: 500, width: "90%", borderColor: "var(--gm-warning, #ffc107)", backgroundColor: "var(--bg-card, #1a1a1a)" }}>
            <h3 style={{ color: "var(--gm-warning, #d39e00)", marginBottom: 12 }}>⚠️ Active Plan Detected</h3>
            <p className="meta" style={{ lineHeight: 1.6, marginBottom: 20 }}>
              You already have an active paid plan. To prevent billing conflicts, you cannot purchase or generate a new plan until your current one expires. 
              <br /><br />
              {activePlanExpiry && (
                <>Your current plan will expire on <strong>{new Date(activePlanExpiry).toLocaleDateString()}</strong>.<br /><br /></>
              )}
              Please check your <Link href="/portal/licenses" style={{ textDecoration: "underline", color: "var(--gm-primary, #d4af37)" }}>My Licenses</Link> page for details, or contact support if you believe this is an error.
            </p>
            <button 
              className="btn btn-primary" 
              onClick={() => setShowPaidPlanModal(false)}
              style={{ width: "100%" }}
            >
              Understood
            </button>
          </div>
        </div>
      )}

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Checkout · Website Edition</h3>
        {!checkoutAvailable ? (
          <p className="meta" style={{ marginBottom: 0 }}>
            Payments are temporarily unavailable. Please check back shortly or contact Support.
          </p>
        ) : (
          <>
            <p className="meta" style={{ marginBottom: 12 }}>
              Secure checkout via PayPal. Licenses are issued only after a verified payment webhook. MQL5 Market is
              not connected.
            </p>
            {sandboxAllowed && !paypalConfigured && (
              <p className="meta" style={{ marginBottom: 12 }}>
                Live payments are not yet configured — sandbox checkout is available for local/dev testing only.
              </p>
            )}
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
              {PLANS.map((p) => {
                const isTrial = p.code === "trial";
                const isDisabled = (isTrial && hasUsedTrial) || (!isTrial && hasActivePaidPlan);
                const tooltip = isTrial && hasUsedTrial 
                  ? "You have already used your one-time free trial." 
                  : (!isTrial && hasActivePaidPlan ? "You already have an active paid plan." : "");

                return (
                  <button
                    key={p.code}
                    type="button"
                    className="btn btn-primary"
                    disabled={pending || isDisabled}
                    title={tooltip}
                    style={isDisabled ? { opacity: 0.6, cursor: "not-allowed", textDecoration: "line-through" } : {}}
                    onClick={() => handlePlanClick(p.code)}
                  >
                    Buy {p.label} ({p.price})
                  </button>
                );
              })}
            </div>
            {sandboxAllowed && (
              <>
                <p className="meta" style={{ marginTop: 12 }}>
                  Dev shortcut (skips hosted page — authenticated sandbox webhook pipeline only):
                </p>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                  {PLANS.map((p) => {
                     const isTrial = p.code === "trial";
                     const isDisabled = (isTrial && hasUsedTrial) || (!isTrial && hasActivePaidPlan);
                     const tooltip = isTrial && hasUsedTrial 
                      ? "You have already used your one-time free trial." 
                      : (!isTrial && hasActivePaidPlan ? "You already have an active paid plan." : "");

                    return (
                      <button
                        key={`quick-${p.code}`}
                        type="button"
                        className="btn"
                        disabled={pending || isDisabled}
                        title={tooltip}
                        style={isDisabled ? { opacity: 0.6, cursor: "not-allowed", textDecoration: "line-through" } : {}}
                        onClick={() => {
                          if (isDisabled) return;
                          start(async () => {
                            const fd = new FormData();
                            fd.set("plan", p.code);
                            const r = await actionCompleteSandboxCheckout(fd);
                            setMsg(r.detail);
                            setKey(r.plaintextKey || null);
                          });
                        }}
                      >
                        Quick {p.label}
                      </button>
                    );
                  })}
                </div>
              </>
            )}
          </>
        )}
        {msg && (
          <p className="meta" style={{ marginTop: 12, color: msg.includes("unavailable") || msg.includes("already used") ? "var(--gm-error, #dc3545)" : "inherit" }}>
            {msg}
          </p>
        )}
        {key && (
          <p className="mono" style={{ marginTop: 8, color: "var(--gm-gold-300)" }}>
            License key (once): {key}
          </p>
        )}
      </div>
    </>
  );
}