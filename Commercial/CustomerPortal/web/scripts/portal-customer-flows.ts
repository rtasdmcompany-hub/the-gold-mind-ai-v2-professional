/**
 * Focused portal production-behavior checks (no Core Trading Engine).
 * Run: npx tsx scripts/portal-customer-flows.ts
 */
import assert from "node:assert/strict";
import {
  isFreeRenewAllowed,
  isSandboxCheckoutAllowed,
  isSelfServeLicenseTypeAllowed,
  isSelfServePaidLicenseAllowed,
  resolveCheckoutProvider,
  getProviderConfigStatus,
} from "../src/server/billing/config";
import { isTradeAlertsEnabled } from "../src/server/accounts/service";
import type { AccountRecord } from "../src/server/accounts/store";

function section(name: string) {
  console.log(`\n== ${name} ==`);
}

function setEnv(key: string, value: string | undefined) {
  const env = process.env as Record<string, string | undefined>;
  if (value === undefined) delete env[key];
  else env[key] = value;
}

async function main() {
  const prev = { ...process.env };
  let failed = 0;

  function check(label: string, fn: () => void) {
    try {
      fn();
      console.log(`PASS  ${label}`);
    } catch (e) {
      failed++;
      console.error(`FAIL  ${label}:`, e instanceof Error ? e.message : e);
    }
  }

  section("Self-serve license gating");
  setEnv("NODE_ENV", "production");
  setEnv("PORTAL_ALLOW_SELF_SERVE_LICENSE", undefined);
  check("trial allowed in production", () => {
    assert.equal(isSelfServeLicenseTypeAllowed("trial"), true);
  });
  check("paid blocked in production by default", () => {
    assert.equal(isSelfServePaidLicenseAllowed(), false);
    assert.equal(isSelfServeLicenseTypeAllowed("monthly"), false);
  });
  setEnv("PORTAL_ALLOW_SELF_SERVE_LICENSE", "true");
  check("paid allowed with override", () => {
    assert.equal(isSelfServeLicenseTypeAllowed("yearly"), true);
  });
  setEnv("PORTAL_ALLOW_SELF_SERVE_LICENSE", undefined);

  section("Sandbox / renew gating");
  setEnv("NODE_ENV", "production");
  setEnv("PAYMENT_FORCE_SANDBOX", undefined);
  setEnv("PORTAL_ALLOW_FREE_RENEW", undefined);
  check("sandbox blocked in production", () => {
    assert.equal(isSandboxCheckoutAllowed(), false);
  });
  check("free renew blocked in production", () => {
    assert.equal(isFreeRenewAllowed(), false);
  });
  setEnv("NODE_ENV", "development");
  check("sandbox allowed in development", () => {
    assert.equal(isSandboxCheckoutAllowed(), true);
  });
  check("free renew allowed in development", () => {
    assert.equal(isFreeRenewAllowed(), true);
  });

  section("Checkout provider resolve (fail-closed)");
  setEnv("NODE_ENV", "production");
  setEnv("PAYMENT_FORCE_SANDBOX", undefined);
  setEnv("PADDLE_VENDOR_ID", undefined);
  setEnv("PADDLE_WEBHOOK_SECRET", undefined);
  setEnv("PAYPAL_CLIENT_ID", undefined);
  setEnv("STRIPE_SECRET_KEY", undefined);
  check("unconfigured paddle fails in production", () => {
    const r = resolveCheckoutProvider("paddle");
    assert.equal(r.ok, false);
    assert.match(r.error || "", /UNCONFIGURED|PADDLE/);
  });
  check("sandbox provider rejected in production", () => {
    const r = resolveCheckoutProvider("sandbox");
    assert.equal(r.ok, false);
  });
  setEnv("NODE_ENV", "development");
  check("dev falls back to sandbox when paddle missing", () => {
    const r = resolveCheckoutProvider("paddle");
    assert.equal(r.ok, true);
    assert.equal(r.provider, "sandbox");
  });

  section("Provider status honesty");
  setEnv("NODE_ENV", "production");
  check("paddle status reports missing vendor", () => {
    const s = getProviderConfigStatus("paddle");
    assert.equal(s.configured, false);
    assert.match(s.detail, /PADDLE_VENDOR_ID/);
  });

  section("Trade alert prefs");
  check("default ON when account missing", () => {
    assert.equal(isTradeAlertsEnabled(null), true);
  });
  check("respects explicit false", () => {
    const acc = { tradeAlertsEnabled: false } as AccountRecord;
    assert.equal(isTradeAlertsEnabled(acc), false);
  });
  check("unset preference defaults ON", () => {
    const acc = {} as AccountRecord;
    assert.equal(isTradeAlertsEnabled(acc), true);
  });

  // restore env
  for (const k of Object.keys(process.env)) {
    if (!(k in prev)) delete process.env[k];
  }
  Object.assign(process.env, prev);

  console.log(`\n${failed === 0 ? "OK" : "FAILED"} — ${failed} failure(s)`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
