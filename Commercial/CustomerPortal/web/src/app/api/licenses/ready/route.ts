import { NextResponse } from "next/server";
import { licensingStoreReadiness } from "@/server/cloud/cache";
import { product } from "@/lib/product";

/**
 * GET /api/licenses/ready — public. {product.installer.name} checks this before activating.
 * Trial and lifetime share the same rule: durable store must be ready in production.
 */
export async function GET() {
  const readiness = licensingStoreReadiness();
  return NextResponse.json(
    {
      ok: readiness.ready,
      ...readiness,
    },
    { status: readiness.ready ? 200 : 503 }
  );
}
