"use client";

import { useEffect, useRef } from "react";
import { signOut } from "next-auth/react";

/** Admin idle timeout — logs out after inactivity. */
export function AdminIdleGuard({ timeoutMinutes }: { timeoutMinutes: number }) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const ms = Math.max(1, timeoutMinutes) * 60 * 1000;
    const reset = () => {
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(() => {
        void signOut({ callbackUrl: "/login?reason=admin_idle" });
      }, ms);
    };
    const events = ["mousemove", "keydown", "click", "scroll", "touchstart"] as const;
    events.forEach((e) => window.addEventListener(e, reset));
    reset();
    return () => {
      if (timer.current) clearTimeout(timer.current);
      events.forEach((e) => window.removeEventListener(e, reset));
    };
  }, [timeoutMinutes]);

  return null;
}
