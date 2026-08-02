/**
 * Site media upload helpers.
 * Priority: Vercel Blob (BLOB_READ_WRITE_TOKEN) → local public/uploads → small durable store.
 *
 * Prefer client-direct uploads via /api/site-content/blob for videos (serverless body limit ~4.5MB).
 */
import fs from "fs";
import path from "path";
import { randomBytes } from "crypto";
import { put } from "@vercel/blob";
import { isServerlessRuntime } from "@/server/cloud/data-root";
import { saveStoredMedia } from "./store";

const MAX_DURABLE_BYTES = 1_400_000; // stay under typical Upstash value limits
const MAX_UPLOAD_BYTES = 500 * 1024 * 1024; // 500MB CMS cap (existing exports / YouCut)

const ALLOWED_EXT: Record<string, string> = {
  ".mp4": "video/mp4",
  ".webm": "video/webm",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".webp": "image/webp",
  ".gif": "image/gif",
};

export type UploadResult =
  | { ok: true; url: string; storage: "blob" | "local" | "durable"; id: string; size: number }
  | { ok: false; error: string };

function extOf(filename: string): string {
  return path.extname(filename || "").toLowerCase();
}

/** Infer MIME when browsers send empty or application/octet-stream. */
export function resolveUploadContentType(filename: string, contentType: string): string {
  const raw = (contentType || "").split(";")[0].trim().toLowerCase();
  if (raw && raw !== "application/octet-stream" && Object.values(ALLOWED_EXT).includes(raw)) {
    return raw;
  }
  const fromExt = ALLOWED_EXT[extOf(filename)];
  if (fromExt) return fromExt;
  return raw || "application/octet-stream";
}

function safeName(filename: string): string {
  return (filename || "upload")
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/-+/g, "-")
    .slice(0, 80);
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
  const contentType = resolveUploadContentType(input.filename, input.contentType);
  if (!Object.values(ALLOWED_EXT).includes(contentType)) {
    return {
      ok: false,
      error: `Unsupported type "${contentType || "unknown"}" for "${input.filename}". Use mp4, webm, jpg, png, webp, or gif.`,
    };
  }
  if (!input.bytes?.length) return { ok: false, error: "Empty file." };
  if (input.bytes.length > MAX_UPLOAD_BYTES) {
    return { ok: false, error: `File too large (max ${Math.floor(MAX_UPLOAD_BYTES / (1024 * 1024))}MB).` };
  }

  // Serverless request body limit is ~4.5MB — tell admin to use client Blob path.
  if (isServerlessRuntime() && input.bytes.length > 4_200_000) {
    return {
      ok: false,
      error:
        "This video is too large for server upload. Use the updated Site Content uploader (direct Blob), or compress under ~4MB.",
    };
  }

  const id = `scm_${Date.now().toString(36)}_${randomBytes(4).toString("hex")}`;
  const ext = extOf(input.filename) || `.${contentType.split("/")[1] || "bin"}`;
  const pathname = `site-content/${id}-${safeName(input.filename).replace(/\.[^.]+$/, "")}${ext}`;

  // 1) Vercel Blob SDK
  if ((process.env.BLOB_READ_WRITE_TOKEN || "").trim()) {
    try {
      const blob = await put(pathname, input.bytes, {
        access: "public",
        contentType,
        token: process.env.BLOB_READ_WRITE_TOKEN,
      });
      return { ok: true, url: blob.url, storage: "blob", id, size: input.bytes.length };
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Blob upload failed";
      if (input.bytes.length > MAX_DURABLE_BYTES) {
        return { ok: false, error: msg };
      }
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
        "Video/large file upload needs Vercel Blob. Refresh this page after deploy, or paste a public HTTPS MP4 URL.",
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
  clientUpload: boolean;
} {
  const blobConfigured = !!(process.env.BLOB_READ_WRITE_TOKEN || "").trim();
  return {
    blobConfigured,
    localWritable: !isServerlessRuntime(),
    durableMaxMb: Math.floor(MAX_DURABLE_BYTES / (1024 * 1024)),
    clientUpload: blobConfigured,
  };
}
