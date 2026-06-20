# IQ Motors upload Worker (`iqmotors-upload-api`)

Proxies browser image uploads to Cloudflare R2. The Flutter web app POSTs raw JPEG bytes to this Worker; the Worker streams `request.body` into R2 and returns the public URL.

## Fix applied

The previous Worker accepted empty POST bodies and still returned `{ success: true }`, which created **0-byte** objects in R2. This version:

1. Streams `request.body` directly: `await env.BUCKET.put(key, request.body, …)`
2. Rejects `Content-Length: 0`
3. After upload, calls `head()` and **deletes** the object if size is 0

## Deploy with Wrangler (recommended)

### Prerequisites

- [Node.js](https://nodejs.org/) 18+
- Cloudflare account with the `iqmotors-media` R2 bucket
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) logged in

### Steps

1. Open a terminal in this folder:

   ```bash
   cd cloudflare/iqmotors-upload-api
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Edit `wrangler.toml` if needed:

   - `bucket_name` — your R2 bucket (default: `iqmotors-media`)
   - `R2_PUBLIC_BASE_URL` — your R2.dev public URL (from **R2 → bucket → Settings → Public access**)

4. Log in to Cloudflare (once):

   ```bash
   npx wrangler login
   ```

5. Deploy:

   ```bash
   npm run deploy
   ```

6. Confirm the Worker URL matches the app (currently `https://iqmotors-upload-api.hiwa-constructions.workers.dev/`). If the Worker name or account subdomain differs, update:

   - `lib/services/cloudflare_upload_service.dart` → `cloudflareWorkerUrl`
   - `web/index.html` → `WORKER_URL` inside `iqMotorsUploadImage`

## Deploy via Cloudflare Dashboard (no CLI)

Use this if you manage the Worker in the dashboard only.

### 1. Open the Worker

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. **Workers & Pages** → **iqmotors-upload-api** (or create a Worker with that name)

### 2. Paste the code

1. Open **Edit code** (Quick edit or full editor)
2. Replace the entire script with the contents of `src/index.js` in this folder
3. Save / Deploy

### 3. Bind the R2 bucket

1. Worker → **Settings** → **Bindings**
2. **Add binding** → **R2 bucket**
3. Variable name: `BUCKET` (must match the code)
4. Bucket: `iqmotors-media`
5. Save

### 4. Set environment variables

Worker → **Settings** → **Variables**:

| Name | Example value |
|------|----------------|
| `R2_PUBLIC_BASE_URL` | `https://pub-4d3c544f5beb41b1a3cd7a4bd0c205ed.r2.dev` |
| `OBJECT_PREFIX` | `cars` |

No trailing slash on `R2_PUBLIC_BASE_URL`.

### 5. Deploy

Click **Deploy** / **Save and deploy**.

## Test

```bash
curl -X POST \
  -H "Content-Type: image/jpeg" \
  --data-binary @../../tool/test-upload.jpg \
  https://iqmotors-upload-api.hiwa-constructions.workers.dev/
```

Expected: `{"success":true,"url":"https://pub-....r2.dev/cars/....jpg","size":8252}`

Empty body must fail:

```bash
curl -X POST -H "Content-Type: image/jpeg" -H "Content-Length: 0" \
  https://iqmotors-upload-api.hiwa-constructions.workers.dev/
```

Expected: HTTP 400 with `"Empty request body"`.

Verify in **R2 → iqmotors-media → Objects** that new files under `cars/` have non-zero size.
