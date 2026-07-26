"use client";

import { useTransition } from "react";
import {
  actionDeactivateDevice,
  actionRenameDevice,
  actionTransferDevice,
} from "@/server/licensing/actions";

export function DeviceActions({ deviceId, name }: { deviceId: string; name: string }) {
  const [pending, start] = useTransition();

  return (
    <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
      <form
        action={(fd) => start(async () => actionRenameDevice(fd))}
        style={{ display: "flex", gap: 6 }}
      >
        <input type="hidden" name="deviceId" value={deviceId} />
        <input name="name" defaultValue={name} style={{ maxWidth: 140 }} aria-label="Rename" />
        <button type="submit" className="btn" disabled={pending}>
          Rename
        </button>
      </form>
      <form action={(fd) => start(async () => actionDeactivateDevice(fd))}>
        <input type="hidden" name="deviceId" value={deviceId} />
        <button type="submit" className="btn" disabled={pending}>
          Deactivate
        </button>
      </form>
      <form action={(fd) => start(async () => actionTransferDevice(fd))}>
        <input type="hidden" name="deviceId" value={deviceId} />
        <button type="submit" className="btn" disabled={pending}>
          Transfer request
        </button>
      </form>
    </div>
  );
}
