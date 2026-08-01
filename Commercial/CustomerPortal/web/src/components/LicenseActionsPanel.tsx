"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { actionActivateLicense, actionCreateLicense } from "@/server/licensing/actions";
import type { LicenseType } from "@/server/licensing/types";
import Link from "next/link";
import { product } from "@/lib/product";

type Props = {
  allowPaidSelfServe: boolean;
};

export function LicenseActionsPanel({ allowPaidSelfServe }: Props) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [message, setMessage] = useState<string | null>(null);
  const [oneTimeKey, setOneTimeKey] = useState<string | null>(null);

  const types = (allowPaidSelfServe
    ? ([...product.planOrder] as LicenseType[])
    : (["trial"] as LicenseType[]));

  return (
    <div className="grid grid-2" style={{ marginBottom: 20 }}>
      <div className="card">
        <h3>1. Generate license key</h3>
        <p className="meta" style={{ marginBottom: 12 }}>
          {allowPaidSelfServe
            ? `Create a trial or paid key here (dev / self-serve mode). Copy once, then paste into ${product.installer.name} during install.`
            : `Create a free trial key here. Paid monthly/yearly/lifetime keys are issued after verified checkout in Billing (or by an admin). Copy the key into ${product.installer.name} — Setup will not finish until the portal marks it Active.`}
        </p>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {types.map((type) => (
            <button
              key={type}
              type="button"
              className="btn btn-primary"
              disabled={pending}
              onClick={() =>
                start(async () => {
                  const r = await actionCreateLicense(type);
                  if (!r.ok) {
                    setMessage(r.error);
                    setOneTimeKey(null);
                    return;
                  }
                  setOneTimeKey(r.plaintextKey);
                  setMessage(
                    `Created ${type} license ${r.license.id} — copy the key into ${product.installer.name} (status stays pending until Setup activates it).`
                  );
                  router.refresh();
                })
              }
            >
              New {type}
            </button>
          ))}
          {!allowPaidSelfServe && (
            <Link href="/portal/billing" className="btn">
              Buy paid plan
            </Link>
          )}
        </div>
        {oneTimeKey && (
          <p className="mono" style={{ marginTop: 12, color: "var(--gm-gold-300)" }}>
            One-time key (paste into installer): {oneTimeKey}
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
        </form>
      </div>
      {message && <p className="meta">{message}</p>}
    </div>
  );
}
