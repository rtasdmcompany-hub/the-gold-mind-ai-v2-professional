import {
  ensureSiteContentLoaded,
  getPublicSiteContent,
} from "@/server/site-content/store";
import { EnterpriseNav } from "./EnterpriseNav";
import { EnterpriseFooter } from "./EnterpriseFooter";
import { SiteContentProvider } from "./SiteContentProvider";

export async function EnterpriseShell({
  children,
  navTransparent = false,
}: {
  children: React.ReactNode;
  navTransparent?: boolean;
}) {
  await ensureSiteContentLoaded();
  const siteContent = getPublicSiteContent();

  return (
    <SiteContentProvider initial={siteContent}>
      <div className="e-site">
        <EnterpriseNav transparent={navTransparent} />
        <main>{children}</main>
        <EnterpriseFooter />
      </div>
    </SiteContentProvider>
  );
}
