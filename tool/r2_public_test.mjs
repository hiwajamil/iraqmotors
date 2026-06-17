import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

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
const endpoint = env.R2_ENDPOINT_URL.replace(/\/+$/, '');
const bucket = env.R2_BUCKET_NAME || 'iqmotors-media';
const key = `cars/_public_test_${Date.now()}.txt`;

const client = new S3Client({
  region: env.R2_REGION || 'auto',
  endpoint,
  credentials: {
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

await client.send(
  new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: 'public-test',
    ContentType: 'text/plain',
    ACL: 'public-read',
  }),
);

const urls = [
  `${endpoint}/${bucket}/${key}`,
  `${endpoint}/${key}`,
  `https://${bucket}.${new URL(endpoint).host}/${key}`,
];

for (const url of urls) {
  try {
    const res = await fetch(url);
    console.log(res.status, url, await res.text());
  } catch (e) {
    console.log('ERR', url, e.message);
  }
}
