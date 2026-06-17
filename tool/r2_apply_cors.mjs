import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { S3Client, PutBucketCorsCommand, GetBucketCorsCommand } from '@aws-sdk/client-s3';

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
const bucket = env.R2_BUCKET_NAME || 'iqmotors-media';
const corsConfig = JSON.parse(
  readFileSync(new URL('./r2-cors-s3.json', import.meta.url), 'utf8'),
);

const client = new S3Client({
  region: env.R2_REGION || 'auto',
  endpoint: env.R2_ENDPOINT_URL,
  credentials: {
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

try {
  await client.send(
    new PutBucketCorsCommand({ Bucket: bucket, CORSConfiguration: corsConfig }),
  );
  console.log('CORS applied successfully');
  const current = await client.send(new GetBucketCorsCommand({ Bucket: bucket }));
  console.log(JSON.stringify(current.CORSRules, null, 2));
} catch (err) {
  console.error('CORS failed:', err.message);
  process.exit(1);
}
