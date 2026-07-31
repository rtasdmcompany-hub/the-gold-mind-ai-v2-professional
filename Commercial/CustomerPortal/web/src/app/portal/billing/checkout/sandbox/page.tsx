import { auth } from "@/auth";
import { completeSandboxCheckout } from "@/server/billing/billing-service";
import { isSandboxCheckoutAllowed } from "@/server/billing/config";
import type { PlanCode } from "@/server/billing/types";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function SandboxCheckoutPage({
  searchParams,
}: {
  searchParams: Promise<{ plan?: string; email?: string; checkoutId?: string }>;
}) {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  if (!isSandboxCheckoutAllowed()) redirect("/portal/billing");
  const sp = await searchParams;
  const plan = (sp.plan || "monthly") as PlanCode;

  async function pay() {
    "use server";
    const s = await auth();
    if (!s?.user?.email) redirect("/login");
    await completeSandboxCheckout({
      plan,
      customerEmail: s.user.email,
      customerName: s.user.name || "Customer",
    });
    redirect("/portal/billing?ok=1");
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>Sandbox Checkout</h1>
        <p>
          Simulated Paddle/PayPal checkout for Website Edition development. Completing payment fires an authenticated,
          idempotent sandbox webhook into the billing engine.
        </p>
        <p className="meta">Plan: {plan}</p>
        <form action={pay}>
          <button type="submit" className="btn btn-primary" style={{ width: "100%" }}>
            Pay (sandbox)
          </button>
        </form>
        <p className="note">
          <Link href="/portal/billing">Cancel · back to Billing</Link>
        </p>
      </div>
    </div>
  );
}
