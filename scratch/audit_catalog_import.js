/**
 * Audit Data/*.csv vs Firestore catalog collections.
 * Usage: node scratch/audit_catalog_import.js
 */
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

const PROJECT_ID = 'iqmotors-d588d';
const ROOT = path.resolve(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'Data');
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function loadToken() {
  const cfg = JSON.parse(
    fs.readFileSync(
      path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json'),
      'utf8',
    ),
  );
  return cfg.tokens.access_token;
}

function httpsJson(method, url, body, token) {
  return new Promise((resolve, reject) => {
    const payload = body === undefined ? null : JSON.stringify(body);
    const u = new URL(url);
    const headers = {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    };
    if (payload) headers['Content-Length'] = Buffer.byteLength(payload);
    const req = https.request(
      {
        hostname: u.hostname,
        path: u.pathname + u.search,
        method,
        headers,
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          let parsed = null;
          try {
            parsed = data ? JSON.parse(data) : null;
          } catch {
            parsed = { raw: data };
          }
          if (res.statusCode >= 200 && res.statusCode < 300) resolve(parsed);
          else
            reject(
              new Error(
                `HTTP ${res.statusCode}: ${JSON.stringify(parsed).slice(0, 400)}`,
              ),
            );
        });
      },
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const next = text[i + 1];
    if (inQuotes) {
      if (ch === '"' && next === '"') {
        field += '"';
        i++;
      } else if (ch === '"') inQuotes = false;
      else field += ch;
      continue;
    }
    if (ch === '"') inQuotes = true;
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

function fromValue(v) {
  if (!v || typeof v !== 'object') return undefined;
  if ('nullValue' in v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(fromValue);
  if ('mapValue' in v) {
    const out = {};
    for (const [k, val] of Object.entries(v.mapValue.fields || {})) {
      out[k] = fromValue(val);
    }
    return out;
  }
  return undefined;
}

function fromDoc(doc) {
  const out = {};
  for (const [k, v] of Object.entries(doc.fields || {})) out[k] = fromValue(v);
  return out;
}

async function listIds(token, collection) {
  const ids = new Set();
  let pageToken = null;
  do {
    let url = `${BASE}/${collection}?pageSize=300&mask.fieldPaths=__name__`;
    if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;
    const res = await httpsJson('GET', url, undefined, token);
    for (const d of res.documents || []) {
      ids.add(d.name.split('/').pop());
    }
    pageToken = res.nextPageToken || null;
  } while (pageToken);
  return ids;
}

async function getDoc(token, collection, id) {
  try {
    const res = await httpsJson(
      'GET',
      `${BASE}/${collection}/${encodeURIComponent(id)}`,
      undefined,
      token,
    );
    return fromDoc(res);
  } catch (e) {
    if (String(e.message).includes('HTTP 404')) return null;
    throw e;
  }
}

function slugify(nameEn) {
  return String(nameEn)
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .replace(/_+/g, '_');
}

function expectedBrandFields() {
  return [
    'brand_id',
    'brand_name_en',
    'brand_name_ar',
    'brand_name_ku',
    'category_id',
    'sort',
    'description_en',
    'description_ar',
    'description_ku',
    'slug',
  ];
}

function expectedModelFields() {
  return [
    'model_id',
    'brand_id',
    'brand_name_en',
    'model_name_en',
    'model_name_ar',
    'model_name_ku',
    'sort',
    'from_year_id',
    'to_year_id',
    'segment_id',
    'sub_segment_id',
    'deleted',
  ];
}

function expectedTrimFields() {
  return [
    'trim_id',
    'trim_name',
    'model_id',
    'model_name_en',
    'brand_id',
    'brand_name_en',
    'from_year_id',
    'to_year_id',
    'deleted',
  ];
}

function compareRowToDoc(csvRow, doc, fieldMap) {
  const diffs = [];
  for (const [csvKey, docKey] of Object.entries(fieldMap)) {
    const raw = String(csvRow[csvKey] ?? '').trim();
    const csvVal = raw === '' ? null : raw;
    let docVal = doc[docKey];
    if (docVal === undefined) {
      diffs.push(`${csvKey}: missing in doc`);
      continue;
    }
    if (csvVal === null && docVal === null) continue;
    if (typeof docVal === 'number') {
      if (csvVal === null) {
        diffs.push(`${csvKey}: csv empty vs doc ${docVal}`);
      } else if (Number(csvVal) !== docVal) {
        diffs.push(`${csvKey}: csv=${csvVal} doc=${docVal}`);
      }
      continue;
    }
    if (typeof docVal === 'boolean') {
      const csvBool = ['true', '1', 'yes'].includes(String(csvVal).toLowerCase());
      if (csvVal === null && docVal === false) continue;
      if (csvBool !== docVal) diffs.push(`${csvKey}: csv=${csvVal} doc=${docVal}`);
      continue;
    }
    if (String(csvVal) !== String(docVal)) {
      diffs.push(`${csvKey}: csv=${csvVal} doc=${docVal}`);
    }
  }
  return diffs;
}

async function main() {
  const token = loadToken();

  const brands = parseCsv(fs.readFileSync(path.join(DATA_DIR, 'brands.csv'), 'utf8'));
  const models = parseCsv(fs.readFileSync(path.join(DATA_DIR, 'models.csv'), 'utf8'));
  const trims = parseCsv(fs.readFileSync(path.join(DATA_DIR, 'trims.csv'), 'utf8'));
  const bmt = parseCsv(
    fs.readFileSync(path.join(DATA_DIR, 'brands_models_trims.csv'), 'utf8'),
  );

  console.log('=== SOURCE CSV ===');
  console.log(`brands: ${brands.length}`);
  console.log(`  cols: ${Object.keys(brands[0]).join(', ')}`);
  console.log(`models: ${models.length}`);
  console.log(`  cols: ${Object.keys(models[0]).join(', ')}`);
  console.log(`trims:  ${trims.length}`);
  console.log(`  cols: ${Object.keys(trims[0]).join(', ')}`);
  console.log(
    `brands_models_trims: ${bmt.length} (derived join; not stored as its own collection)`,
  );

  console.log('\n=== FIRESTORE ID COVERAGE ===');
  const fbBrands = await listIds(token, 'catalog_brands');
  const fbModels = await listIds(token, 'catalog_models');
  const fbTrims = await listIds(token, 'catalog_trims');

  const missB = brands.map((r) => r.brand_id).filter((id) => !fbBrands.has(String(id)));
  const missM = models.map((r) => r.model_id).filter((id) => !fbModels.has(String(id)));
  const missT = trims.map((r) => r.trim_id).filter((id) => !fbTrims.has(String(id)));
  const extraB = [...fbBrands].filter(
    (id) => !brands.some((r) => String(r.brand_id) === id),
  );
  const extraM = [...fbModels].filter(
    (id) => !models.some((r) => String(r.model_id) === id),
  );
  const extraT = [...fbTrims].filter(
    (id) => !trims.some((r) => String(r.trim_id) === id),
  );

  console.log(
    `catalog_brands: ${fbBrands.size}/${brands.length} missing=${missB.length} extra=${extraB.length}`,
  );
  console.log(
    `catalog_models: ${fbModels.size}/${models.length} missing=${missM.length} extra=${extraM.length}`,
  );
  console.log(
    `catalog_trims:  ${fbTrims.size}/${trims.length} missing=${missT.length} extra=${extraT.length}`,
  );
  if (missB.length) console.log('  missing brand ids:', missB.slice(0, 20).join(', '));
  if (missM.length) console.log('  missing model ids:', missM.slice(0, 20).join(', '));
  if (missT.length) console.log('  missing trim ids:', missT.slice(0, 20).join(', '));

  console.log('\n=== FIELD SCHEMA CHECK (random samples) ===');
  const brandSample = await getDoc(token, 'catalog_brands', brands[0].brand_id);
  const modelSample = await getDoc(token, 'catalog_models', models[0].model_id);
  const trimSample = await getDoc(token, 'catalog_trims', trims[0].trim_id);
  const brandMissingFields = expectedBrandFields().filter((f) => !(f in brandSample));
  const modelMissingFields = expectedModelFields().filter((f) => !(f in modelSample));
  const trimMissingFields = expectedTrimFields().filter((f) => !(f in trimSample));
  console.log('brand fields present:', Object.keys(brandSample).sort().join(', '));
  console.log('  missing expected:', brandMissingFields.join(', ') || 'none');
  console.log('model fields present:', Object.keys(modelSample).sort().join(', '));
  console.log('  missing expected:', modelMissingFields.join(', ') || 'none');
  console.log('trim fields present:', Object.keys(trimSample).sort().join(', '));
  console.log('  missing expected:', trimMissingFields.join(', ') || 'none');

  console.log('\n=== VALUE PARITY (first 50 of each) ===');
  let brandDiffs = 0;
  let modelDiffs = 0;
  let trimDiffs = 0;
  const brandDiffSamples = [];
  const modelDiffSamples = [];
  const trimDiffSamples = [];

  for (const row of brands.slice(0, 50)) {
    const doc = await getDoc(token, 'catalog_brands', row.brand_id);
    const diffs = compareRowToDoc(row, doc, {
      brand_id: 'brand_id',
      brand_name_en: 'brand_name_en',
      brand_name_ar: 'brand_name_ar',
      brand_name_ku: 'brand_name_ku',
      category_id: 'category_id',
      sort: 'sort',
      description_en: 'description_en',
      description_ar: 'description_ar',
      description_ku: 'description_ku',
    });
    if (diffs.length) {
      brandDiffs++;
      if (brandDiffSamples.length < 5)
        brandDiffSamples.push(`${row.brand_id}: ${diffs.join('; ')}`);
    }
  }
  for (const row of models.slice(0, 50)) {
    const doc = await getDoc(token, 'catalog_models', row.model_id);
    const diffs = compareRowToDoc(row, doc, {
      model_id: 'model_id',
      brand_id: 'brand_id',
      brand_name_en: 'brand_name_en',
      model_name_en: 'model_name_en',
      model_name_ar: 'model_name_ar',
      model_name_ku: 'model_name_ku',
      sort: 'sort',
      from_year_id: 'from_year_id',
      to_year_id: 'to_year_id',
      segment_id: 'segment_id',
      sub_segment_id: 'sub_segment_id',
      deleted: 'deleted',
    });
    if (diffs.length) {
      modelDiffs++;
      if (modelDiffSamples.length < 5)
        modelDiffSamples.push(`${row.model_id}: ${diffs.join('; ')}`);
    }
  }
  for (const row of trims.slice(0, 50)) {
    const doc = await getDoc(token, 'catalog_trims', row.trim_id);
    const diffs = compareRowToDoc(row, doc, {
      trim_id: 'trim_id',
      trim_name: 'trim_name',
      model_id: 'model_id',
      model_name_en: 'model_name_en',
      brand_id: 'brand_id',
      brand_name_en: 'brand_name_en',
      from_year_id: 'from_year_id',
      to_year_id: 'to_year_id',
      deleted: 'deleted',
    });
    if (diffs.length) {
      trimDiffs++;
      if (trimDiffSamples.length < 5)
        trimDiffSamples.push(`${row.trim_id}: ${diffs.join('; ')}`);
    }
  }
  console.log(`brands with diffs (of 50): ${brandDiffs}`);
  if (brandDiffSamples.length) console.log(brandDiffSamples.join('\n'));
  console.log(`models with diffs (of 50): ${modelDiffs}`);
  if (modelDiffSamples.length) console.log(modelDiffSamples.join('\n'));
  console.log(`trims with diffs (of 50): ${trimDiffs}`);
  if (trimDiffSamples.length) console.log(trimDiffSamples.join('\n'));

  console.log('\n=== car_metadata MIRROR ===');
  let metaMissing = 0;
  let metaModelMismatch = 0;
  const metaMissSamples = [];
  const modelsByBrand = new Map();
  for (const m of models) {
    if (String(m.deleted).toLowerCase() === 'true') continue;
    const bid = m.brand_id;
    if (!modelsByBrand.has(bid)) modelsByBrand.set(bid, []);
    modelsByBrand.get(bid).push(m);
  }
  const slugCounts = new Map();
  for (const b of brands) {
    let slug = slugify(b.brand_name_en);
    const c = (slugCounts.get(slug) || 0) + 1;
    slugCounts.set(slug, c);
    if (c > 1) slug = `${slug}_${b.brand_id}`;
    const meta = await getDoc(token, 'car_metadata', slug);
    if (!meta) {
      metaMissing++;
      if (metaMissSamples.length < 10) metaMissSamples.push(`${b.brand_name_en} -> ${slug}`);
      continue;
    }
    const metaModelCount = Object.keys(meta.models || {}).length;
    const csvModelCount = (modelsByBrand.get(b.brand_id) || []).length;
    if (metaModelCount !== csvModelCount) {
      metaModelMismatch++;
      if (metaMissSamples.length < 15) {
        metaMissSamples.push(
          `${b.brand_name_en}: csvModels=${csvModelCount} metaModels=${metaModelCount}`,
        );
      }
    }
  }
  console.log(`brands with missing car_metadata slug: ${metaMissing}`);
  console.log(`brands with model-count mismatch in mirror: ${metaModelMismatch}`);
  if (metaMissSamples.length) console.log(metaMissSamples.join('\n'));

  // BMT join coverage: every BMT row should resolve
  console.log('\n=== brands_models_trims.csv JOIN COVERAGE ===');
  let bmtOk = 0;
  let bmtBad = 0;
  for (const row of bmt) {
    const hasBrand = fbBrands.has(String(row.brand_id));
    const hasModel = fbModels.has(String(row.model_id));
    const trimEmpty = !String(row.trim_id || '').trim();
    const hasTrim = trimEmpty || fbTrims.has(String(row.trim_id));
    if (hasBrand && hasModel && hasTrim) bmtOk++;
    else bmtBad++;
  }
  console.log(`BMT rows fully resolvable in Firestore: ${bmtOk}/${bmt.length}`);
  console.log(`BMT rows broken: ${bmtBad}`);

  console.log('\n=== OTHER ARTIFACTS (not from Data/*.csv import) ===');
  for (const f of ['brands_models_trims.json', 'final_iqmotors_catalog.json']) {
    const p = path.join(ROOT, f);
    if (!fs.existsSync(p)) continue;
    const j = JSON.parse(fs.readFileSync(p, 'utf8'));
    const brandN = (j.brands || []).length;
    const modelN = (j.brands || []).reduce((a, b) => a + (b.models || []).length, 0);
    const trimN = (j.brands || []).reduce(
      (a, b) =>
        a + (b.models || []).reduce((x, m) => x + ((m.trims || []).length || 0), 0),
      0,
    );
    console.log(`${f}: brands=${brandN} models=${modelN} trimStrings=${trimN}`);
  }

  const allOk =
    missB.length === 0 &&
    missM.length === 0 &&
    missT.length === 0 &&
    brandDiffs === 0 &&
    modelDiffs === 0 &&
    trimDiffs === 0 &&
    metaMissing === 0 &&
    metaModelMismatch === 0 &&
    bmtBad === 0;

  console.log('\n=== VERDICT ===');
  console.log(
    allOk
      ? 'PASS: All Data/*.csv rows and fields are present in Firestore.'
      : 'ISSUES FOUND: see details above.',
  );
  process.exit(allOk ? 0 : 2);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
