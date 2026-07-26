import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureSprint7Evidence } from "@/server/market/dashboard";
import { latestMarketRun } from "@/server/market/store";
import { actionRunMetadata } from "@/server/market/actions";
import type { StoreMetadata } from "@/server/market/metadata";

export default async function StoreMetadataPage() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.releases.read") && !isDevAdminBypass(actor)) redirect("/portal/admin");
  await ensureSprint7Evidence();
  const payload = latestMarketRun("metadata")?.payload as { metadata: StoreMetadata; score: number } | undefined;
  const m = payload?.metadata;
  const canWrite = hasPermission(role, "admin.releases.write") || isDevAdminBypass(actor);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Store Metadata</h1>
        <p className="page-sub">Score {payload?.score ?? "—"}</p>
      </header>
      {canWrite && (
        <form action={actionRunMetadata} style={{ marginBottom: 16 }}>
          <button type="submit" className="btn btn-primary">
            Refresh metadata
          </button>
        </form>
      )}
      {m && (
        <div className="card">
          <p>
            <strong>Product:</strong> {m.productName}
          </p>
          <p>
            <strong>Version:</strong> {m.version}
          </p>
          <p>
            <strong>Category:</strong> {m.category}
          </p>
          <p>
            <strong>Min MT5 build:</strong> {m.minimumMt5Build}
          </p>
          <p>
            <strong>Short:</strong> {m.shortDescription}
          </p>
          <p>
            <strong>Keywords:</strong> {m.keywords.join(", ")}
          </p>
          <p>
            <strong>Tags:</strong> {m.tags.join(", ")}
          </p>
          <p>
            <strong>Languages:</strong> {m.languageSupport.join(", ")}
          </p>
        </div>
      )}
    </>
  );
}
