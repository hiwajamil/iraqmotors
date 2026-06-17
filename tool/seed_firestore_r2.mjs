import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';
import { join } from 'node:path';

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

async function getFirebaseAccessToken() {
  const configPath = join(homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  const refreshToken = config?.tokens?.refresh_token;
  if (!refreshToken) throw new Error('Firebase CLI not logged in. Run: firebase login');

  const body = new URLSearchParams({
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
    refresh_token: refreshToken,
    grant_type: 'refresh_token',
  });

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`Firebase token refresh failed: ${json.error_description || json.error}`);
  return json.access_token;
}

const env = loadEnv(new URL('../.env', import.meta.url));
const projectId = 'iqmotors-d588d';
const accessToken = await getFirebaseAccessToken();

const patch = {
  fields: {
    r2Endpoint: { stringValue: env.R2_ENDPOINT_URL || '' },
    r2AccessKey: { stringValue: env.R2_ACCESS_KEY_ID || '' },
    r2SecretKey: { stringValue: env.R2_SECRET_ACCESS_KEY || '' },
    r2Bucket: { stringValue: env.R2_BUCKET_NAME || 'iqmotors-media' },
    r2PublicBaseUrl: { stringValue: env.R2_PUBLIC_BASE_URL || '' },
    r2Region: { stringValue: env.R2_REGION || 'auto' },
  },
};

const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/system_config/platform?updateMask.fieldPaths=r2Endpoint&updateMask.fieldPaths=r2AccessKey&updateMask.fieldPaths=r2SecretKey&updateMask.fieldPaths=r2Bucket&updateMask.fieldPaths=r2PublicBaseUrl&updateMask.fieldPaths=r2Region`;

const res = await fetch(url, {
  method: 'PATCH',
  headers: {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(patch),
});

const json = await res.json();
if (!res.ok) {
  console.error('Firestore update failed:', JSON.stringify(json, null, 2));
  process.exit(1);
}

console.log('Firestore system_config/platform R2 fields updated.');
