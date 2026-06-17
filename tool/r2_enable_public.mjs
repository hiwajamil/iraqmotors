import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { S3Client, PutBucketCorsCommand } from '@aws-sdk/client-s3';

function loadEnv(pathOrUrl) {
  const env = {};
  const filePath =
    typeof pathOrUrl === 'string' ? pathOrUrl : fileURLToPath(pathOrUrl);
  for (const line of readFileSync(filePath, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    env[trimmed.slice(0, idx).trim()] = trimmed.slice(idx + 1).trim();
  }
  return env;
}

function updateEnvPublicUrl(filePath, publicUrl) {
  const lines = readFileSync(filePath, 'utf8').split(/\r?\n/);
  let replaced = false;
  const next = lines.map((line) => {
    if (line.startsWith('R2_PUBLIC_BASE_URL=')) {
      replaced = true;
      return `R2_PUBLIC_BASE_URL=${publicUrl}`;
    }
    return line;
  });
  if (!replaced) next.push(`R2_PUBLIC_BASE_URL=${publicUrl}`);
  writeFileSync(filePath, `${next.join('\n').replace(/\n?$/, '\n')}`, 'utf8');
}

const envPath = fileURLToPath(new URL('../.env', import.meta.url));
const env = loadEnv(envPath);
const accountId =
  env.CLOUDFLARE_ACCOUNT_ID ||
  env.R2_ENDPOINT_URL?.match(
    /https?:\/\/([a-f0-9]+)\.r2\.cloudflarestorage\.com/i,
  )?.[1];
const bucket = env.R2_BUCKET_NAME || 'iqmotors-media';
const apiToken = env.CLOUDFLARE_API_TOKEN?.trim();

if (!accountId) {
  console.error('Missing CLOUDFLARE_ACCOUNT_ID or R2_ENDPOINT_URL account id.');
  process.exit(1);
}

if (!apiToken) {
  console.error(
    'Missing CLOUDFLARE_API_TOKEN in .env — create one at\n' +
      'https://dash.cloudflare.com/profile/api-tokens with R2 Edit permission.',
  );
  process.exit(1);
}

const corsConfig = JSON.parse(
  readFileSync(new URL('./r2-cors-s3.json', import.meta.url), 'utf8'),
);

// 1) Enable r2.dev public access via Cloudflare API
const managedBase = `https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets/${bucket}/domains/managed`;
const enableRes = await fetch(managedBase, {
  method: 'PUT',
  headers: {
    Authorization: `Bearer ${apiToken}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ enabled: true }),
});
const enableJson = await enableRes.json();
if (!enableRes.ok) {
  console.error('Enable public access failed:', JSON.stringify(enableJson, null, 2));
  process.exit(1);
}

// 2) Read public dev URL
const getRes = await fetch(managedBase, {
  headers: { Authorization: `Bearer ${apiToken}` },
});
const getJson = await getRes.json();
if (!getRes.ok) {
  console.error('Fetch public URL failed:', JSON.stringify(getJson, null, 2));
  process.exit(1);
}

const result = getJson?.result;
const publicUrl = result?.domain
  ? `https://${result.domain}`.replace(/\/+$/, '')
  : result?.url?.replace(/\/+$/, '');

if (!publicUrl) {
  console.error('No public URL in API response:', JSON.stringify(getJson, null, 2));
  process.exit(1);
}

console.log('Public R2 URL:', publicUrl);
updateEnvPublicUrl(envPath, publicUrl);
console.log('Updated .env R2_PUBLIC_BASE_URL');

// 3) Apply CORS via S3 API (needs R2 token with Admin/Object Read & Write)
const s3 = new S3Client({
  region: env.R2_REGION || 'auto',
  endpoint: env.R2_ENDPOINT_URL,
  credentials: {
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

try {
  await s3.send(
    new PutBucketCorsCommand({
      Bucket: bucket,
      CORSConfiguration: corsConfig,
    }),
  );
  console.log('CORS policy applied via S3 API');
} catch (err) {
  console.warn('CORS via S3 API failed:', err.message);
  console.warn('Paste tool/r2-cors.json into bucket CORS settings in dashboard.');
}

console.log('\nDone. Run: flutter build web && firebase deploy --only hosting');
