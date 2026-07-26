/**
 * Task 4 — Store documentation inventory.
 */
import fs from "fs";
import path from "path";
import { commercialRoot, saveMarketRun } from "./store";

const DOCS: Array<{ id: string; file: string; label: string }> = [
  { id: "product_description", file: "PRODUCT_DESCRIPTION.md", label: "PRODUCT_DESCRIPTION.md" },
  { id: "feature_list", file: "FEATURE_LIST.md", label: "FEATURE_LIST.md" },
  { id: "installation", file: "INSTALLATION_GUIDE.md", label: "INSTALLATION_GUIDE.md" },
  { id: "user_manual", file: "USER_MANUAL.md", label: "USER_MANUAL.md" },
  { id: "quick_start", file: "QUICK_START_GUIDE.md", label: "QUICK_START_GUIDE.md" },
  { id: "faq", file: "FAQ.md", label: "FAQ.md" },
  { id: "changelog", file: "CHANGELOG.md", label: "CHANGELOG.md" },
  { id: "known_limitations", file: "KNOWN_LIMITATIONS.md", label: "KNOWN_LIMITATIONS.md" },
  { id: "disclaimer", file: "DISCLAIMER.md", label: "DISCLAIMER.md" },
];

export interface DocItem {
  id: string;
  label: string;
  path: string;
  status: "ready" | "missing";
  bytes: number;
}

export async function runDocumentationInventory(): Promise<{
  items: DocItem[];
  score: number;
  at: string;
}> {
  const listing = path.join(commercialRoot(), "MarketEdition", "Listing");
  const items: DocItem[] = DOCS.map((d) => {
    const p = path.join(listing, d.file);
    const ready = fs.existsSync(p);
    return {
      id: d.id,
      label: d.label,
      path: `MarketEdition/Listing/${d.file}`,
      status: ready ? "ready" : "missing",
      bytes: ready ? fs.statSync(p).size : 0,
    };
  });
  const score = Math.round((items.filter((i) => i.status === "ready").length / items.length) * 100);
  const payload = { items, score, at: new Date().toISOString() };
  saveMarketRun("documentation", "Sprint 7 store documentation", payload);
  return payload;
}
