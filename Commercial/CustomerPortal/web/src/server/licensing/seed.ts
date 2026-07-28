import { createLicense } from "./license-service";
import { activateLicense } from "./license-service";
import { ensureStoreLoaded, flushStore, readStore } from "./store";

const DEMO_EMAIL = "demo@goldmind.local";
const ADMIN_EMAIL = "admin@goldmind.local";

/**
 * Seeds demo customer + admin yearly license once (empty store).
 * Always loads durable store first so Vercel cold starts see real activations.
 */
export async function ensureSeedData(): Promise<{ demoKey?: string; adminKey?: string }> {
  await ensureStoreLoaded();
  const data = readStore();
  if (data.licenses.length > 0) return {};

  // Never auto-seed fake licenses in production — customers must generate keys.
  if (process.env.NODE_ENV === "production" || process.env.VERCEL) {
    return {};
  }

  const demo = createLicense({
    customerEmail: DEMO_EMAIL,
    customerName: "Demo Customer",
    type: "yearly",
    actorEmail: "system@seed",
    skipEmail: true,
  });

  const admin = createLicense({
    customerEmail: ADMIN_EMAIL,
    customerName: "Portal Admin",
    type: "lifetime",
    actorEmail: "system@seed",
    skipEmail: true,
  });

  activateLicense({
    plaintextKey: demo.plaintextKey,
    customerEmail: DEMO_EMAIL,
    deviceName: "Trading-PC-Home",
    deviceFingerprint: "seed-demo-device-fingerprint-v1",
    skipEmail: true,
  });

  await flushStore();

  console.info("[licensing] Seeded demo key (dev only):", demo.plaintextKey);
  console.info("[licensing] Seeded admin key (dev only):", admin.plaintextKey);

  return { demoKey: demo.plaintextKey, adminKey: admin.plaintextKey };
}

export { DEMO_EMAIL, ADMIN_EMAIL };
