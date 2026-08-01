# THE GOLD MIND PROFESSIONAL 1.0.0

## Artifacts (canonical — no duplicates)

| Artifact | Bytes | SHA-256 |
|----------|------:|---------|
| `installer/Setup.exe` | 457728 | `db387c8b97c6c833f7a7c06f2fa128f888982626016262e63adabd60300071fb` |
| `TGM_PROFESSIONAL_1.0.0_stable.zip` | 862711 | `b33753bb0289b6838c3d5ccaa2b0df152b3b7c2cc0c2b84565586a4a132f21f0` |
| `TheGoldMindAI_Professional.ex5` | 251018 | `890e22254ef44f86e82bc3700cd2b0dd0eaddf57c3ce91ff0f801b999c347535` |
| mq5 (packaging gate) | — | `1965551f7b88f403cf8a0af5475211a562b9c05500a0bb530e0136d38d403f1e` |

## Install (strict license)

1. Create Customer Portal account and generate a license key (trial or paid).  
2. Run **`Setup.exe`**.  
3. Paste the **same portal email + license key**.  
4. Setup finishes only when the portal confirms **Active** (trial and lifetime — same rule).  
5. Attach the EA in MetaTrader 5.

## Notes

- Trading / Risk / Recovery / Money / Entry / Exit / Order logic: unchanged.  
- AI Dynamic Engine panel move/min/max is in MQ5 source; recompile EX5 in MetaEditor to ship that UI binary.  
- Code signing: pending Owner Authenticode.
