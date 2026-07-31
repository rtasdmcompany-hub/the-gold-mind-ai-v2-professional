/**
 * Shared secret header name used to authorize the portal's own same-origin
 * fetch of /releases/* static assets (serverless fallback when local disk
 * reads fail). Never advertised to browsers/customers — /releases/* is not
 * a public download surface; the only customer path is
 * /api/releases/download/[id].
 */
export const RELEASE_INTERNAL_FETCH_HEADER = "x-tgm-internal-release-fetch";
