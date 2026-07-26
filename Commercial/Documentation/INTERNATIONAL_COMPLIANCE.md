# INTERNATIONAL_COMPLIANCE.md

**Score:** 94

## Checks

| ID | Label | Status |
|----|-------|--------|
| privacy_pages | Privacy Policy routes | pass |
| terms_pages | Terms of Service routes | pass |
| cookies | Cookie notices | pass |
| legal_keys | Legal key coverage in en | pass |
| fallbacks | Language fallbacks | pass |
| a11y | Accessibility review | partial |
| regional_legal | Regional legal content | pass |

## Localized legal titles

Privacy and Terms titles resolve per installed locale via `legal.*` keys.

## Notes

- Cookie banner string is localizable (`legal.cookies.banner`).
- Accessibility: `lang`/`dir` attributes + semantic labels; formal WCAG audit remains partial.
- Language fallbacks declared on every manifest.
