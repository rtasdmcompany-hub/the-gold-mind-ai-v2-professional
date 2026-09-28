"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { actionActivateLicense, actionCreateLicense } from "@/server/licensing/actions";
import type { LicenseType } from "@/server/licensing/types";
import Link from "next/link";
import { product } from "@/lib/product";

type Props = {
  allowPaidSelfServe: boolean;
  hasUsedTrial?: boolean; // ✅ NEW: Check if user already used trial
};

function remainingTrialDays(expiresAt: string | null | undefined): number | null {
  if (!expiresAt) return null;
  const ms = Date.parse(expiresAt) - Date.now();
  return Math.max(0, Math.ceil(ms / (24 * 60 * 60 * 1000)));
}

export function LicenseActionsPanel({ allowPaidSelfServe, hasUsedTrial = false }: Props) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [message, setMessage] = useState<string | null>(null);
  const [oneTimeKey, setOneTimeKey] = useState<string | null>(null);
  const [showPaidPlanModal, setShowPaidPlanModal] = useState(false); // ✅ NEW: Modal state

  const types = (allowPaidSelfServe
    ? ([...product.planOrder] as LicenseType[])
    : (["trial"] as LicenseType[]));

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
              Please check your <Link href="/portal/licenses" style={{ textDecoration: "underline", color: "var(--gm-primary, #d4af37)" }}>My Licenses</Link> page for your current plan&apos;s expiry date, or contact support if you believe this is an error.
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

      <div className="grid grid-2" style={{ marginBottom: 20 }}>
        <div className="card">
          <h3>1. Get license key</h3>
          <p className="meta" style={{ marginBottom: 12 }}>
            Free trial: <strong>one per email</strong> (and per IP). Regenerating always returns the{" "}
            <strong>same key</strong> with the <strong>original start/expiry</strong> — elapsed days are
            not reset. Paste the key into {product.installer.name}.
            {allowPaidSelfServe
              ? " Paid self-serve minting is enabled in this environment."
              : " Paid monthly/yearly/lifetime keys are issued after verified checkout in Billing (or by an admin)."}
          </p>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            {types.map((type) => {
              // ✅ Disable trial button if already used
              if (type === "trial" && hasUsedTrial) {
                return (
                  <button
                    key={type}
                    type="button"
                    className="btn"
                    disabled={true}
                    style={{ opacity: 0.6, cursor: "not-allowed", textDecoration: "line-through" }}
                    title="You have already used your one-time free trial."
                  >
                    Trial Used
                  </button>
                );
              }

              return (
                <button
                  key={type}
                  type="button"
                  className="btn btn-primary"
                  disabled={pending}
                  onClick={() =>
                    start(async () => {
                      const r = await actionCreateLicense(type);
                      if (!r.ok) {
                        // ✅ Handle specific backend errors
                        if (r.error === "PAID_PLAN_ALREADY_ACTIVE") {
                          setShowPaidPlanModal(true);
                          setMessage(null);
                          return;
                        }
                        if (r.error === "TRIAL_ALREADY_USED") {
                          setMessage("You have already used your one-time free trial for this email/IP. Please purchase a paid plan.");
                          setOneTimeKey(null);
                          return;
                        }

                        const left = remainingTrialDays(r.license?.expiresAt);
                        setMessage(
                          r.error +
                            (r.license
                              ? ` · Existing trial ${r.license.keyMasked} (created ${r.license.createdAt?.slice(0, 10) || "—"}, expires ${r.license.expiresAt?.slice(0, 10) || "—"})${
                                  left === null ? "" : ` · ~${left} day(s) left`
                                }`
                              : "")
                        );
                        setOneTimeKey(null);
                        return;
                      }
                      setOneTimeKey(r.plaintextKey);
                      if (type === "trial" && r.reused) {
                        const left = remainingTrialDays(r.license.expiresAt);
                        setMessage(
                          `Same trial key as before (created ${r.license.createdAt?.slice(0, 10) || "—"}, expires ${r.license.expiresAt?.slice(0, 10) || "—"})${
                            left === null ? "" : ` · ~${left} day(s) remaining`
                          }. Dates are not reset.`
                        );
                      } else {
                        setMessage(
                          `Created ${type} license ${r.license.id} — copy the key into ${product.installer.name} (status stays pending until Setup activates it).`
                        );
                      }
                      router.refresh();
                    })
                  }
                >
                  {type === "trial" ? "Get trial key" : `New ${type}`}
                </button>
              );
            })}
            {!allowPaidSelfServe && (
              <Link href="/portal/billing" className="btn">
                Buy paid plan
              </Link>
            )}
          </div>
          {oneTimeKey && (
            <p className="mono" style={{ marginTop: 12, color: "var(--gm-gold-300)" }}>
              License key (paste into installer): {oneTimeKey}
            </p>
          )}
        </div>

        <div className="card">
          <h3>2. Re-check key in browser (optional)</h3>
          <p className="meta" style={{ marginBottom: 12 }}>
            Preferred path is {product.installer.name} during installation (binds your Windows PC). Use this only to
            re-check or recover a key in the portal after Setup already activated it.
          </p>
          <form
            className="stack"
            action={(fd) =>
              start(async () => {
                const r = await actionActivateLicense(fd);
                if (r.ok) {
                  setMessage(`Activated · device ${r.deviceId}`);
                  setOneTimeKey(null);
                  router.refresh();
                } else {
                  setMessage(`Activation failed: ${r.error}`);
                }
              })
            }
          >
            <div className="field">
              <label htmlFor="licenseKey">License key</label>
              <input id="licenseKey" name="licenseKey" required placeholder="TGM-…" defaultValue={oneTimeKey || ""} />
            </div>
            <div className="field">
              <label htmlFor="deviceName">Device name</label>
              <input id="deviceName" name="deviceName" defaultValue="Portal Workstation" />
            </div>
            <input type="hidden" name="deviceFingerprint" value="portal-browser-fingerprint" />
            <button type="submit" className="btn btn-primary" disabled={pending}>
              Activate in portal
            </button>
            <p className="meta" style={{ marginTop: 8 }}>
              Soft activate only — Windows Setup will replace this seat with your PC automatically.
            </p>
          </form>
        </div>
        {message && <p className="meta" style={{ color: "var(--gm-error, #dc3545)", marginTop: 12, fontWeight: 500 }}>{message}</p>}
      </div>
    </>
  );
}