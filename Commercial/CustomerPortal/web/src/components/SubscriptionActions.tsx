"use client";

import { useState, useTransition } from "react";
import { actionCancelSubscription, actionRenewLicense } from "@/server/licensing/actions";
import { useRouter } from "next/navigation";

export function SubscriptionActions({
  licenseId,
  freeRenewAllowed,
}: {
  licenseId: string;
  freeRenewAllowed: boolean;
}) {
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);
  const router = useRouter();

  return (
    <div>
      <div style={{ display: "flex", gap: 8, marginTop: 12, flexWrap: "wrap" }}>
        {freeRenewAllowed ? (
          <form
            action={(fd) =>
              start(async () => {
                const r = await actionRenewLicense(fd);
                setMsg(r.detail);
                if (r.ok) router.refresh();
              })
            }
          >
            <input type="hidden" name="licenseId" value={licenseId} />
            <button type="submit" className="btn btn-primary" disabled={pending}>
              Renew (free — non-production)
            </button>
          </form>
        ) : (
          <button
            type="button"
            className="btn btn-primary"
            disabled={pending}
            onClick={() => router.push("/portal/billing")}
          >
            Renew via Billing
          </button>
        )}
        <form
          action={(fd) =>
            start(async () => {
              const r = await actionCancelSubscription(fd);
              setMsg(r.detail);
              if (r.ok) router.refresh();
            })
          }
        >
          <input type="hidden" name="licenseId" value={licenseId} />
          <button type="submit" className="btn" disabled={pending}>
            Cancel
          </button>
        </form>
      </div>
      {msg && <p className="meta" style={{ marginTop: 8 }}>{msg}</p>}
    </div>
  );
}
