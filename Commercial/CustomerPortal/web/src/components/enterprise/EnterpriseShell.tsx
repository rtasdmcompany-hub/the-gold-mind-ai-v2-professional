import { EnterpriseNav } from "./EnterpriseNav";
import { EnterpriseFooter } from "./EnterpriseFooter";

export function EnterpriseShell({
  children,
  navTransparent = false,
}: {
  children: React.ReactNode;
  navTransparent?: boolean;
}) {
  return (
    <div className="e-site">
      <EnterpriseNav transparent={navTransparent} />
      <main>{children}</main>
      <EnterpriseFooter />
    </div>
  );
}
