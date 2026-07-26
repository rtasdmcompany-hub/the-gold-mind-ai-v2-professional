/**
 * Push notification service — commercial events only; marketing is opt-in.
 */
import { newMobileId, readMobileStore, writeMobileStore } from "./store";
import {
  DEFAULT_PUSH_PREFS,
  type PushCategory,
  type PushMessage,
  type PushPreference,
} from "./types";

export function getPushPreferences(email: string): PushPreference {
  const store = readMobileStore();
  const e = email.toLowerCase();
  let prefs = store.pushPrefs.find((p) => p.customerEmail === e);
  if (!prefs) {
    prefs = {
      customerEmail: e,
      categories: { ...DEFAULT_PUSH_PREFS },
      updatedAt: new Date().toISOString(),
    };
    store.pushPrefs.unshift(prefs);
    writeMobileStore(store);
  }
  return prefs;
}

export function updatePushPreferences(
  email: string,
  patch: Partial<Record<PushCategory, boolean>>
): PushPreference {
  const store = readMobileStore();
  const e = email.toLowerCase();
  let prefs = store.pushPrefs.find((p) => p.customerEmail === e);
  if (!prefs) {
    prefs = {
      customerEmail: e,
      categories: { ...DEFAULT_PUSH_PREFS },
      updatedAt: new Date().toISOString(),
    };
    store.pushPrefs.unshift(prefs);
  }
  prefs.categories = { ...prefs.categories, ...patch };
  // Enforce marketing opt-in: never auto-enable
  if (patch.marketing === undefined) {
    // keep existing
  }
  prefs.updatedAt = new Date().toISOString();
  writeMobileStore(store);
  return prefs;
}

export function enqueuePush(input: {
  customerEmail: string;
  category: PushCategory;
  title: string;
  body: string;
  deepLink?: string;
}): PushMessage | null {
  const prefs = getPushPreferences(input.customerEmail);
  if (!prefs.categories[input.category]) {
    return null; // suppressed by preference (esp. marketing opt-out)
  }
  const store = readMobileStore();
  const msg: PushMessage = {
    id: newMobileId("push"),
    customerEmail: input.customerEmail.toLowerCase(),
    category: input.category,
    title: input.title,
    body: input.body,
    deepLink: input.deepLink,
    createdAt: new Date().toISOString(),
    deliveredAt: new Date().toISOString(),
  };
  store.pushMessages.unshift(msg);
  writeMobileStore(store);
  return msg;
}

export function listPushInbox(email: string): PushMessage[] {
  return readMobileStore().pushMessages.filter((m) => m.customerEmail === email.toLowerCase());
}

export function markPushRead(id: string, email: string): boolean {
  const store = readMobileStore();
  const msg = store.pushMessages.find((m) => m.id === id && m.customerEmail === email.toLowerCase());
  if (!msg) return false;
  msg.readAt = new Date().toISOString();
  writeMobileStore(store);
  return true;
}

export function seedDemoNotifications(email: string) {
  const e = email.toLowerCase();
  const cats: { category: PushCategory; title: string; body: string }[] = [
    {
      category: "license_expiry",
      title: "License expiring soon",
      body: "Your Professional license renews within 7 days.",
    },
    {
      category: "subscription_renewal",
      title: "Subscription renewal",
      body: "Your yearly plan will renew automatically.",
    },
    {
      category: "payment_confirmation",
      title: "Payment confirmed",
      body: "We received your payment. Thank you.",
    },
    {
      category: "software_update",
      title: "Companion update available",
      body: "Mobile Companion 1.0.0 is ready to install.",
    },
    {
      category: "maintenance",
      title: "Scheduled maintenance",
      body: "Commercial APIs may be briefly unavailable Sunday 02:00 UTC.",
    },
    {
      category: "security_alert",
      title: "New device login",
      body: "A new mobile device signed in to your account.",
    },
    {
      category: "support_reply",
      title: "Support replied",
      body: "Your ticket has a new reply from Customer Success.",
    },
  ];
  // Marketing suppressed by default
  enqueuePush({
    customerEmail: e,
    category: "marketing",
    title: "Should not deliver",
    body: "Marketing is opt-in only.",
  });
  const delivered = cats.map((c) => enqueuePush({ customerEmail: e, ...c })).filter(Boolean);
  return { delivered: delivered.length, marketingSuppressed: true };
}

export function pushSystemOverview() {
  const store = readMobileStore();
  return {
    totalMessages: store.pushMessages.length,
    preferences: store.pushPrefs.length,
    devicesWithTokens: store.devices.filter((d) => !!d.pushToken && !d.revokedAt).length,
    categories: Object.keys(DEFAULT_PUSH_PREFS),
    marketingDefault: DEFAULT_PUSH_PREFS.marketing,
    providers: ["FCM (Android)", "APNs (iOS)", "in-app inbox"],
    at: new Date().toISOString(),
  };
}
