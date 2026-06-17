import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { S3Client, ListObjectsV2Command, PutObjectCommand } from '@aws-sdk/client-s3';

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

const env = loadEnv(new URL('../.env', import.meta.url));
const endpoint = env.R2_ENDPOINT_URL;
const bucket = env.R2_BUCKET_NAME || 'iqmotors-media';
const publicBase = env.R2_PUBLIC_BASE_URL || '';

const client = new S3Client({
  region: env.R2_REGION || 'auto',
  endpoint,
  credentials: {
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

const list = await client.send(
  new ListObjectsV2Command({ Bucket: bucket, Prefix: 'cars/', MaxKeys: 5 }),
);
console.log('Bucket:', bucket);
console.log('Endpoint:', endpoint);
console.log('Configured public base:', publicBase);
console.log('Objects:', list.Contents?.map((o) => o.Key).join(', ') || '(none)');

const testKey = `cars/_probe_${Date.now()}.txt`;
await client.send(
  new PutObjectCommand({
    Bucket: bucket,
    Key: testKey,
    Body: 'iqmotors-probe',
    ContentType: 'text/plain',
  }),
);
console.log('Upload OK:', testKey);

const bases = new Set([
  publicBase.replace(/\/+$/, ''),
  'https://media.iqmotors.net',
  'https://cdn.iqmotors.net',
].filter((b) => b && !b.includes('your-public-media-domain') && !b.includes('YOUR_R2_DEV')));

const keys = [testKey, ...(list.Contents?.map((o) => o.Key).filter(Boolean) ?? [])];

for (const base of bases) {
  for (const key of keys) {
    const url = `${base}/${key}`;
    try {
      const res = await fetch(url, { method: 'HEAD' });
      console.log(`${res.status} ${url}`);
      if (res.ok) {
        console.log('\nWORKING PUBLIC BASE:', base);
        console.log(`Set R2_PUBLIC_BASE_URL=${base}`);
        process.exit(0);
      }
    } catch (err) {
      console.log(`ERR ${url}`, err.message);
    }
  }
}

console.log('\nNo public URL detected. Enable R2.dev public access in Cloudflare dashboard.');
