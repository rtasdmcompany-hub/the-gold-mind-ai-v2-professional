"use server";

import { AuthError } from "next-auth";
import { redirect } from "next/navigation";
import { signIn } from "@/auth";

function isNextRedirectError(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "digest" in error &&
    typeof (error as { digest?: unknown }).digest === "string" &&
    String((error as { digest: string }).digest).startsWith("NEXT_REDIRECT")
  );
}

function sanitizeCallbackUrl(raw: string): string {
  const value = (raw || "/portal").trim() || "/portal";
  // Only allow same-origin relative paths (block open redirects).
  if (!value.startsWith("/") || value.startsWith("//")) return "/portal";
  return value;
}

/**
 * Auth.js v5 throws AuthError (e.g. CredentialsSignin) on failed sign-in.
 * Uncaught, Next.js renders the black "Application error" page.
 * Successful sign-in throws NEXT_REDIRECT — that must be rethrown.
 */
export async function safeCredentialsSignIn(input: {
  email: string;
  password: string;
  callbackUrl?: string;
}): Promise<void> {
  const callbackUrl = sanitizeCallbackUrl(input.callbackUrl || "/portal");
  try {
    await signIn("credentials", {
      email: input.email,
      password: input.password,
      redirectTo: callbackUrl,
    });
  } catch (error) {
    if (isNextRedirectError(error)) throw error;
    if (error instanceof AuthError) {
      const type = error.type || "CredentialsSignin";
      redirect(
        `/login?error=${encodeURIComponent(type)}&callbackUrl=${encodeURIComponent(callbackUrl)}`
      );
    }
    console.error("[auth] credentials sign-in unexpected error", error);
    redirect(
      `/login?error=Configuration&callbackUrl=${encodeURIComponent(callbackUrl)}`
    );
  }
}

export async function safeGoogleSignIn(input: { callbackUrl?: string }): Promise<void> {
  const callbackUrl = sanitizeCallbackUrl(input.callbackUrl || "/portal");
  try {
    await signIn("google", { redirectTo: callbackUrl });
  } catch (error) {
    if (isNextRedirectError(error)) throw error;
    if (error instanceof AuthError) {
      const type = error.type || "OAuthSignInError";
      redirect(
        `/login?error=${encodeURIComponent(type)}&callbackUrl=${encodeURIComponent(callbackUrl)}`
      );
    }
    console.error("[auth] google sign-in unexpected error", error);
    redirect(
      `/login?error=Configuration&callbackUrl=${encodeURIComponent(callbackUrl)}`
    );
  }
}
