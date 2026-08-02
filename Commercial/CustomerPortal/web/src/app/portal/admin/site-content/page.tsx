import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { SiteContentAdminClient } from "@/components/admin/SiteContentAdminClient";
import {
  ensureSiteContentLoaded,
  isSiteContentDurable,
  readSiteContent,
} from "@/server/site-content/store";
import { mediaUploadHints } from "@/server/site-content/media";

export const dynamic = "force-dynamic";

export default async function AdminSiteContentPage() {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(email)) {
    redirect("/portal/admin");
  }

  await ensureSiteContentLoaded();
  const content = readSiteContent();
  const canWrite = hasPermission(role, "admin.launch.write") || isDevAdminBypass(email);
  const hints = mediaUploadHints();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Site Content Manager</h1>
        <p className="page-sub">
          cPanel-style editor · phone playlist/relay, hero, logos, header/footer · last saved{" "}
          {content.updatedAt && content.updatedAt !== new Date(0).toISOString()
            ? content.updatedAt
            : "defaults (not saved yet)"}{" "}
          · store {isSiteContentDurable() ? "durable (Upstash / Blob)" : "ephemeral / local file"}
        </p>
        <p className="meta">
          Open sections: <a href="#phone-ads">Video playlist</a> · <a href="#hero">Hero</a> ·{" "}
          <a href="#logos">Logos</a> · <a href="#copy">Header &amp; footer</a>
        </p>
      </header>

      <SiteContentAdminClient initial={content} canWrite={canWrite} uploadHints={hints} />
    </>
  );
}
