/**
 * IQ Motors image upload proxy — streams POST body directly into R2
 * after strict AI image moderation with Google Gemini 2.5 Flash.
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

// Gemini 2.5 Flash is now the recommended stable endpoint.
// Updated moderation prompt to require more specific rejection messages.
const GEMINI_MODERATION_PROMPT =
  `You are a strict automotive image moderator. Analyze this image. Return ONLY a valid JSON object with no markdown. The JSON must have two keys: \`is_valid\` (boolean: true ONLY if the image clearly contains a real car or car parts) and \`reason\` (string: empty if true. If false, provide a short, polite explanation in Kurdish Sorani for why it was rejected, using these guidelines:
- If only some images are invalid, explicitly state: 'یەکێک لە وێنەکان یان چەند دانەیەکی پەیوەندی بە ئۆتۆمبێلەوە نییە'.
- If the images are not the same car, state: 'وێنەکان هەموویان هی یەک ئۆتۆمبێل نین'.
- Otherwise explain the specific reason, e.g., 'ئەم وێنەیە پەیوەندی بە ئۆتۆمبێلەوە نییە'.)`;

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    if (request.method !== 'POST') {
      return json({ success: false, error: 'Method not allowed' }, 405);
    }

    const R2_BUCKET = env.BUCKET || env.R2_BUCKET; // Support both BUCKET and R2_BUCKET naming
    if (!R2_BUCKET) {
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

    if (!env.GEMINI_API_KEY) {
      return json(
        { success: false, error: 'GEMINI_API_KEY is not configured' },
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

    // Get content type or default
    const contentType =
      request.headers.get('Content-Type')?.trim() || 'image/jpeg';
    const key = buildObjectKey(
      request.headers.get('X-Filename'),
      env.OBJECT_PREFIX || 'cars',
    );

    let imageBuffer;
    try {
      imageBuffer = await request.arrayBuffer();
    } catch (err) {
      return json(
        { success: false, error: 'Failed to read image body: ' + err },
        400,
      );
    }

    const imageBase64 = arrayBufferToBase64(imageBuffer);

    // Prepare Gemini payload
    const geminiReqBody = {
      contents: [
        {
          role: "user",
          parts: [
            { text: GEMINI_MODERATION_PROMPT },
            {
              inlineData: {
                mimeType: contentType,
                data: imageBase64,
              }
            }
          ]
        },
      ]
    };

    let geminiResponseJson;
    try {
      // IMPORTANT: Use the current v2.5-flash stable API and pass the key as query param (no encodeURIComponent needed as per Google guidance)
      const geminiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${env.GEMINI_API_KEY}`;
      const geminiResp = await fetch(
        geminiApiUrl,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(geminiReqBody),
        }
      );

      if (!geminiResp.ok) {
        const errorText = await geminiResp.text();
        return json(
          { success: false, error: `Gemini moderation failed: ${geminiResp.status} ${errorText}` },
          500,
        );
      }

      const geminiJson = await geminiResp.json();
      let content;
      // The Gemini response puts model output in `candidates[0].content.parts[0].text`
      if (
        geminiJson?.candidates &&
        geminiJson.candidates[0]?.content?.parts &&
        geminiJson.candidates[0].content.parts[0].text
      ) {
        content = geminiJson.candidates[0].content.parts[0].text;
      } else {
        return json(
          { success: false, error: 'Gemini moderation response did not contain a usable answer' },
          500,
        );
      }
      // The answer MUST be a JSON object. Try to parse it.
      try {
        geminiResponseJson = JSON.parse(content);
      } catch (err) {
        return json(
          { success: false, error: `Gemini response was not valid JSON: ${content}` },
          500,
        );
      }
    } catch (err) {
      return json(
        { success: false, error: `Gemini fetch failed: ${String(err)}` },
        500,
      );
    }

    // Process moderation result
    if (!geminiResponseJson || typeof geminiResponseJson.is_valid !== 'boolean') {
      return json(
        { success: false, error: 'Invalid response from Gemini: missing `is_valid`' },
        500,
      );
    }

    if (!geminiResponseJson.is_valid) {
      // AI blocked the image: do NOT upload; show Kurdish reason from Gemini
      return json(
        { success: false, reason: String(geminiResponseJson.reason || '') },
        400,
      );
    }

    // Otherwise: save to R2 as before
    try {
      await R2_BUCKET.put(key, imageBuffer, {
        httpMetadata: { contentType },
      });

      const head = await R2_BUCKET.head(key);
      const size = head?.size ?? 0;
      if (size === 0) {
        await R2_BUCKET.delete(key);
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

// Utility to encode ArrayBuffer to base64
function arrayBufferToBase64(buf) {
  // Cloudflare Workers: ArrayBuffer -> Uint8Array -> btoa on string
  let binary = '';
  const bytes = new Uint8Array(buf);
  const len = bytes.byteLength;
  for (let i = 0; i < len; ++i) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

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
