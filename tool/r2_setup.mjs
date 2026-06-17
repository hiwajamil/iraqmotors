import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  S3Client,
  PutBucketCorsCommand,
  PutPublicAccessBlockCommand,
  GetPublicAccessBlockCommand,
} from '@aws-sdk/client-s3';

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

const client = new S3Client({
  region: env.R2_REGION || 'auto',
  endpoint,
  credentials: {
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

const corsRules = [
  {
    AllowedOrigins: [
      'https://iqmotors.net',
      'https://www.iqmotors.net',
      'https://iqmotors-d588d.web.app',
      'https://iqmotors-d588d.firebaseapp.com',
      'http://localhost:8080',
      'http://localhost:5000',
      'http://127.0.0.1:8080',
    ],
    AllowedMethods: ['GET', 'PUT', 'HEAD', 'POST', 'DELETE'],
    AllowedHeaders: ['*'],
    ExposeHeaders: ['ETag'],
    MaxAgeSeconds: 3600,
  },
];

try {
  await client.send(
    new PutBucketCorsCommand({
      Bucket: bucket,
      CORSConfiguration: { CORSRules: corsRules },
    }),
  );
  console.log('CORS configured for bucket:', bucket);
} catch (err) {
  console.error('CORS setup failed:', err.message);
}

try {
  const block = await client.send(
    new GetPublicAccessBlockCommand({ Bucket: bucket }),
  );
  console.log('Public access block:', JSON.stringify(block.PublicAccessBlockConfiguration));
} catch (err) {
  console.log('Public access block check:', err.message);
}

console.log('');
console.log('Next: enable R2.dev public access in Cloudflare dashboard:');
console.log('  R2 > iqmotors-media > Settings > Public access > Allow Access');
console.log('Then copy the https://pub-xxxx.r2.dev URL into .env as R2_PUBLIC_BASE_URL');
