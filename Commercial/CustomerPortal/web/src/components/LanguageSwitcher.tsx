"use client";

import { useRouter } from "next/navigation";
import { LOCALE_COOKIE, SUPPORTED_LOCALES, type LocaleCode } from "@/lib/i18n";

export function LanguageSwitcher({ current = "en" }: { current?: LocaleCode }) {
  const router = useRouter();

  function onChange(code: string) {
    document.cookie = `${LOCALE_COOKIE}=${code};path=/;max-age=31536000;samesite=lax`;
    document.documentElement.lang = code;
    document.documentElement.dir =
      SUPPORTED_LOCALES.find((l) => l.code === code)?.dir || "ltr";
    router.refresh();
  }

  return (
    <label style={{ display: "inline-flex", gap: 8, alignItems: "center", fontSize: 13 }}>
      <span>Language</span>
      <select
        value={current}
        onChange={(e) => onChange(e.target.value)}
        aria-label="Language"
        style={{ padding: "4px 8px" }}
      >
        {SUPPORTED_LOCALES.map((l) => (
          <option key={l.code} value={l.code}>
            {l.label}
          </option>
        ))}
      </select>
    </label>
  );
}
