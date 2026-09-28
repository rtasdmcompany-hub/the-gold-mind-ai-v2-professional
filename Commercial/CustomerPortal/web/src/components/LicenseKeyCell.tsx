"use client";

import { useState } from "react";
import { actionRevealLicenseKey } from "@/server/licensing/actions";

type Props = {
  licenseId: string;
  keyMasked: string;
};

export function LicenseKeyCell({ licenseId, keyMasked }: Props) {
  const [revealedKey, setRevealedKey] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  const handleReveal = async () => {
    setLoading(true);
    const res = await actionRevealLicenseKey(licenseId);
    setLoading(false);
    if (res.ok && res.key) {
      setRevealedKey(res.key);
    } else {
      alert("Could not reveal key: " + res.error);
    }
  };

  const handleCopy = () => {
    if (revealedKey) {
      navigator.clipboard.writeText(revealedKey);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      <div className="mono" style={{ minWidth: 140, color: revealedKey ? "var(--gm-gold-300)" : "inherit" }}>
        {revealedKey || keyMasked}
      </div>
      <div style={{ display: "flex", gap: 4 }}>
        {!revealedKey ? (
          <button 
            className="btn" 
            style={{ padding: "2px 8px", fontSize: 12, height: 28 }} 
            onClick={handleReveal} 
            disabled={loading}
            title="Reveal full license key"
          >
            {loading ? "..." : "Show"}
          </button>
        ) : (
          <button 
            className="btn" 
            style={{ 
              padding: "2px 8px", 
              fontSize: 12, 
              height: 28,
              backgroundColor: copied ? "var(--gm-success, #28a745)" : "",
              color: copied ? "#fff" : ""
            }} 
            onClick={handleCopy}
            title="Copy to clipboard"
          >
            {copied ? "Copied!" : "Copy"}
          </button>
        )}
      </div>
    </div>
  );
}