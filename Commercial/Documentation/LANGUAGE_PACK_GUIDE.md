# LANGUAGE_PACK_GUIDE.md

## Built-in packs (v1.0.0)

- **ar** · العربية · v1.0.0 · rtl
- **de** · Deutsch · v1.0.0 · ltr
- **en** · English · v1.0.0 · ltr
- **es** · Español · v1.0.0 · ltr
- **fr** · Français · v1.0.0 · ltr
- **tr** · Türkçe · v1.0.0 · ltr
- **ur** · اردو · v1.0.0 · rtl

## Create a new language

1. Copy `locales/en/` to `locales/{code}/`.
2. Edit `manifest.json` (`code`, `name`, `nativeName`, `direction`, `version`, `fallback`, `currencyDefault`).
3. Translate `messages.json` keys (UTF-8).
4. Restart / run `npm run phase11:sprint5` — pack is discovered automatically.

## Versioning

Each pack is independently versioned via `manifest.version`. Bump on content changes.

## Pluralization

Provide `{base}_one` and `{base}_other` (optional `_zero`). Use `tp(base, count, locale)`.
