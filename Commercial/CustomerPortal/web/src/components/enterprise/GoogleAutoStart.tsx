"use client";

import { useEffect, useRef } from "react";

/** Submits the parent Google sign-in form after mount (installer deep-link). */
export function GoogleAutoStart({ enabled, formId }: { enabled: boolean; formId: string }) {
  const started = useRef(false);

  useEffect(() => {
    if (!enabled || started.current) return;
    started.current = true;
    const form = document.getElementById(formId) as HTMLFormElement | null;
    form?.requestSubmit();
  }, [enabled, formId]);

  return (
    <p className="e-login-oauth-note" role="status">
      Redirecting to Google Sign-In…
    </p>
  );
}
