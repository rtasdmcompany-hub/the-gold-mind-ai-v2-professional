/**
 * Task 3 — Store asset inventory.
 */
import fs from "fs";
import path from "path";
import { commercialRoot, saveMarketRun } from "./store";

export interface AssetItem {
  id: string;
  label: string;
  path: string;
  status: "ready" | "placeholder" | "missing";
  detail: string;
}

function existsRel(rel: string): boolean {
  return fs.existsSync(path.join(commercialRoot(), rel));
}

export async function runStoreAssetInventory(): Promise<{
  items: AssetItem[];
  score: number;
  at: string;
}> {
  const items: AssetItem[] = [
    {
      id: "icon",
      label: "Application Icon",
      path: "Assets/Market/Icons/tgm-market-icon.png",
      status: existsRel("Assets/Market/Icons/tgm-market-icon.png") ? "ready" : "missing",
      detail: "1:1 Market icon",
    },
    {
      id: "logo",
      label: "Product Logo",
      path: "Assets/Market/Logos/tgm-market-logo.png",
      status: existsRel("Assets/Market/Logos/tgm-market-logo.png") ? "ready" : "missing",
      detail: "16:9 logo lockup",
    },
    {
      id: "banner",
      label: "Feature Banner",
      path: "Assets/Market/Banners/tgm-market-feature-banner.png",
      status: existsRel("Assets/Market/Banners/tgm-market-feature-banner.png") ? "ready" : "missing",
      detail: "Store feature banner — no profit claims",
    },
    {
      id: "cover",
      label: "Store Cover Images",
      path: "Assets/Market/Covers/tgm-market-cover.png",
      status: existsRel("Assets/Market/Covers/tgm-market-cover.png") ? "ready" : "missing",
      detail: "Primary cover",
    },
    {
      id: "mt5_shots",
      label: "MT5 Screenshots",
      path: "Assets/Market/Screenshots/",
      status: existsRel("Assets/Market/Screenshots/CAPTURE_PLAN.md") ? "placeholder" : "missing",
      detail: "Capture plan ready — live MT5 stills required before upload",
    },
    {
      id: "settings",
      label: "Settings Screenshots",
      path: "Assets/Market/Screenshots/03-inputs.png",
      status: "placeholder",
      detail: "Await Owner/QA capture per CAPTURE_PLAN.md",
    },
    {
      id: "tester",
      label: "Strategy Tester Screenshots",
      path: "Assets/Market/Screenshots/04-tester-settings.png",
      status: "placeholder",
      detail: "Must label historical/demo — no live profit implication",
    },
    {
      id: "graphs",
      label: "Performance Graphs (accurately labeled)",
      path: "Assets/Market/Screenshots/05-tester-graph.png",
      status: "placeholder",
      detail: "Equity graphs require DEMO/HISTORICAL watermark",
    },
    {
      id: "install",
      label: "Installation Images",
      path: "Assets/Market/Screenshots/08-install.png",
      status: "placeholder",
      detail: "Market one-click install confirmation",
    },
    {
      id: "help",
      label: "Help Images",
      path: "Assets/Market/Help/",
      status: existsRel("Assets/Market/Help/README.md") ? "placeholder" : "missing",
      detail: "Annotated help stills after capture",
    },
  ];

  const score = Math.round(
    (items.reduce((a, i) => a + (i.status === "ready" ? 1 : i.status === "placeholder" ? 0.4 : 0), 0) /
      items.length) *
      100
  );
  const payload = { items, score, at: new Date().toISOString() };
  saveMarketRun("assets", "Sprint 7 store assets", payload);
  return payload;
}
