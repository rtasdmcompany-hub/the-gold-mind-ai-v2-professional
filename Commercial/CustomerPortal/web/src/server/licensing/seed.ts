import { createLicense } from "./license-service";
import { activateLicense } from "./license-service";
import { readStore } from "./store";

const DEMO_EMAIL = "demo@goldmind.local";
const ADMIN_EMAIL = "admin@goldmind.local";

/**
 * Seeds demo customer + admin yearly license once (empty store).
 * Returns one-time plaintext keys for console logging in development only.
 */
export function ensureSeedData(): { demoKey?: string; adminKey?: string } {
  const data = readStore();
  if (data.licenses.length > 0) return {};

  const demo = createLicense({
    customerEmail: DEMO_EMAIL,
    customerName: "Demo Customer",
    type: "yearly",
    actorEmail: "system@seed",
  });

  const admin = createLicense({
    customerEmail: ADMIN_EMAIL,
    customerName: "Portal Admin",
    type: "lifetime",
    actorEmail: "system@seed",
  });

  // Pre-activate demo on a virtual device for portal UX
  activateLicense({
    plaintextKey: demo.plaintextKey,
    customerEmail: DEMO_EMAIL,
    deviceName: "Trading-PC-Home",
    deviceFingerprint: "seed-demo-device-fingerprint-v1",
  });

  if (process.env.NODE_ENV !== "production") {
    console.info("[licensing] Seeded demo key (dev only):", demo.plaintextKey);
    console.info("[licensing] Seeded admin key (dev only):", admin.plaintextKey);
  }

  return { demoKey: demo.plaintextKey, adminKey: admin.plaintextKey };
}

export { DEMO_EMAIL, ADMIN_EMAIL };
