import { auth } from "@/auth";
import { ensureSeedData } from "@/server/licensing/seed";
import {
  canAccessAdminConsole,
  hasPermission,
  normalizeAdminRole,
  type AdminPermission,
  type AdminRole,
} from "@/server/admin/roles";
import { logAdminSecurityEvent } from "@/server/admin/security";
import { isDevAdminBypass } from "@/server/security/dev-bypass";

export async function requireSession() {
  await ensureSeedData();
  const session = await auth();
  if (!session?.user?.email) {
    throw new Error("UNAUTHORIZED");
  }
  return {
    email: session.user.email.toLowerCase(),
    name: session.user.name || "Customer",
    role: normalizeAdminRole((session.user as { role?: string }).role || "customer") as AdminRole,
  };
}

export async function requireAdmin() {
  const s = await requireSession();
  if (!canAccessAdminConsole(s.role) && !isDevAdminBypass(s.email)) {
    throw new Error("FORBIDDEN");
  }
  // Legacy: requireAdmin means full admin — prefer requirePermission going forward
  if (
    s.role !== "super_admin" &&
    s.role !== "admin" &&
    !isDevAdminBypass(s.email) &&
    !hasPermission(s.role, "admin.dashboard")
  ) {
    throw new Error("FORBIDDEN");
  }
  return s;
}

export async function requireSupport() {
  const s = await requireSession();
  if (!hasPermission(s.role, "admin.support.read") && !isDevAdminBypass(s.email)) {
    throw new Error("FORBIDDEN");
  }
  return s;
}

export async function requirePermission(permission: AdminPermission, ip = "admin") {
  const s = await requireSession();
  if (isDevAdminBypass(s.email)) return s;
  if (!hasPermission(s.role, permission)) {
    await logAdminSecurityEvent({
      user: s.email,
      ip,
      event: `permission denied: ${permission}`,
      result: "denied",
    });
    throw new Error("FORBIDDEN");
  }
  return s;
}

export async function requireAdminConsole() {
  const s = await requireSession();
  if (!canAccessAdminConsole(s.role) && !isDevAdminBypass(s.email)) {
    throw new Error("FORBIDDEN");
  }
  return s;
}
