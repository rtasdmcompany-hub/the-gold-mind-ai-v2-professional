import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/auth';
import { createLicense } from '@/server/licensing/license-service';
import type { LicenseType } from '@/server/licensing/types';

export async function GET(req: NextRequest) {
  try {
    console.log("[PayPal Capture] Starting capture process...");
    
    const session = await auth();
    if (!session?.user?.email) {
      console.error("[PayPal Capture] No session found");
      return NextResponse.redirect(new URL('/login', req.url));
    }

    const searchParams = req.nextUrl.searchParams;
    const token = searchParams.get('token'); // PayPal Order ID
    const planParam = searchParams.get('plan') || 'yearly'; 
    
    console.log(`[PayPal Capture] Token: ${token}, Plan: ${planParam}, Email: ${session.user.email}`);

    if (!token) {
      console.error("[PayPal Capture] No token provided");
      return NextResponse.redirect(new URL('/portal/licenses?error=no_token', req.url));
    }

    const clientId = process.env.PAYPAL_CLIENT_ID;
    const clientSecret = process.env.PAYPAL_CLIENT_SECRET;
    const isSandbox = process.env.PAYMENT_FORCE_SANDBOX === "true" || process.env.NODE_ENV !== "production";
    const apiBaseUrl = isSandbox ? "https://api-m.sandbox.paypal.com" : "https://api-m.paypal.com";
    const authHeader = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

    // 1. PayPal se Order Capture karein
    console.log("[PayPal Capture] Capturing order from PayPal...");
    const captureResponse = await fetch(`${apiBaseUrl}/v2/checkout/orders/${token}/capture`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${authHeader}`,
      },
    });

    if (!captureResponse.ok) {
      const err = await captureResponse.text();
      console.error("[PayPal Capture] Capture failed:", err);
      return NextResponse.redirect(new URL('/portal/licenses?error=capture_failed', req.url));
    }

    const captureData = await captureResponse.json();
    console.log("[PayPal Capture] Capture response:", captureData.status);

    // 2. Agar payment successful (COMPLETED) hai, to License generate karein
    if (captureData.status === 'COMPLETED') {
      const purchaseUnit = captureData.purchase_units?.[0] as { custom_id?: string } | undefined;
      const customId = purchaseUnit?.custom_id || session.user.email;
      
      console.log(`[PayPal Capture] Creating license for ${customId} with plan ${planParam}`);
      
      const licenseResult = await createLicense({
        customerEmail: customId.toLowerCase(),
        customerName: session.user.name || customId.split('@')[0],
        type: planParam as LicenseType, // ✅ FIX: 'any' ki jagah 'LicenseType' use kiya
        clientIp: req.headers.get('x-forwarded-for') || 'paypal-capture',
        bypassIpCheck: true,
      });

      if (licenseResult.ok) {
        console.log(`[PayPal Capture] License created successfully: ${licenseResult.license.id}`);
        return NextResponse.redirect(new URL(`/portal/licenses?ok=1`, req.url));
      } else {
        console.error("[PayPal Capture] License creation failed:", licenseResult.error);
        return NextResponse.redirect(new URL('/portal/licenses?error=license_failed', req.url));
      }
    } else {
      console.error("[PayPal Capture] Payment not completed:", captureData.status);
      return NextResponse.redirect(new URL('/portal/licenses?error=not_completed', req.url));
    }
  } catch (error) {
    console.error("[PayPal Capture] Exception:", error);
    return NextResponse.redirect(new URL('/portal/licenses?error=exception', req.url));
  }
}