/**
 * IQ Motors image upload proxy — streams POST body directly into R2.
 *
 * Client contract (Flutter web / index.html):
 *   POST /
 *   Content-Type: image/jpeg
 *   Body: raw JPEG bytes
 *   Response: { "success": true, "url": "https://pub-....r2.dev/cars/....jpg" }
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Filename',
  'Access-Control-Max-Age': '86400',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    if (request.method !== 'POST') {
      return json({ success: false, error: 'Method not allowed' }, 405);
    }

    if (!env.BUCKET) {
      return json(
        { success: false, error: 'R2 bucket binding BUCKET is not configured' },
        500,
      );
    }

    const publicBase = (env.R2_PUBLIC_BASE_URL || '').replace(/\/+$/, '');
    if (!publicBase) {
      return json(
        { success: false, error: 'R2_PUBLIC_BASE_URL is not configured' },
        500,
      );
    }

    const contentLengthHeader = request.headers.get('Content-Length');
    if (contentLengthHeader === '0') {
      return json(
        { success: false, error: 'Empty request body (Content-Length: 0)' },
        400,
      );
    }

    if (!request.body) {
      return json({ success: false, error: 'Missing request body stream' }, 400);
    }

    const contentType =
      request.headers.get('Content-Type')?.trim() || 'image/jpeg';
    const key = buildObjectKey(
      request.headers.get('X-Filename'),
      env.OBJECT_PREFIX || 'cars',
    );

    try {
      // Stream the raw POST body into R2 — do NOT call request.text(),
      // request.json(), or request.arrayBuffer() before this put().
      await env.BUCKET.put(key, request.body, {
        httpMetadata: { contentType },
      });

      const head = await env.BUCKET.head(key);
      const size = head?.size ?? 0;
      if (size === 0) {
        await env.BUCKET.delete(key);
        return json(
          {
            success: false,
            error:
              'Upload rejected: R2 object is 0 bytes. The client sent an empty body.',
          },
          400,
        );
      }

      const url = `${publicBase}/${key}`;
      return json({ success: true, url, size });
    } catch (err) {
      return json(
        { success: false, error: err instanceof Error ? err.message : String(err) },
        500,
      );
    }
  },
};

function buildObjectKey(filenameHeader, prefix) {
  const safePrefix = String(prefix || 'cars').replace(/^\/+|\/+$/g, '');
  const sanitized = sanitizeFilename(filenameHeader);
  const name =
    sanitized ||
    `${Date.now()}_${crypto.randomUUID().slice(0, 8)}.jpg`;
  return safePrefix ? `${safePrefix}/${name}` : name;
}

function sanitizeFilename(name) {
  if (!name) return '';
  const base = name.trim().split(/[/\\]/).pop();
  if (!base || base === '.' || base === '..') return '';
  return base.replace(/[^\w.\-()+@]/g, '_');
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...CORS,
      'Content-Type': 'application/json; charset=utf-8',
    },
  });
}
