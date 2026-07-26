# PRODUCT_PACKAGE_GUIDE.md

**Phase:** 10 · Sprint 7  

---

## Market package location

`Commercial/MarketEdition/`

| Folder | Purpose |
|--------|---------|
| `Package/` | MANIFEST.json · CORE_TAG.txt · FILE_LIST.txt · STORE_METADATA.json |
| `Listing/` | Store documentation set |
| `Docs/` | Extra Market ops notes |
| `Screenshots/` | Optional local mirror of captures |
| `Compliance/` | Checklists |

## Shared Core rule

Compile / publish Market builds from Core tag:

`Experts/TheGoldMindAI_Professional.mq5`  
SHA-256 `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce`

**Never** include Customer Portal, PaymentPort, or Website installers in the Market upload.

## Professional Website contrast

Website edition continues under `Installer/Professional` + Customer Portal. Separate SKU, separate licensing, same Core.
