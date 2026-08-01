"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import Link from "next/link";
import { brand } from "@/lib/brand";

const SESSION_KEY = "tgm_investor_alert_dismissed";

/**
 * Homepage investor / risk alert — landscape layout, THE GOLD MIND theme.
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
        className="e-alert-modal e-alert-modal--landscape"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="e-alert-modal-chrome">
          <header className="e-alert-modal-top">
            <div className="e-alert-modal-brand">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="/brand/the-gold-mind-logo-header.png"
                alt={brand.brandName}
                className="e-alert-modal-logo"
                width={220}
                height={52}
              />
            </div>

            <div className="e-alert-modal-icon" aria-hidden="true">
              <svg className="e-alert-modal-megaphone" viewBox="0 0 96 96" width="72" height="72">
                <defs>
                  <linearGradient id="tgmHorn" x1="12" y1="20" x2="78" y2="72">
                    <stop offset="0%" stopColor="#fff3c4" />
                    <stop offset="45%" stopColor="#e8c547" />
                    <stop offset="100%" stopColor="#9a7209" />
                  </linearGradient>
                  <linearGradient id="tgmRing" x1="0" y1="0" x2="96" y2="96">
                    <stop offset="0%" stopColor="#ffe28a" />
                    <stop offset="100%" stopColor="#b8860b" />
                  </linearGradient>
                </defs>
                <circle cx="48" cy="48" r="46" fill="#0a0906" stroke="url(#tgmRing)" strokeWidth="3" />
                {/* Classic megaphone / announcement horn */}
                <path
                  d="M28 40h10l22-14v44L38 56H28c-4 0-7-3-7-7v-2c0-4 3-7 7-7z"
                  fill="url(#tgmHorn)"
                  stroke="#6b5208"
                  strokeWidth="1.2"
                />
                <path d="M38 56v10c0 4 3 7 7 4" fill="none" stroke="#c9a227" strokeWidth="3.5" strokeLinecap="round" />
                <circle cx="31" cy="48" r="3" fill="#5c4508" />
                {/* Sound waves = announcement */}
                <path d="M66 34c6 5 9 10 9 14s-3 9-9 14" fill="none" stroke="#ffe28a" strokeWidth="3" strokeLinecap="round" />
                <path d="M72 28c9 7 13 14 13 20s-4 13-13 20" fill="none" stroke="#e8c547" strokeWidth="2.5" strokeLinecap="round" opacity="0.85" />
              </svg>
              <span className="e-alert-modal-icon-label">Announcement</span>
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
          </header>

          <div className="e-alert-modal-card">
            <h2 id={titleId} className="e-alert-modal-title">
              Investor Alert
            </h2>
            <div className="e-alert-modal-body">
              <p>
                Stay cautious of unauthorized websites, social pages, or Telegram/WhatsApp groups claiming to sell,
                rent, or “guarantee profits” with <strong>{brand.productFullName}</strong> or any imitation of{" "}
                {brand.brandName}.
              </p>
              <p>
                {brand.productName} is licensed MetaTrader 5 software — available only via the official{" "}
                {brand.brandName} website and Customer Portal. Trading involves substantial risk of loss; past results
                do not guarantee future performance.
              </p>
              <p>
                Never share license keys, portal passwords, or broker credentials. Download only from this site. Verify
                via{" "}
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
            <div className="e-alert-modal-actions">
              <p className="e-alert-modal-footer">Trade responsibly. Stay vigilant.</p>
              <button type="button" className="e-btn e-btn-primary e-alert-modal-cta" onClick={dismiss}>
                I understand
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
