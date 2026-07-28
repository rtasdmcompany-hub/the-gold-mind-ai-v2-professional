import {
  getAccountByEmail,
  hashPassword,
  hashToken,
  newAccountId,
  newVerifyToken,
  saveAccount,
  verifyPassword,
  type AccountRecord,
} from "./store";
import { sendTransactionalEmail } from "./mailer";

function baseUrl(): string {
  return (
    process.env.AUTH_URL ||
    process.env.NEXTAUTH_URL ||
    "https://the-gold-mind-ai-v2-professional.vercel.app"
  ).replace(/\/$/, "");
}

export type SignupResult =
  | { ok: true; email: string; emailSent: boolean; mailError?: string; verifyUrl?: string }
  | { ok: false; error: string };

export async function registerAccount(input: {
  name: string;
  email: string;
  password: string;
}): Promise<SignupResult> {
  const email = input.email.trim().toLowerCase();
  const name = input.name.trim();
  const password = input.password;

  if (!name || name.length < 2) return { ok: false, error: "Please enter your full name." };
  if (!email || !email.includes("@")) return { ok: false, error: "Please enter a valid email." };
  if (password.length < 8) return { ok: false, error: "Password must be at least 8 characters." };

  const existing = await getAccountByEmail(email);
  if (existing?.emailVerifiedAt) {
    return { ok: false, error: "An account with this email already exists. Please sign in." };
  }

  const token = newVerifyToken();
  const now = new Date().toISOString();
  const expires = new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString();

  const account: AccountRecord = {
    id: existing?.id || newAccountId(),
    email,
    name,
    passwordHash: hashPassword(password),
    emailVerifiedAt: null,
    verifyTokenHash: hashToken(token),
    verifyTokenExpiresAt: expires,
    provider: "credentials",
    tradeAlertsEnabled: existing?.tradeAlertsEnabled ?? true,
    createdAt: existing?.createdAt || now,
    updatedAt: now,
  };
  await saveAccount(account);

  const verifyUrl = `${baseUrl()}/verify-email?token=${token}&email=${encodeURIComponent(email)}`;
  const subject = "Confirm your email — THE GOLD MIND PROFESSIONAL";
  const text = [
    `Confirm your THE GOLD MIND PROFESSIONAL account.`,
    ``,
    `Open this link to verify your email (required before sign-in):`,
    verifyUrl,
    ``,
    `This link expires in 24 hours.`,
    ``,
    `If you did not create this account, ignore this message.`,
  ].join("\n");
  const html = `
    <p>Confirm your <strong>THE GOLD MIND PROFESSIONAL</strong> account.</p>
    <p><a href="${verifyUrl}" style="display:inline-block;padding:10px 18px;background:#c9a227;color:#111;text-decoration:none;border-radius:4px;font-weight:600">Verify email address</a></p>
    <p style="font-size:13px;color:#666">Or open: <a href="${verifyUrl}">${verifyUrl}</a></p>
    <p style="font-size:13px;color:#666">You must confirm before you can sign in. This link expires in 24 hours.</p>
  `;

  const sent = await sendTransactionalEmail({ to: email, subject, html, text });
  if (!sent.ok) {
    console.warn(
      `[accounts] Verification email not delivered via Resend (${sent.error || "unknown"}) — token flow still active`
    );
  } else {
    console.info(`[accounts] Verification email accepted by Resend id=${sent.providerId || "n/a"} → ${email}`);
  }
  // Expose verify link when mail failed, in non-production, or when explicitly enabled.
  const expose =
    !sent.ok ||
    process.env.NODE_ENV !== "production" ||
    process.env.PORTAL_EXPOSE_VERIFY_LINK === "true";

  return {
    ok: true,
    email,
    emailSent: sent.ok,
    mailError: sent.ok ? undefined : sent.error,
    verifyUrl: expose ? verifyUrl : undefined,
  };
}

export async function verifyAccountEmail(emailRaw: string, token: string): Promise<{ ok: boolean; error?: string }> {
  const email = emailRaw.trim().toLowerCase();
  const account = await getAccountByEmail(email);
  if (!account) return { ok: false, error: "Account not found." };
  if (account.emailVerifiedAt) return { ok: true };
  if (!account.verifyTokenHash || !account.verifyTokenExpiresAt) {
    return { ok: false, error: "No pending verification for this account." };
  }
  if (new Date(account.verifyTokenExpiresAt).getTime() < Date.now()) {
    return { ok: false, error: "Verification link expired. Please register again." };
  }
  if (hashToken(token) !== account.verifyTokenHash) {
    return { ok: false, error: "Invalid verification link." };
  }

  account.emailVerifiedAt = new Date().toISOString();
  account.verifyTokenHash = null;
  account.verifyTokenExpiresAt = null;
  account.updatedAt = new Date().toISOString();
  await saveAccount(account);
  return { ok: true };
}

export async function authenticatePassword(
  emailRaw: string,
  password: string
): Promise<AccountRecord | null> {
  const email = emailRaw.trim().toLowerCase();
  const account = await getAccountByEmail(email);
  if (!account?.passwordHash) return null;
  if (!account.emailVerifiedAt) return null;
  if (!verifyPassword(password, account.passwordHash)) return null;
  return account;
}

/** Google / OAuth users are treated as verified. */
export async function upsertOAuthAccount(input: {
  email: string;
  name?: string | null;
}): Promise<AccountRecord> {
  const email = input.email.trim().toLowerCase();
  const existing = await getAccountByEmail(email);
  const now = new Date().toISOString();
  if (existing) {
    existing.emailVerifiedAt = existing.emailVerifiedAt || now;
    existing.name = input.name?.trim() || existing.name;
    existing.provider = existing.passwordHash ? "both" : "google";
    existing.updatedAt = now;
    return saveAccount(existing);
  }
  return saveAccount({
    id: newAccountId(),
    email,
    name: input.name?.trim() || email.split("@")[0],
    passwordHash: null,
    emailVerifiedAt: now,
    verifyTokenHash: null,
    verifyTokenExpiresAt: null,
    provider: "google",
    tradeAlertsEnabled: true,
    createdAt: now,
    updatedAt: now,
  });
}

/** Default ON when preference has never been set. */
export function isTradeAlertsEnabled(account: AccountRecord | null | undefined): boolean {
  if (!account) return true;
  return account.tradeAlertsEnabled !== false;
}

export async function setTradeAlertsEnabled(
  emailRaw: string,
  enabled: boolean
): Promise<AccountRecord | null> {
  const email = emailRaw.trim().toLowerCase();
  if (!email) return null;
  const existing = await getAccountByEmail(email);
  const now = new Date().toISOString();
  if (existing) {
    existing.tradeAlertsEnabled = enabled;
    existing.updatedAt = now;
    return saveAccount(existing);
  }
  return saveAccount({
    id: newAccountId(),
    email,
    name: email.split("@")[0],
    passwordHash: null,
    emailVerifiedAt: now,
    verifyTokenHash: null,
    verifyTokenExpiresAt: null,
    provider: "credentials",
    tradeAlertsEnabled: enabled,
    createdAt: now,
    updatedAt: now,
  });
}
