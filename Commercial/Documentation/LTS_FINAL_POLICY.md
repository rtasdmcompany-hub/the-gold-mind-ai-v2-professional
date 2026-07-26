# LTS_FINAL_POLICY.md

## Versioning

- Commercial: SemVer MAJOR.MINOR.PATCH for portal/API; language packs independent
- Core: Frozen certified tag — no commercial release may alter Core SHA

## Security patches

- Critical: ≤ 7 calendar days
- High: ≤ 30 calendar days
- Medium: Next monthly train
- Low: Backlog / quarterly

## Release cadence

- Feature/fix monthly
- LTS train every quarter
- Hotfixes: As required under security policy

## Maintenance

Sunday 02:00–04:00 UTC · notice ≥ 72 hours for planned; best-effort for emergency

## End-of-Life

Support Current + previous minor (N and N-1) · notice 12 months

## Support matrix

- Customer Portal
- Email / tickets
- AI Assistant (commercial only)
- Mobile Companion
- Partner Portal
- Public API v1

## Compatibility

- API: v1 stable; breaking changes require v2 with deprecation window
- MT5: Certified Core tag only; no engine changes via commercial releases
- Browsers: Latest 2 Chrome/Edge/Firefox/Safari
