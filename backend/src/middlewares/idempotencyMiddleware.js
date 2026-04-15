/**
 * Very small idempotency middleware for server-to-server webhooks.
 *
 * - Uses `x-idempotency-key` header.
 * - Stores the first response for a short TTL and replays it on retries.
 * - In-memory only (good for single-instance Render; not shared across instances).
 */
const DEFAULT_TTL_MS = 5 * 60 * 1000; // 5 minutes

/** @type {Map<string, { expiresAt: number, statusCode: number, body: any }>} */
const store = new Map();

function cleanupNow(now) {
  for (const [key, value] of store.entries()) {
    if (value.expiresAt <= now) store.delete(key);
  }
}

/**
 * @param {{ ttlMs?: number }} [options]
 */
export function idempotency(options = {}) {
  const ttlMs = options.ttlMs ?? DEFAULT_TTL_MS;

  return (req, res, next) => {
    const keyRaw = req.headers["x-idempotency-key"];
    const key = Array.isArray(keyRaw) ? keyRaw[0] : keyRaw;

    if (!key || typeof key !== "string" || key.trim().length < 8) {
      return next();
    }

    const now = Date.now();
    cleanupNow(now);

    const hit = store.get(key);
    if (hit && hit.expiresAt > now) {
      return res.status(hit.statusCode).json(hit.body);
    }

    const originalJson = res.json.bind(res);
    res.json = (body) => {
      store.set(key, {
        expiresAt: now + ttlMs,
        statusCode: res.statusCode || 200,
        body,
      });
      return originalJson(body);
    };

    next();
  };
}

