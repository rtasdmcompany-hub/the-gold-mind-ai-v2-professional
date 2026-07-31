/**
 * Customer-facing product announcements — durable JSON store (+ Upstash when configured).
 * Production does not auto-seed demo announcements.
 */
import fs from "fs";
import path from "path";
import { randomBytes } from "crypto";
import { commercialDataRoot } from "@/server/cloud/data-root";
import {
  durableGet,
  durableSet,
  isDurableStoreConfigured,
} from "@/server/cloud/cache";
import { isProductionRuntime } from "@/server/security/dev-bypass";

export type Announcement = {
  id: string;
  title: string;
  body: string;
  date: string;
  pinned?: boolean;
  published: boolean;
  createdAt: string;
};

type AnnouncementStore = { version: 1; items: Announcement[] };

const EMPTY: AnnouncementStore = { version: 1, items: [] };
const DURABLE_KEY = "tgm:announcements:store:v1";
let cache: AnnouncementStore | null = null;
let writeChain: Promise<void> = Promise.resolve();
let loadPromise: Promise<void> | null = null;

function storePath(): string {
  const dir = commercialDataRoot("announcements");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, "announcements.json");
}

function seedItems(): Announcement[] {
  const now = new Date().toISOString();
  return [
    {
      id: "ann_100_stable",
      title: "THE GOLD MIND PROFESSIONAL 1.0.0 available",
      body: "Download the stable Windows installer ZIP from Portal → Downloads. Unzip, run Setup.exe, and enter your existing license key to complete installation. Core Trading Engine remains certified frozen.",
      date: "2026-07-28",
      pinned: true,
      published: true,
      createdAt: now,
    },
    {
      id: "ann_core_frozen",
      title: "Core Trading Engine remains frozen",
      body: "Commercial portal, licensing, and installer services are isolated from live trading behaviour. Updates never modify Strategy, Risk, Recovery, or Order Execution logic.",
      date: "2026-07-20",
      pinned: false,
      published: true,
      createdAt: now,
    },
  ];
}

function loadRawFromDisk(): AnnouncementStore {
  const p = storePath();
  if (!fs.existsSync(p)) return structuredClone(EMPTY);
  try {
    const data = JSON.parse(fs.readFileSync(p, "utf8")) as AnnouncementStore;
    if (!Array.isArray(data.items)) data.items = [];
    return data;
  } catch {
    return structuredClone(EMPTY);
  }
}

export async function ensureAnnouncementsLoaded(): Promise<void> {
  if (cache) return;
  if (!loadPromise) {
    loadPromise = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(DURABLE_KEY);
          if (remote) {
            cache = JSON.parse(remote) as AnnouncementStore;
            if (!Array.isArray(cache.items)) cache.items = [];
            return;
          }
        } catch {
          /* fall through */
        }
      }
      cache = loadRawFromDisk();
      // Dev-only seed when empty
      if (cache.items.length === 0 && !isProductionRuntime()) {
        cache.items = seedItems();
        persist(cache);
        return;
      }
      if (isDurableStoreConfigured() && cache.items.length > 0) {
        try {
          await durableSet(DURABLE_KEY, JSON.stringify(cache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      if (!cache) loadPromise = null;
    });
  }
  await loadPromise;
  if (!cache) cache = structuredClone(EMPTY);
}

function persist(data: AnnouncementStore): void {
  cache = data;
  const blob = JSON.stringify(data, null, 2);
  writeChain = writeChain.then(async () => {
    try {
      fs.writeFileSync(storePath(), blob, "utf8");
    } catch {
      /* serverless */
    }
    if (isDurableStoreConfigured()) {
      await durableSet(DURABLE_KEY, blob);
    }
  });
}

function read(): AnnouncementStore {
  if (cache) return cache;
  cache = loadRawFromDisk();
  return cache;
}

export function listPublishedAnnouncements(): Announcement[] {
  return read()
    .items.filter((a) => a.published)
    .sort((a, b) => {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.date.localeCompare(a.date);
    });
}

export function createAnnouncement(input: {
  title: string;
  body: string;
  pinned?: boolean;
}): Announcement {
  const item: Announcement = {
    id: `ann_${Date.now().toString(36)}_${randomBytes(2).toString("hex")}`,
    title: input.title.trim(),
    body: input.body.trim(),
    date: new Date().toISOString().slice(0, 10),
    pinned: !!input.pinned,
    published: true,
    createdAt: new Date().toISOString(),
  };
  const data = structuredClone(read());
  data.items.unshift(item);
  persist(data);
  return item;
}

export async function flushAnnouncements(): Promise<void> {
  await writeChain;
}
