import { NextResponse } from "next/server";
import { requireAdmin } from "@/server/licensing/session";
import { listAllLicensesAdmin } from "@/server/licensing/license-service";
import { listAllDevicesAdmin } from "@/server/licensing/device-service";
import { listAllSubscriptionsAdmin } from "@/server/licensing/subscription-service";
import { appendAudit, mutateStore, readStore } from "@/server/licensing/store";
import { maskLicenseKey } from "@/server/licensing/crypto";

export async function GET(req: Request) {
  try {
    const admin = await requireAdmin();
    const url = new URL(req.url);
    const q = (url.searchParams.get("q") || "").toLowerCase();

    mutateStore((data) => {
      appendAudit(data, {
        actorEmail: admin.email,
        action: "admin.lookup",
        entityType: "system",
        entityId: "admin-console",
        detail: `Admin lookup q=${q || "(all)"}`,
      });
    });

    // ✅ Sirf licenses ko await karein (kyunke ye async hai)
    let licenses = await listAllLicensesAdmin();
    
    // ❌ Ye bina await ke (kyunke ye abhi sync hain)
    let devices = listAllDevicesAdmin();
    let subscriptions = listAllSubscriptionsAdmin();
    
    const audit = readStore().audit.slice(0, 100);

    if (q) {
      licenses = licenses.filter(
        (l) => l.customerEmail.includes(q) || l.id.includes(q) || l.keyPrefix.toLowerCase().includes(q)
      );
      const ids = new Set(licenses.map((l) => l.id));
      const emails = new Set(licenses.map((l) => l.customerEmail));
      devices = devices.filter((d) => ids.has(d.licenseId) || d.customerEmail.includes(q));
      subscriptions = subscriptions.filter((s) => ids.has(s.licenseId) || emails.has(s.customerEmail));
    }

    return NextResponse.json({
      licenses: licenses.map((l) => ({
        id: l.id,
        customerEmail: l.customerEmail,
        customerName: l.customerName,
        keyMasked: maskLicenseKey(`${l.keyPrefix}-****-****-${l.keyLast4}`),
        type: l.type,
        status: l.status,
        seatsMax: l.seatsMax,
        expiresAt: l.expiresAt,
        activatedAt: l.activatedAt,
        lastValidatedAt: l.lastValidatedAt,
      })),
      devices: devices.map((d) => ({
        id: d.id,
        licenseId: d.licenseId,
        customerEmail: d.customerEmail,
        name: d.name,
        status: d.status,
        activationDate: d.activationDate,
        lastActiveAt: d.lastActiveAt,
      })),
      subscriptions,
      audit,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    const status = msg === "UNAUTHORIZED" ? 401 : msg === "FORBIDDEN" ? 403 : 500;
    return NextResponse.json({ error: msg }, { status });
  }
}
