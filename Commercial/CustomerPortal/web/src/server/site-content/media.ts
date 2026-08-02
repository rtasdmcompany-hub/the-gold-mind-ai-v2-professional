/**
 * Site media upload helpers.
 * Priority: Vercel Blob (BLOB_READ_WRITE_TOKEN) → local public/uploads → small durable store.
 */
import fs from "fs";
import path from "path";
import { randomBytes } from "crypto";
import { isServerlessRuntime } from "@/server/cloud/data-root";
import { saveStoredMedia } from "./store";

const MAX_DURABLE_BYTES = 1_400_000; // stay under typical Upstash value limits
const MAX_UPLOAD_BYTES = 80 * 1024 * 1024; // 80MB hard cap for Blob/local

const ALLOWED: Record<string, string[]> = {
  "video/mp4": [".mp4"],
  "video/webm": [".webm"],
  "image/jpeg": [".jpg", ".jpeg"],
  "image/png": [".png"],
  "image/webp": [".webp"],
  "image/gif": [".gif"],
};

export type UploadResult =
  | { ok: true; url: string; storage: "blob" | "local" | "durable"; id: string; size: number }
  | { ok: false; error: string };

function extFor(contentType: string, filename: string): string {
  const fromName = path.extname(filename || "").toLowerCase();
  if (fromName && Object.values(ALLOWED).some((arr) => arr.includes(fromName))) return fromName;
  const mapped = ALLOWED[contentType]?.[0];
  return mapped || ".bin";
}

function safeName(filename: string): string {
  return (filename || "upload")
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/-+/g, "-")
    .slice(0, 80);
}

async function putVercelBlob(
  pathname: string,
  body: Buffer,
  contentType: string
): Promise<string | null> {
  const token = (process.env.BLOB_READ_WRITE_TOKEN || "").trim();
  if (!token) return null;

  const res = await fetch(`https://blob.vercel-storage.com/${pathname}`, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${token}`,
      Access: "public",
      "x-api-version": "7",
      "Content-Type": contentType,
    },
    body: new Uint8Array(body),
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Vercel Blob upload failed (${res.status}): ${text.slice(0, 200)}`);
  }
  const json = (await res.json()) as { url?: string };
  if (!json.url) throw new Error("Vercel Blob response missing url");
  return json.url;
}

function writeLocalPublic(relPath: string, body: Buffer): string | null {
  if (isServerlessRuntime()) return null;
  try {
    const abs = path.join(process.cwd(), "public", relPath);
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.writeFileSync(abs, body);
    return `/${relPath.replace(/\\/g, "/")}`;
  } catch {
    return null;
  }
}

export async function uploadSiteMedia(input: {
  filename: string;
  contentType: string;
  bytes: Buffer;
}): Promise<UploadResult> {
  const contentType = (input.contentType || "").split(";")[0].trim().toLowerCase();
  if (!ALLOWED[contentType]) {
    return {
      ok: false,
      error: `Unsupported type "${contentType}". Allowed: mp4, webm, jpg, png, webp, gif.`,
    };
  }
  if (!input.bytes?.length) return { ok: false, error: "Empty file." };
  if (input.bytes.length > MAX_UPLOAD_BYTES) {
    return { ok: false, error: `File too large (max ${Math.floor(MAX_UPLOAD_BYTES / (1024 * 1024))}MB).` };
  }

  const id = `scm_${Date.now().toString(36)}_${randomBytes(4).toString("hex")}`;
  const ext = extFor(contentType, input.filename);
  const pathname = `site-content/${id}-${safeName(input.filename).replace(/\.[^.]+$/, "")}${ext}`;

  // 1) Vercel Blob (recommended on production)
  try {
    const blobUrl = await putVercelBlob(pathname, input.bytes, contentType);
    if (blobUrl) {
      return { ok: true, url: blobUrl, storage: "blob", id, size: input.bytes.length };
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Blob upload failed";
    // If token is set but upload fails, surface the error (don't silently fall back for large videos).
    if ((process.env.BLOB_READ_WRITE_TOKEN || "").trim() && input.bytes.length > MAX_DURABLE_BYTES) {
      return { ok: false, error: msg };
    }
  }

  // 2) Local public/uploads (dev / long-running Node)
  const local = writeLocalPublic(path.join("uploads", pathname), input.bytes);
  if (local) {
    return { ok: true, url: local, storage: "local", id, size: input.bytes.length };
  }

  // 3) Durable base64 store for small images/posters only
  if (input.bytes.length > MAX_DURABLE_BYTES) {
    return {
      ok: false,
      error:
        "Video/large file upload needs BLOB_READ_WRITE_TOKEN on Vercel, or paste a public HTTPS URL. Small images can still be stored in Redis.",
    };
  }

  saveStoredMedia({
    id,
    filename: safeName(input.filename) || `${id}${ext}`,
    contentType,
    base64: input.bytes.toString("base64"),
    size: input.bytes.length,
    createdAt: new Date().toISOString(),
  });

  return {
    ok: true,
    url: `/api/site-content/media/${id}`,
    storage: "durable",
    id,
    size: input.bytes.length,
  };
}

export function mediaUploadHints(): {
  blobConfigured: boolean;
  localWritable: boolean;
  durableMaxMb: number;
} {
  return {
    blobConfigured: !!(process.env.BLOB_READ_WRITE_TOKEN || "").trim(),
    localWritable: !isServerlessRuntime(),
    durableMaxMb: Math.floor(MAX_DURABLE_BYTES / (1024 * 1024)),
  };
}
