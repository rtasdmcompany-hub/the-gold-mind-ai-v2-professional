"use client";

import { useState, useTransition } from "react";
import { actionActivateLicense, actionCreateLicense } from "@/server/licensing/actions";
import type { LicenseType } from "@/server/licensing/types";

export function LicenseActionsPanel() {
  const [pending, start] = useTransition();
  const [message, setMessage] = useState<string | null>(null);
  const [oneTimeKey, setOneTimeKey] = useState<string | null>(null);

  return (
    <div className="grid grid-2" style={{ marginBottom: 20 }}>
      <div className="card">
        <h3>Purchase → Generate (MVP)</h3>
        <p className="meta" style={{ marginBottom: 12 }}>
          Creates a license for your signed-in account. Full key shown once — never stored in the browser afterward.
        </p>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {(["trial", "monthly", "yearly", "lifetime"] as LicenseType[]).map((type) => (
            <button
              key={type}
              type="button"
              className="btn btn-primary"
              disabled={pending}
              onClick={() =>
                start(async () => {
                  const r = await actionCreateLicense(type);
                  setOneTimeKey(r.plaintextKey);
                  setMessage(`Created ${type} license ${r.license.id}`);
                })
              }
            >
              New {type}
            </button>
          ))}
        </div>
        {oneTimeKey && (
          <p className="mono" style={{ marginTop: 12, color: "var(--gm-gold-300)" }}>
            One-time key: {oneTimeKey}
          </p>
        )}
      </div>

      <div className="card">
        <h3>Activate license</h3>
        <form
          className="stack"
          action={(fd) =>
            start(async () => {
              const r = await actionActivateLicense(fd);
              if (r.ok) {
                setMessage(`Activated · device ${r.deviceId}`);
                setOneTimeKey(null);
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
          <input type="hidden" name="deviceFingerprint" value="portal-browser-fingerprint-mvp" />
          <button type="submit" className="btn btn-primary" disabled={pending}>
            Activate
          </button>
        </form>
      </div>
      {message && <p className="meta">{message}</p>}
    </div>
  );
}
