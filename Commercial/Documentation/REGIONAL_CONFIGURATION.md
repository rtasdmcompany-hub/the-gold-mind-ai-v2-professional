# REGIONAL_CONFIGURATION.md

Configurable regional settings (independent of Core):

| Setting | Purpose |
|---------|---------|
| Language | UI locale code |
| Timezone | `Intl` / date formatting |
| Date format | short · medium · long |
| Currency display | ISO 4217 |
| Measurement | metric · imperial |
| Legal notice key | Localized legal string |
| Support contact key | Localized support contacts |

## Seeded regions

- **US** · lang=en · tz=America/New_York · USD · imperial
- **PK** · lang=ur · tz=Asia/Karachi · PKR · metric
- **AE** · lang=ar · tz=Asia/Dubai · AED · metric
- **FR** · lang=fr · tz=Europe/Paris · EUR · metric
- **DE** · lang=de · tz=Europe/Berlin · EUR · metric
- **ES** · lang=es · tz=Europe/Madrid · EUR · metric
- **TR** · lang=tr · tz=Europe/Istanbul · TRY · metric

Preview uses `applyRegional()` for sample date/number/currency/legal/support strings.
