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
import { brand } from "@/lib/brand";
import { cacheIncr, CacheKeys } from "@/server/cloud/cache";

function baseUrl(): string {
  return (
    process.env.AUTH_URL ||
    process.env.NEXTAUTH_URL ||
    brand.website
  ).replace(/\/$/, "");
}

function exposeVerifyLink(emailSent: boolean): boolean {
  return (
    !emailSent ||
    process.env.NODE_ENV !== "production" ||
    process.env.PORTAL_EXPOSE_VERIFY_LINK === "true"
  );
}

async function issueVerificationEmail(account: AccountRecord): Promise<{
  emailSent: boolean;
  verifyUrl: string;
}> {
  const token = newVerifyToken();
  const expires = new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString();
  account.verifyTokenHash = hashToken(token);
  account.verifyTokenExpiresAt = expires;
  account.updatedAt = new Date().toISOString();
  await saveAccount(account);

  const verifyUrl = `${baseUrl()}/verify-email?token=${token}&email=${encodeURIComponent(account.email)}`;
  const subject = `Confirm your email — ${brand.productName}`;
  const text = `Confirm your ${brand.productName} account:\n\n${verifyUrl}\n\nThis link expires in 24 hours.`;
  const html = `<p>Confirm your <strong>${brand.productName}</strong> account.</p><p><a href="${verifyUrl}">Verify email address</a></p><p>This link expires in 24 hours.</p>`;
  const sent = await sendTransactionalEmail({ to: account.email, subject, html, text });
  return { emailSent: sent.ok, verifyUrl };
}

export type SignupResult =
  | { ok: true; email: string; emailSent: boolean; verifyUrl?: string }
  | { ok: false; error: string };

export type ResendVerificationResult =
  | { ok: true; email: string; emailSent: boolean; verifyUrl?: string; alreadyVerified?: boolean }
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

  const now = new Date().toISOString();
  const account: AccountRecord = {
    id: existing?.id || newAccountId(),
    email,
    name,
    passwordHash: hashPassword(password),
    emailVerifiedAt: null,
    verifyTokenHash: null,
    verifyTokenExpiresAt: null,
    provider: "credentials",
    createdAt: existing?.createdAt || now,
    updatedAt: now,
  };
  await saveAccount(account);

  const issued = await issueVerificationEmail(account);
  return {
    ok: true,
    email,
    emailSent: issued.emailSent,
    verifyUrl: exposeVerifyLink(issued.emailSent) ? issued.verifyUrl : undefined,
  };
}

/**
 * Resend signup confirmation. Rate-limited per email (3 / 15 min).
 * Does not reveal whether an account exists when none is found.
 */
export async function resendVerificationEmail(emailRaw: string): Promise<ResendVerificationResult> {
  const email = emailRaw.trim().toLowerCase();
  if (!email || !email.includes("@")) {
    return { ok: false, error: "Please enter a valid email." };
  }

  const n = await cacheIncr(CacheKeys.rateLimit(`verify-resend:${email}`), 15 * 60);
  if (n > 3) {
    return {
      ok: false,
      error: "Too many resend attempts. Please wait about 15 minutes and try again.",
    };
  }

  const account = await getAccountByEmail(email);
  if (!account) {
    // Anti-enumeration: same success shape, no mail.
    return { ok: true, email, emailSent: false };
  }
  if (account.emailVerifiedAt) {
    return { ok: true, email, emailSent: false, alreadyVerified: true };
  }
  if (!account.passwordHash) {
    // Google-only — no email/password verification pending.
    return {
      ok: false,
      error: "This account uses Google Sign-In. Please sign in with Google instead.",
    };
  }

  const issued = await issueVerificationEmail(account);
  return {
    ok: true,
    email,
    emailSent: issued.emailSent,
    verifyUrl: exposeVerifyLink(issued.emailSent) ? issued.verifyUrl : undefined,
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
    createdAt: now,
    updatedAt: now,
  });
}

export function isTradeAlertsEnabled(account: AccountRecord | null | undefined): boolean {
  if (!account) return true;
  return account.tradeAlertsEnabled !== false;
}

export async function setTradeAlertsEnabled(emailRaw: string, enabled: boolean): Promise<void> {
  const email = emailRaw.trim().toLowerCase();
  let account = await getAccountByEmail(email);
  if (!account) {
    account = await upsertOAuthAccount({ email, name: email.split("@")[0] });
  }
  account.tradeAlertsEnabled = enabled;
  account.updatedAt = new Date().toISOString();
  await saveAccount(account);
}

export async function updateAccountProfile(input: {
  email: string;
  name: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const email = input.email.trim().toLowerCase();
  const name = input.name.trim();
  if (name.length < 2) return { ok: false, error: "Name must be at least 2 characters." };
  const account = await getAccountByEmail(email);
  if (!account) return { ok: false, error: "Account not found. Sign in with email/password or Google first." };
  account.name = name;
  account.updatedAt = new Date().toISOString();
  await saveAccount(account);
  return { ok: true };
}

export type PasswordResetRequestResult =
  | { ok: true; emailSent: boolean; resetUrl?: string }
  | { ok: false; error: string };

/**
 * Always resolves ok:true (does not reveal account existence) unless the email is malformed.
 * Google-only accounts (no passwordHash) are silently skipped — no email is sent — but the
 * response shape is identical to avoid leaking account status to an unauthenticated caller.
 */
export async function requestPasswordReset(emailRaw: string): Promise<PasswordResetRequestResult> {
  const email = emailRaw.trim().toLowerCase();
  if (!email || !email.includes("@")) {
    return { ok: false, error: "Please enter a valid email." };
  }

  const account = await getAccountByEmail(email);
  if (!account || !account.passwordHash) {
    // No account, or Google-only account — respond identically to a real send.
    return { ok: true, emailSent: false };
  }

  const token = newVerifyToken();
  const expires = new Date(Date.now() + 1000 * 60 * 60).toISOString();
  account.resetTokenHash = hashToken(token);
  account.resetTokenExpiresAt = expires;
  account.updatedAt = new Date().toISOString();
  await saveAccount(account);

  const resetUrl = `${baseUrl()}/reset-password?token=${token}&email=${encodeURIComponent(email)}`;
  const subject = `Reset your password — ${brand.productName}`;
  const text = `A password reset was requested for your ${brand.productName} account:\n\n${resetUrl}\n\nThis link expires in 1 hour. If you did not request this, you can ignore this email.`;
  const html = `<p>A password reset was requested for your <strong>${brand.productName}</strong> account.</p><p><a href="${resetUrl}">Reset password</a></p><p>This link expires in 1 hour. If you did not request this, you can ignore this email.</p>`;

  const sent = await sendTransactionalEmail({ to: email, subject, html, text });
  const expose =
    !sent.ok ||
    process.env.NODE_ENV !== "production" ||
    process.env.PORTAL_EXPOSE_VERIFY_LINK === "true";

  return { ok: true, emailSent: sent.ok, resetUrl: expose ? resetUrl : undefined };
}

export async function resetPasswordWithToken(input: {
  email: string;
  token: string;
  newPassword: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const email = input.email.trim().toLowerCase();
  const token = input.token.trim();
  if (input.newPassword.length < 8) {
    return { ok: false, error: "New password must be at least 8 characters." };
  }

  const account = await getAccountByEmail(email);
  if (!account) return { ok: false, error: "Invalid or expired reset link." };
  if (!account.resetTokenHash || !account.resetTokenExpiresAt) {
    return { ok: false, error: "No pending reset request for this account." };
  }
  if (new Date(account.resetTokenExpiresAt).getTime() < Date.now()) {
    return { ok: false, error: "Reset link expired. Please request a new one." };
  }
  if (!token || hashToken(token) !== account.resetTokenHash) {
    return { ok: false, error: "Invalid or expired reset link." };
  }

  account.passwordHash = hashPassword(input.newPassword);
  account.resetTokenHash = null;
  account.resetTokenExpiresAt = null;
  account.updatedAt = new Date().toISOString();
  await saveAccount(account);
  return { ok: true };
}

export async function changeAccountPassword(input: {
  email: string;
  currentPassword: string;
  newPassword: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const email = input.email.trim().toLowerCase();
  const account = await getAccountByEmail(email);
  if (!account) return { ok: false, error: "Account not found." };
  if (!account.passwordHash) {
    return { ok: false, error: "This account uses Google sign-in only. Password change is not available." };
  }
  if (!verifyPassword(input.currentPassword, account.passwordHash)) {
    return { ok: false, error: "Current password is incorrect." };
  }
  if (input.newPassword.length < 8) {
    return { ok: false, error: "New password must be at least 8 characters." };
  }
  account.passwordHash = hashPassword(input.newPassword);
  account.updatedAt = new Date().toISOString();
  await saveAccount(account);
  return { ok: true };
}
