import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/auth';
import { createLicense } from '@/server/licensing/license-service';
import type { PlanCode } from '@/server/billing/types';

export async function GET(req: NextRequest) {
  try {
    const session = await auth();
    if (!session?.user?.email) {
      return NextResponse.redirect(new URL('/login', req.url));
    }

    const searchParams = req.nextUrl.searchParams;
    const token = searchParams.get('token'); // PayPal Order ID
    const plan = (searchParams.get('plan') || 'monthly') as PlanCode;

    if (!token) {
      return NextResponse.redirect(new URL('/portal/licenses?error=no_token', req.url));
    }

    const clientId = process.env.PAYPAL_CLIENT_ID;
    const clientSecret = process.env.PAYPAL_CLIENT_SECRET;
    const isSandbox = process.env.PAYMENT_FORCE_SANDBOX === "true" || process.env.NODE_ENV !== "production";
    const apiBaseUrl = isSandbox ? "https://api-m.sandbox.paypal.com" : "https://api-m.paypal.com";
    const authHeader = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

    // 1. PayPal se Order Capture karein (Payment complete karein)
    const captureResponse = await fetch(`${apiBaseUrl}/v2/checkout/orders/${token}/capture`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${authHeader}`,
      },
    });

    if (!captureResponse.ok) {
      const err = await captureResponse.text();
      console.error("[PayPal Capture] Failed:", err);
      return NextResponse.redirect(new URL('/portal/licenses?error=capture_failed', req.url));
    }

    const captureData = await captureResponse.json();

    // 2. Agar payment successful (COMPLETED) hai, to License generate karein
    if (captureData.status === 'COMPLETED') {
      const customId = (captureData.purchase_units?.[0] as { custom_id?: string })?.custom_id || session.user.email;
      
      const licenseResult = await createLicense({
        customerEmail: customId.toLowerCase(),
        customerName: session.user.name || customId.split('@')[0],
        type: plan,
        clientIp: req.headers.get('x-forwarded-for') || 'paypal-capture',
        bypassIpCheck: true,
      });

      if (licenseResult.ok) {
        // License ban gaya, user ko licenses page par bhej dein
        return NextResponse.redirect(new URL(`/portal/licenses?ok=1`, req.url));
      } else {
        console.error("[PayPal Capture] License creation failed:", licenseResult.error);
        return NextResponse.redirect(new URL('/portal/licenses?error=license_failed', req.url));
      }
    } else {
      return NextResponse.redirect(new URL('/portal/licenses?error=not_completed', req.url));
    }
  } catch (error) {
    console.error("[PayPal Capture] Exception:", error);
    return NextResponse.redirect(new URL('/portal/licenses?error=exception', req.url));
  }
}