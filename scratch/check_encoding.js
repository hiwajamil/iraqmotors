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

function get(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { Authorization: `Bearer ${token}` } }, (res) => {
        let d = '';
        res.on('data', (c) => (d += c));
        res.on('end', () => resolve(JSON.parse(d)));
      })
      .on('error', reject);
  });
}

function codepoints(s) {
  return [...String(s)].map((ch) => ch.codePointAt(0).toString(16)).join(' ');
}

(async () => {
  const csv = fs.readFileSync('Data/brands.csv');
  console.log('file size', csv.length);
  console.log('BOM utf8?', csv[0] === 0xef && csv[1] === 0xbb && csv[2] === 0xbf);

  // Detect likely encoding by trying utf8 vs win1256 for brand 159
  const textUtf8 = csv.toString('utf8');
  const line159 = textUtf8.split(/\r?\n/).find((l) => l.startsWith('159,'));
  console.log('UTF8 line:', line159);
  const arUtf8 = line159.split(',')[2];
  console.log('UTF8 ar:', arUtf8, 'cps:', codepoints(arUtf8));

  // Also try latin1 roundtrip interpretation if file was mis-decoded
  const textLatin1 = csv.toString('latin1');
  const line159L = textLatin1.split(/\r?\n/).find((l) => l.startsWith('159,'));
  console.log('latin1 ar raw:', line159L.split(',')[2]);

  const doc = await get(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/catalog_brands/159`,
  );
  const arDoc = doc.fields.brand_name_ar.stringValue;
  const kuDoc = doc.fields.brand_name_ku?.stringValue;
  console.log('Firestore ar:', arDoc, 'cps:', codepoints(arDoc));
  console.log('Firestore ku:', kuDoc, 'cps:', kuDoc ? codepoints(kuDoc) : null);
  console.log('match utf8?', arDoc === arUtf8);

  // Count replacement chars in all brand ar/ku fields in firestore vs csv
  const brands = textUtf8
    .split(/\r?\n/)
    .slice(1)
    .filter(Boolean)
    .map((l) => {
      // naive split ok for this file
      const p = l.split(',');
      return { id: p[0], ar: p[2], ku: p[3] };
    });

  let bad = 0;
  const samples = [];
  for (const b of brands) {
    const d = await get(
      `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/catalog_brands/${b.id}`,
    );
    const ar = d.fields.brand_name_ar?.stringValue ?? null;
    const ku = d.fields.brand_name_ku?.stringValue ?? null;
    const csvAr = b.ar === '' ? null : b.ar;
    const csvKu = b.ku === '' ? null : b.ku;
    const arBad = ar && ar.includes('\uFFFD');
    const kuBad = ku && ku.includes('\uFFFD');
    const arMismatch = ar !== csvAr;
    const kuMismatch = ku !== csvKu;
    if (arBad || kuBad || arMismatch || kuMismatch) {
      bad++;
      if (samples.length < 15) {
        samples.push({
          id: b.id,
          csvAr,
          ar,
          csvKu,
          ku,
          arBad,
          kuBad,
          arMismatch,
          kuMismatch,
        });
      }
    }
  }
  console.log('brands with ar/ku issues:', bad, '/', brands.length);
  console.log(JSON.stringify(samples, null, 2));
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
