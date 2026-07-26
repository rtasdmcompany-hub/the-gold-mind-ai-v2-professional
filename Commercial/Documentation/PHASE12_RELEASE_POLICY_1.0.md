# PHASE12_RELEASE_POLICY_1.0.md

**Line:** 1.0.x LTS  
**Current portal:** `1.0.10-phase12.s1`

## Allowed

- Bug Fixes
- Security Updates
- Performance Optimizations
- Compatibility Updates
- Documentation Improvements

## Forbidden

- Feature additions
- Trading engine changes
- Risk / recovery / money management changes
- Magic number / calculation changes
- Any Core Trading Engine modification

## Cadence

- Security patches: as needed (critical ≤ 72h)
- Maintenance windows: Sun 02:00–04:00 UTC (optional)
- Documentation: continuous

## Core rule

SHA-256 must match certified value on every release
