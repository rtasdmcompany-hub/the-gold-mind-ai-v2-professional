import Link from "next/link";
import { UserAvatar } from "@/components/BrandLogo";
import { SignOutButton } from "@/components/SignOutButton";

export function PortalUserBar({
  name,
  email,
  image,
  role,
}: {
  name?: string | null;
  email?: string | null;
  image?: string | null;
  role?: string | null;
}) {
  return (
    <div className="portal-userbar">
      <div className="portal-userbar-info">
        <UserAvatar name={name || email} image={image} size={42} />
        <div>
          <div className="portal-userbar-name">{name || email}</div>
          {role && <div className="portal-userbar-role">{role}</div>}
        </div>
      </div>
      <div className="portal-userbar-actions">
        <Link href="/" className="portal-home-btn">
          Website Home
        </Link>
        <SignOutButton />
      </div>
    </div>
  );
}
