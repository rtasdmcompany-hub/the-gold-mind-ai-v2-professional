"use client";

import { useState, useTransition } from "react";
import {
  actionCompleteDeviceTransfer,
  actionDeactivateDevice,
  actionRenameDevice,
  actionTransferDevice,
} from "@/server/licensing/actions";

export function DeviceActions({
  deviceId,
  name,
  status,
}: {
  deviceId: string;
  name: string;
  status: string;
}) {
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);

  return (
    <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
      <form
        action={(fd) =>
          start(async () => {
            const r = await actionRenameDevice(fd);
            setMsg(r.ok ? "Renamed" : r.error || "Rename failed");
          })
        }
        style={{ display: "flex", gap: 6 }}
      >
        <input type="hidden" name="deviceId" value={deviceId} />
        <input name="name" defaultValue={name} style={{ maxWidth: 140 }} aria-label="Rename" />
        <button type="submit" className="btn" disabled={pending}>
          Rename
        </button>
      </form>
      {(status === "active" || status === "pending_transfer") && (
        <form
          action={(fd) =>
            start(async () => {
              const r = await actionDeactivateDevice(fd);
              setMsg(r.ok ? "Deactivated" : r.error || "Deactivate failed");
            })
          }
        >
          <input type="hidden" name="deviceId" value={deviceId} />
          <button type="submit" className="btn" disabled={pending}>
            Deactivate
          </button>
        </form>
      )}
      {status === "active" && (
        <form
          action={(fd) =>
            start(async () => {
              const r = await actionTransferDevice(fd);
              setMsg(r.ok ? "Transfer requested — seat freed for new activation" : r.error || "Transfer failed");
            })
          }
        >
          <input type="hidden" name="deviceId" value={deviceId} />
          <button type="submit" className="btn" disabled={pending}>
            Transfer request
          </button>
        </form>
      )}
      {status === "pending_transfer" && (
        <form
          action={(fd) =>
            start(async () => {
              const r = await actionCompleteDeviceTransfer(fd);
              setMsg(r.ok ? "Transfer completed" : r.error || "Complete failed");
            })
          }
        >
          <input type="hidden" name="deviceId" value={deviceId} />
          <button type="submit" className="btn btn-primary" disabled={pending}>
            Complete transfer
          </button>
        </form>
      )}
      {msg && <span className="meta">{msg}</span>}
    </div>
  );
}
