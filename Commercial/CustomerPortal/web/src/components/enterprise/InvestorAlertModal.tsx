"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import Link from "next/link";
import { brand } from "@/lib/brand";

const SESSION_KEY = "tgm_investor_alert_dismissed";

/**
 * Homepage investor / risk alert — PMEX-style layout, THE GOLD MIND theme.
 * Shows once per browser session after dismiss.
 */
export function InvestorAlertModal() {
  const titleId = useId();
  const closeRef = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);

  const dismiss = useCallback(() => {
    try {
      sessionStorage.setItem(SESSION_KEY, "1");
    } catch {
      /* ignore */
    }
    setOpen(false);
  }, []);

  useEffect(() => {
    try {
      if (sessionStorage.getItem(SESSION_KEY) === "1") return;
    } catch {
      /* private mode */
    }
    const t = window.setTimeout(() => setOpen(true), 280);
    return () => window.clearTimeout(t);
  }, []);

  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") dismiss();
    };
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", onKey);
    };
  }, [open, dismiss]);

  if (!open) return null;

  return (
    <div className="e-alert-overlay" role="presentation" onClick={dismiss}>
      <div
        className="e-alert-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="e-alert-modal-chrome">
          <div className="e-alert-modal-brand">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/brand/the-gold-mind-logo-nav.png"
              alt=""
              className="e-alert-modal-logo"
              width={120}
              height={28}
            />
          </div>
          <button
            ref={closeRef}
            type="button"
            className="e-alert-modal-close"
            onClick={dismiss}
            aria-label="Close alert"
          >
            ×
          </button>

          <div className="e-alert-modal-icon" aria-hidden="true">
            <svg className="e-alert-modal-megaphone" viewBox="0 0 64 64" width="56" height="56">
              <circle cx="32" cy="32" r="30" fill="rgba(5,5,5,0.92)" stroke="rgba(232,197,71,0.55)" strokeWidth="2" />
              <path
                d="M18 28h8l14-10v28L26 36h-8a4 4 0 0 1-4-4v0a4 4 0 0 1 4-4z"
                fill="url(#tgmAlertGold)"
              />
              <path d="M26 36v8a4 4 0 0 0 4 2" fill="none" stroke="#c9a227" strokeWidth="2.5" strokeLinecap="round" />
              <path d="M44 24c3 2.5 5 6 5 8s-2 5.5-5 8" fill="none" stroke="#e8c547" strokeWidth="2" strokeLinecap="round" />
              <defs>
                <linearGradient id="tgmAlertGold" x1="14" y1="18" x2="42" y2="46">
                  <stop offset="0%" stopColor="#ffe28a" />
                  <stop offset="55%" stopColor="#e8c547" />
                  <stop offset="100%" stopColor="#b8860b" />
                </linearGradient>
              </defs>
            </svg>
          </div>

          <div className="e-alert-modal-card">
            <h2 id={titleId} className="e-alert-modal-title">
              Investor Alert
            </h2>
            <div className="e-alert-modal-body">
              <p>
                The general public is advised to remain cautious of unauthorized websites, social-media pages,
                Telegram/WhatsApp groups, or individuals claiming to sell, rent, or “guarantee profits” with{" "}
                <strong>{brand.productFullName}</strong> or any imitation of {brand.brandName}.
              </p>
              <p>
                {brand.productName} is licensed MetaTrader 5 trading software distributed only through the official{" "}
                {brand.brandName} website and Customer Portal. Past performance does not guarantee future results.
                Automated trading involves substantial risk of loss and is not suitable for every investor.
              </p>
              <p>
                Never share license keys, portal passwords, or broker credentials with third parties. Download
                installers only from this official site. For verification, use{" "}
                <Link href="/contact" className="e-alert-modal-link" onClick={dismiss}>
                  Contact
                </Link>
                ,{" "}
                <Link href="/risk" className="e-alert-modal-link" onClick={dismiss}>
                  Risk Disclosure
                </Link>
                , or{" "}
                <Link href="/disclaimer" className="e-alert-modal-link" onClick={dismiss}>
                  Disclaimer
                </Link>
                .
              </p>
            </div>
            <p className="e-alert-modal-footer">Trade responsibly. Stay vigilant.</p>
            <button type="button" className="e-btn e-btn-primary e-alert-modal-cta" onClick={dismiss}>
              I understand
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
