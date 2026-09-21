import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { DeviceActions } from "@/components/DeviceActions";
import { ensureSeedData } from "@/server/licensing/seed";
import { listDevicesForCustomer } from "@/server/licensing/device-service";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { redirect } from "next/navigation";

export default async function DevicesPage() {
  await ensureSeedData();
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  
  const devices = listDevicesForCustomer(session.user.email); // Ye abhi sync hai, isliye await nahi
  // ✅ FIX: Yahan 'await' add kiya gaya hai
  const licenses = await listLicensesForCustomer(session.user.email);
  
  const limit = licenses.find((l) => l.status === "active" || l.status === "grace")?.seatsMax;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Devices</h1>
        <p className="page-sub">
          Registration, rename, deactivation, transfer request · seat limit {limit ?? "—"}. Audit history retained
          server-side.
        </p>
      </header>

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Device Name</th>
              <th>Fingerprint</th>
              <th>Activation Date</th>
              <th>Last Active</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {devices.length === 0 && (
              <tr>
                <td colSpan={6}>No devices — activate a license from My Licenses.</td>
              </tr>
            )}
            {devices.map((d) => (
              <tr key={d.id}>
                <td>
                  {d.name}
                  <div className="meta">{d.id}</div>
                </td>
                <td className="mono">{d.fingerprintMasked}</td>
                <td>{d.activationDate.slice(0, 19).replace("T", " ")}</td>
                <td>{d.lastActiveAt.slice(0, 19).replace("T", " ")}</td>
                <td>
                  <StatusBadge status={d.status} />
                </td>
                <td>
                  <DeviceActions deviceId={d.id} name={d.name} status={d.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
