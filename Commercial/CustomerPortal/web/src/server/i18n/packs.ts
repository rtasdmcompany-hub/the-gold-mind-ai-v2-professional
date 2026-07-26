/**
 * Language pack registry — file packs under locales/ are installable without code changes.
 */
import fs from "fs";
import path from "path";
import type { LocaleCode, LocaleManifest, TranslationCatalog } from "./types";
import { I18N_NAMESPACES } from "./types";
import { EN_CATALOG } from "./catalogs/en";
import { UR_CATALOG } from "./catalogs/ur";
import { AR_CATALOG } from "./catalogs/ar";
import { FR_CATALOG } from "./catalogs/fr";
import { DE_CATALOG } from "./catalogs/de";
import { ES_CATALOG } from "./catalogs/es";
import { TR_CATALOG } from "./catalogs/tr";

const BUILTIN: Record<string, { manifest: LocaleManifest; catalog: TranslationCatalog }> = {
  en: {
    manifest: {
      code: "en",
      name: "English",
      nativeName: "English",
      version: "1.0.0",
      direction: "ltr",
      fallback: "en",
      currencyDefault: "USD",
      dateStyle: "medium",
      namespaces: [...I18N_NAMESPACES],
    },
    catalog: EN_CATALOG,
  },
  ur: {
    manifest: {
      code: "ur",
      name: "Urdu",
      nativeName: "اردو",
      version: "1.0.0",
      direction: "rtl",
      fallback: "en",
      currencyDefault: "PKR",
      dateStyle: "medium",
      namespaces: [...I18N_NAMESPACES],
    },
    catalog: UR_CATALOG,
  },
  ar: {
    manifest: {
      code: "ar",
      name: "Arabic",
      nativeName: "العربية",
      version: "1.0.0",
      direction: "rtl",
      fallback: "en",
      currencyDefault: "AED",
      dateStyle: "medium",
      namespaces: [...I18N_NAMESPACES],
    },
    catalog: AR_CATALOG,
  },
  fr: {
    manifest: {
      code: "fr",
      name: "French",
      nativeName: "Français",
      version: "1.0.0",
      direction: "ltr",
      fallback: "en",
      currencyDefault: "EUR",
      dateStyle: "medium",
      namespaces: [...I18N_NAMESPACES],
    },
    catalog: FR_CATALOG,
  },
  de: {
    manifest: {
      code: "de",
      name: "German",
      nativeName: "Deutsch",
      version: "1.0.0",
      direction: "ltr",
      fallback: "en",
      currencyDefault: "EUR",
      dateStyle: "medium",
      namespaces: [...I18N_NAMESPACES],
    },
    catalog: DE_CATALOG,
  },
  es: {
    manifest: {
      code: "es",
      name: "Spanish",
      nativeName: "Español",
      version: "1.0.0",
      direction: "ltr",
      fallback: "en",
      currencyDefault: "EUR",
      dateStyle: "medium",
      namespaces: [...I18N_NAMESPACES],
    },
    catalog: ES_CATALOG,
  },
  tr: {
    manifest: {
      code: "tr",
      name: "Turkish",
      nativeName: "Türkçe",
      version: "1.0.0",
      direction: "ltr",
      fallback: "en",
      currencyDefault: "TRY",
      dateStyle: "medium",
      namespaces: [...I18N_NAMESPACES],
    },
    catalog: TR_CATALOG,
  },
};

export function localesRoot(): string {
  return path.join(process.cwd(), "locales");
}

/** Sync builtin packs to locales/{code}/ for drop-in future packs. */
export function syncBuiltinPacksToDisk(): void {
  const root = localesRoot();
  if (!fs.existsSync(root)) fs.mkdirSync(root, { recursive: true });
  for (const [code, pack] of Object.entries(BUILTIN)) {
    const dir = path.join(root, code);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, "manifest.json"), JSON.stringify(pack.manifest, null, 2), "utf8");
    fs.writeFileSync(path.join(dir, "messages.json"), JSON.stringify(pack.catalog, null, 2), "utf8");
    fs.writeFileSync(
      path.join(dir, "README.md"),
      `# Locale pack: ${pack.manifest.name} (${code})\n\nVersion: ${pack.manifest.version}\nDirection: ${pack.manifest.direction}\n\nDrop additional packs as \`locales/{code}/manifest.json\` + \`messages.json\` — no application code change required.\n`,
      "utf8"
    );
  }
}

function loadDiskPack(code: string): { manifest: LocaleManifest; catalog: TranslationCatalog } | null {
  const dir = path.join(localesRoot(), code);
  const manPath = path.join(dir, "manifest.json");
  const msgPath = path.join(dir, "messages.json");
  if (!fs.existsSync(manPath) || !fs.existsSync(msgPath)) return null;
  try {
    const manifest = JSON.parse(fs.readFileSync(manPath, "utf8")) as LocaleManifest;
    const catalog = JSON.parse(fs.readFileSync(msgPath, "utf8")) as TranslationCatalog;
    return { manifest, catalog };
  } catch {
    return null;
  }
}

export function listInstalledLocales(): LocaleManifest[] {
  syncBuiltinPacksToDisk();
  const root = localesRoot();
  const codes = new Set<string>(Object.keys(BUILTIN));
  if (fs.existsSync(root)) {
    for (const ent of fs.readdirSync(root, { withFileTypes: true })) {
      if (ent.isDirectory()) codes.add(ent.name);
    }
  }
  const out: LocaleManifest[] = [];
  for (const code of [...codes].sort()) {
    const disk = loadDiskPack(code);
    if (disk) out.push(disk.manifest);
    else if (BUILTIN[code]) out.push(BUILTIN[code].manifest);
  }
  return out;
}

export function getLocalePack(code: LocaleCode): { manifest: LocaleManifest; catalog: TranslationCatalog } {
  const disk = loadDiskPack(String(code));
  if (disk) return disk;
  if (BUILTIN[code]) return BUILTIN[code];
  return BUILTIN.en;
}

export function masterKeys(): string[] {
  return Object.keys(EN_CATALOG).sort();
}
