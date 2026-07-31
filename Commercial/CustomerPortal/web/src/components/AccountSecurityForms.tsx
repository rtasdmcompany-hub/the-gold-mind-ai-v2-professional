"use client";

import { useState, useTransition } from "react";
import { actionChangePassword, actionUpdateProfile } from "@/server/accounts/actions";

export function AccountProfileForm({ defaultName }: { defaultName: string }) {
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);

  return (
    <form
      className="stack"
      action={(fd) =>
        start(async () => {
          const r = await actionUpdateProfile(fd);
          setMsg(r.ok ? "Profile saved." : r.error || "Save failed");
        })
      }
    >
      <div className="field">
        <label htmlFor="name">Display name</label>
        <input id="name" name="name" defaultValue={defaultName} required minLength={2} maxLength={80} />
      </div>
      <button type="submit" className="btn btn-primary" disabled={pending}>
        Save name
      </button>
      {msg && <p className="meta">{msg}</p>}
    </form>
  );
}

export function ChangePasswordForm({ hasPassword }: { hasPassword: boolean }) {
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);

  if (!hasPassword) {
    return (
      <p className="meta">
        This account signs in with Google only. Password change is unavailable unless you also register with
        email/password.
      </p>
    );
  }

  return (
    <form
      className="stack"
      action={(fd) =>
        start(async () => {
          const r = await actionChangePassword(fd);
          setMsg(r.ok ? "Password updated." : r.error || "Update failed");
        })
      }
    >
      <div className="field">
        <label htmlFor="currentPassword">Current password</label>
        <input id="currentPassword" name="currentPassword" type="password" required autoComplete="current-password" />
      </div>
      <div className="field">
        <label htmlFor="newPassword">New password</label>
        <input id="newPassword" name="newPassword" type="password" required minLength={8} autoComplete="new-password" />
      </div>
      <button type="submit" className="btn btn-primary" disabled={pending}>
        Change password
      </button>
      {msg && <p className="meta">{msg}</p>}
    </form>
  );
}
