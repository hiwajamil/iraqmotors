'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

const PROJECT = 'iqmotors-d588d';
const token = JSON.parse(
  fs.readFileSync(
    path.join(os.homedir(), '.config/configstore/firebase-tools.json'),
    'utf8',
  ),
).tokens.access_token;

function cps(s) {
  return [...String(s)].map((c) => c.codePointAt(0).toString(16)).join(' ');
}

function parseCsv(text) {
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
  const rows = [];
  let row = [];
  let field = '';
  let q = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const next = text[i + 1];
    if (q) {
      if (ch === '"' && next === '"') {
        field += '"';
        i++;
      } else if (ch === '"') q = false;
      else field += ch;
      continue;
    }
    if (ch === '"') q = true;
    else if (ch === ',') {
      row.push(field);
      field = '';
    } else if (ch === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (ch !== '\r') field += ch;
  }
  if (field.length || row.length) {
    row.push(field);
    rows.push(row);
  }
  const headers = rows[0].map((h) => h.trim());
  return rows
    .slice(1)
    .filter((r) => !(r.length === 1 && !String(r[0]).trim()))
    .map((r) => {
      const o = {};
      headers.forEach((h, i) => {
        o[h] = r[i] ?? '';
      });
      return o;
    });
}

function req(method, url, body) {
  return new Promise((resolve, reject) => {
    const payload = body ? Buffer.from(JSON.stringify(body), 'utf8') : null;
    const u = new URL(url);
    const r = https.request(
      {
        hostname: u.hostname,
        path: u.pathname + u.search,
        method,
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json; charset=utf-8',
          ...(payload ? { 'Content-Length': payload.length } : {}),
        },
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          const data = Buffer.concat(chunks).toString('utf8');
          resolve({ status: res.statusCode, body: data ? JSON.parse(data) : null });
        });
      },
    );
    r.on('error', reject);
    if (payload) r.write(payload);
    r.end();
  });
}

(async () => {
  const models = parseCsv(fs.readFileSync('Data/models.csv', 'utf8'));
  const row = models.find((m) => m.model_id === '1468');
  console.log('CSV row:', row);
  console.log('CSV ku:', row.model_name_ku, 'cps:', cps(row.model_name_ku));
  console.log('CSV ku has FFFD?', row.model_name_ku.includes('\uFFFD'));

  const before = await req(
    'GET',
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/catalog_models/1468`,
  );
  const kuBefore = before.body.fields.model_name_ku.stringValue;
  console.log('DOC before ku:', kuBefore, 'cps:', cps(kuBefore));
  console.log('DOC has FFFD?', kuBefore.includes('\uFFFD'));
  console.log('equal?', kuBefore === row.model_name_ku);

  // Patch single field
  const patchBody = {
    fields: {
      model_name_ku: { stringValue: row.model_name_ku },
    },
  };
  const patched = await req(
    'PATCH',
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/catalog_models/1468?updateMask.fieldPaths=model_name_ku`,
    patchBody,
  );
  console.log('patch status', patched.status);
  const kuAfter = patched.body.fields.model_name_ku.stringValue;
  console.log('DOC after ku:', kuAfter, 'cps:', cps(kuAfter));
  console.log('equal after?', kuAfter === row.model_name_ku);

  // Full scan models for FFFD
  let page = null;
  const bad = [];
  do {
    let url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/catalog_models?pageSize=300`;
    if (page) url += `&pageToken=${encodeURIComponent(page)}`;
    const res = await req('GET', url);
    for (const d of res.body.documents || []) {
      const fields = d.fields || {};
      for (const [k, v] of Object.entries(fields)) {
        if (v.stringValue && v.stringValue.includes('\uFFFD')) {
          bad.push({ id: d.name.split('/').pop(), field: k, value: v.stringValue });
        }
      }
    }
    page = res.body.nextPageToken || null;
  } while (page);
  console.log('models with FFFD after patch:', bad.length);
  console.log(JSON.stringify(bad.slice(0, 20), null, 2));
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
