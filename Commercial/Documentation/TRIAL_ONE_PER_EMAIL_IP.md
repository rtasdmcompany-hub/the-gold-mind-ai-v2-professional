# Free trial — one per email + IP

## Rules
1. **One free trial per email identity** (Gmail dots / `+tag` / `googlemail.com` collapse to the same identity).
2. Regenerating **always returns the same key**.
3. **`createdAt` / `expiresAt` never reset** — if 4 days already passed on a 14-day trial, ~10 days remain.
4. **IP guard:** an IP that already claimed a trial cannot mint another trial for a different email.

## Implementation
- Deterministic trial key: `deriveTrialKey(email)` (HMAC) for new trials.
- Recoverable plaintext stored in `license.keyEnvelope` (AES envelope).
- Claims tracked in `store.trialClaims[]` + `issuedIpHash` on the license.
- Portal button: **Get trial key**.

## Legacy random trials
If a trial was minted before this change (random key), the portal re-shows it after the customer activates once (Setup or portal) so `keyEnvelope` can be bound. Dates stay original; a second trial is never created.
