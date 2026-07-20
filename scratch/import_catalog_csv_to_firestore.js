/**
 * Import Data/*.csv catalog into Firestore via the Firestore REST API.
 *
 * Writes:
 *   catalog_brands/{brand_id}
 *   catalog_models/{model_id}
 *   catalog_trims/{trim_id}
 *   car_metadata/{slug}  (derived Brand → Model → Trims mirror)
 *
 * Auth: uses the logged-in Firebase CLI access token
 * (same user as `firebase login`).
 *
 * Usage (from repo root):
 *   node scratch/import_catalog_csv_to_firestore.js
 *   node scratch/import_catalog_csv_to_firestore.js --dry-run
 *   node scratch/import_catalog_csv_to_firestore.js --spot-check
 */

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

const PROJECT_ID = 'iqmotors-d588d';
const ROOT = path.resolve(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'Data');
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const BATCH_LIMIT = 400;

const args = new Set(process.argv.slice(2));
const DRY_RUN = args.has('--dry-run');
const SPOT_CHECK_ONLY = args.has('--spot-check');

function loadFirebaseCliTokens() {
  const toolsPath = path.join(
    os.homedir(),
    '.config',
    'configstore',
    'firebase-tools.json',
  );
  if (!fs.existsSync(toolsPath)) {
    throw new Error(
      `Firebase CLI config not found at ${toolsPath}. Run: firebase login`,
    );
  }
  const cfg = JSON.parse(fs.readFileSync(toolsPath, 'utf8'));
  if (!cfg.tokens?.access_token) {
    throw new Error('No access_token in firebase-tools.json. Run: firebase login');
  }
  return cfg.tokens;
}

function httpsJson(method, url, body, accessToken) {
  return new Promise((resolve, reject) => {
    const payload =
      body === undefined ? null : Buffer.from(JSON.stringify(body), 'utf8');
    const u = new URL(url);
    const req = https.request(
      {
        hostname: u.hostname,
        path: u.pathname + u.search,
        method,
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json; charset=utf-8',
          ...(payload ? { 'Content-Length': payload.length } : {}),
        },
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          const data = Buffer.concat(chunks).toString('utf8');
          let parsed = null;
          try {
            parsed = data ? JSON.parse(data) : null;
          } catch {
            parsed = { raw: data };
          }
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ status: res.statusCode, body: parsed });
          } else {
            const err = new Error(
              `HTTP ${res.statusCode}: ${typeof parsed === 'object' ? JSON.stringify(parsed).slice(0, 500) : data.slice(0, 500)}`,
            );
            err.status = res.statusCode;
            err.body = parsed;
            reject(err);
          }
        });
      },
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

/** Convert a plain JS value to a Firestore REST Value. */
function toFirestoreValue(value) {
  if (value === null || value === undefined) {
    return { nullValue: null };
  }
  if (typeof value === 'boolean') {
    return { booleanValue: value };
  }
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (typeof value === 'string') {
    return { stringValue: value };
  }
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((v) => toFirestoreValue(v)),
      },
    };
  }
  if (typeof value === 'object') {
    if (value.__serverTimestamp) {
      return { timestampValue: new Date().toISOString() };
    }
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

function toFirestoreDocument(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] = toFirestoreValue(v);
  }
  return { fields };
}

function serverTimestamp() {
  return { __serverTimestamp: true };
}

/** Minimal RFC4180 CSV parser (handles quotes + Unicode). */
function parseCsv(text) {
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
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
      } else if (ch === '"') {
        inQuotes = false;
      } else {
        field += ch;
      }
      continue;
    }

    if (ch === '"') {
      inQuotes = true;
    } else if (ch === ',') {
      row.push(field);
      field = '';
    } else if (ch === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (ch === '\r') {
      // ignore
    } else {
      field += ch;
    }
  }

  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }

  if (rows.length === 0) return [];

  const headers = rows[0].map((h) => h.trim());
  const records = [];
  for (let r = 1; r < rows.length; r++) {
    const cols = rows[r];
    if (cols.length === 1 && cols[0].trim() === '') continue;
    const obj = {};
    for (let c = 0; c < headers.length; c++) {
      obj[headers[c]] = cols[c] !== undefined ? cols[c] : '';
    }
    records.push(obj);
  }
  return records;
}

function emptyToNull(value) {
  if (value === undefined || value === null) return null;
  const s = String(value).trim();
  return s === '' ? null : s;
}

function toIntOrNull(value) {
  const s = emptyToNull(value);
  if (s === null) return null;
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

function toBool(value) {
  const s = String(value ?? '')
    .trim()
    .toLowerCase();
  return s === 'true' || s === '1' || s === 'yes';
}

function slugifyBrandName(nameEn) {
  return String(nameEn)
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .replace(/_+/g, '_');
}

function readCsv(fileName) {
  const filePath = path.join(DATA_DIR, fileName);
  const text = fs.readFileSync(filePath, 'utf8');
  return parseCsv(text);
}

function mapBrand(row) {
  const brandId = toIntOrNull(row.brand_id);
  if (brandId === null) throw new Error(`Invalid brand_id: ${row.brand_id}`);
  const nameEn = emptyToNull(row.brand_name_en);
  return {
    id: String(brandId),
    data: {
      brandId,
      brand_id: brandId,
      brand_name_en: nameEn,
      brand_name_ar: emptyToNull(row.brand_name_ar),
      brand_name_ku: emptyToNull(row.brand_name_ku),
      category_id: toIntOrNull(row.category_id),
      sort: toIntOrNull(row.sort),
      description_en: emptyToNull(row.description_en),
      description_ar: emptyToNull(row.description_ar),
      description_ku: emptyToNull(row.description_ku),
      slug: slugifyBrandName(nameEn || `brand_${brandId}`),
      importedAt: serverTimestamp(),
      source: 'Data/brands.csv',
    },
  };
}

function mapModel(row) {
  const modelId = toIntOrNull(row.model_id);
  if (modelId === null) throw new Error(`Invalid model_id: ${row.model_id}`);
  return {
    id: String(modelId),
    data: {
      modelId,
      model_id: modelId,
      brand_id: toIntOrNull(row.brand_id),
      brand_name_en: emptyToNull(row.brand_name_en),
      model_name_en: emptyToNull(row.model_name_en),
      model_name_ar: emptyToNull(row.model_name_ar),
      model_name_ku: emptyToNull(row.model_name_ku),
      sort: toIntOrNull(row.sort),
      from_year_id: toIntOrNull(row.from_year_id),
      to_year_id: toIntOrNull(row.to_year_id),
      segment_id: toIntOrNull(row.segment_id),
      sub_segment_id: toIntOrNull(row.sub_segment_id),
      deleted: toBool(row.deleted),
      importedAt: serverTimestamp(),
      source: 'Data/models.csv',
    },
  };
}

function mapTrim(row) {
  const trimId = toIntOrNull(row.trim_id);
  if (trimId === null) throw new Error(`Invalid trim_id: ${row.trim_id}`);
  return {
    id: String(trimId),
    data: {
      trimId,
      trim_id: trimId,
      trim_name: emptyToNull(row.trim_name),
      model_id: toIntOrNull(row.model_id),
      model_name_en: emptyToNull(row.model_name_en),
      brand_id: toIntOrNull(row.brand_id),
      brand_name_en: emptyToNull(row.brand_name_en),
      from_year_id: toIntOrNull(row.from_year_id),
      to_year_id: toIntOrNull(row.to_year_id),
      deleted: toBool(row.deleted),
      importedAt: serverTimestamp(),
      source: 'Data/trims.csv',
    },
  };
}

function buildCarMetadataMirror(brands, models, trims) {
  const modelsByBrand = new Map();
  for (const m of models) {
    const bid = m.data.brand_id;
    if (!modelsByBrand.has(bid)) modelsByBrand.set(bid, []);
    modelsByBrand.get(bid).push(m.data);
  }
  const trimsByModel = new Map();
  for (const t of trims) {
    const mid = t.data.model_id;
    if (!trimsByModel.has(mid)) trimsByModel.set(mid, []);
    trimsByModel.get(mid).push(t.data);
  }

  const docs = [];
  const slugCounts = new Map();

  for (const brand of brands) {
    const b = brand.data;
    let slug = b.slug;
    const count = (slugCounts.get(slug) || 0) + 1;
    slugCounts.set(slug, count);
    if (count > 1) slug = `${slug}_${b.brand_id}`;

    const modelsMap = {};
    const brandModels = modelsByBrand.get(b.brand_id) || [];
    for (const m of brandModels) {
      if (m.deleted) continue;
      const modelName = m.model_name_en || `model_${m.model_id}`;
      const modelTrims = (trimsByModel.get(m.model_id) || [])
        .filter((t) => !t.deleted)
        .map((t) => t.trim_name)
        .filter(Boolean);
      modelsMap[modelName] = modelTrims;
    }

    docs.push({
      id: slug,
      data: {
        models: modelsMap,
        brandId: b.brand_id,
        brand_name_en: b.brand_name_en,
        brand_name_ar: b.brand_name_ar,
        brand_name_ku: b.brand_name_ku,
        source: 'derived_from_Data_csv',
        importedAt: serverTimestamp(),
      },
    });
  }

  return docs;
}

function verifyFkIntegrity(brands, models, trims) {
  const brandIds = new Set(brands.map((b) => b.data.brand_id));
  const modelIds = new Set(models.map((m) => m.data.model_id));

  const orphanModels = models.filter((m) => !brandIds.has(m.data.brand_id));
  const orphanTrimsByModel = trims.filter((t) => !modelIds.has(t.data.model_id));
  const orphanTrimsByBrand = trims.filter((t) => !brandIds.has(t.data.brand_id));

  return {
    orphanModels: orphanModels.length,
    orphanTrimsByModel: orphanTrimsByModel.length,
    orphanTrimsByBrand: orphanTrimsByBrand.length,
    orphanModelSamples: orphanModels.slice(0, 5).map((m) => m.id),
    orphanTrimSamples: orphanTrimsByModel.slice(0, 5).map((t) => t.id),
  };
}

async function commitBatches(writes, accessToken) {
  let committed = 0;
  for (let i = 0; i < writes.length; i += BATCH_LIMIT) {
    const chunk = writes.slice(i, i + BATCH_LIMIT);
    if (DRY_RUN) {
      committed += chunk.length;
      continue;
    }

    const writesPayload = chunk.map((w) => ({
      update: {
        name: `projects/${PROJECT_ID}/databases/(default)/documents/${w.collection}/${w.id}`,
        ...toFirestoreDocument(w.data),
      },
    }));

    await httpsJson(
      'POST',
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:batchWrite`,
      { writes: writesPayload },
      accessToken,
    );

    committed += chunk.length;
    process.stdout.write(
      `\r  Committed ${committed}/${writes.length} documents...`,
    );
  }
  if (!DRY_RUN && writes.length > 0) process.stdout.write('\n');
  return committed;
}

function fromFirestoreValue(v) {
  if (!v || typeof v !== 'object') return null;
  if ('nullValue' in v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('arrayValue' in v) {
    return (v.arrayValue.values || []).map(fromFirestoreValue);
  }
  if ('mapValue' in v) {
    const out = {};
    for (const [k, val] of Object.entries(v.mapValue.fields || {})) {
      out[k] = fromFirestoreValue(val);
    }
    return out;
  }
  return null;
}

function fromFirestoreDoc(doc) {
  const out = {};
  for (const [k, v] of Object.entries(doc.fields || {})) {
    out[k] = fromFirestoreValue(v);
  }
  return out;
}

async function runQuery(accessToken, structuredQuery) {
  const res = await httpsJson(
    'POST',
    `${FIRESTORE_BASE}:runQuery`,
    { structuredQuery },
    accessToken,
  );
  return (res.body || [])
    .filter((r) => r.document)
    .map((r) => ({
      name: r.document.name,
      data: fromFirestoreDoc(r.document),
    }));
}

async function getDocument(accessToken, collection, id) {
  try {
    const res = await httpsJson(
      'GET',
      `${FIRESTORE_BASE}/${collection}/${encodeURIComponent(id)}`,
      undefined,
      accessToken,
    );
    return fromFirestoreDoc(res.body);
  } catch (e) {
    if (e.status === 404) return null;
    throw e;
  }
}

async function listCollectionCount(accessToken, collection) {
  // Aggregation count via runAggregationQuery
  try {
    const res = await httpsJson(
      'POST',
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runAggregationQuery`,
      {
        structuredAggregationQuery: {
          structuredQuery: {
            from: [{ collectionId: collection }],
          },
          aggregations: [{ alias: 'count', count: {} }],
        },
      },
      accessToken,
    );
    const agg = (res.body || [])[0]?.result?.aggregateFields?.count;
    if (agg?.integerValue != null) return Number(agg.integerValue);
  } catch {
    // fallback below
  }

  // Fallback: page through documents
  let count = 0;
  let pageToken = null;
  do {
    const url =
      `${FIRESTORE_BASE}/${collection}?pageSize=300` +
      (pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : '') +
      `&mask.fieldPaths=__name__`;
    const res = await httpsJson('GET', url, undefined, accessToken);
    count += (res.body.documents || []).length;
    pageToken = res.body.nextPageToken || null;
  } while (pageToken);
  return count;
}

async function spotCheck(accessToken) {
  console.log('\n=== Spot-check ===');
  const brandNames = ['Toyota', 'Kia', 'Audi'];
  for (const name of brandNames) {
    const rows = await runQuery(accessToken, {
      from: [{ collectionId: 'catalog_brands' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'brand_name_en' },
          op: 'EQUAL',
          value: { stringValue: name },
        },
      },
      limit: 1,
    });
    if (!rows.length) {
      console.log(`  ${name}: NOT FOUND in catalog_brands`);
      continue;
    }
    const brand = rows[0].data;
    const models = await runQuery(accessToken, {
      from: [{ collectionId: 'catalog_models' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'brand_id' },
          op: 'EQUAL',
          value: { integerValue: String(brand.brand_id) },
        },
      },
    });
    const trims = await runQuery(accessToken, {
      from: [{ collectionId: 'catalog_trims' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'brand_id' },
          op: 'EQUAL',
          value: { integerValue: String(brand.brand_id) },
        },
      },
    });
    const meta = await getDocument(accessToken, 'car_metadata', brand.slug);
    const metaModels = meta ? Object.keys(meta.models || {}) : [];
    console.log(
      `  ${name} (id=${brand.brand_id}, slug=${brand.slug}): ` +
        `${models.length} models, ${trims.length} trims, ` +
        `car_metadata models=${metaModels.length}, ` +
        `ar=${brand.brand_name_ar}, ku=${brand.brand_name_ku}`,
    );
    if (metaModels.length > 0) {
      for (const m of metaModels.slice(0, 3)) {
        const list = meta.models[m] || [];
        console.log(
          `    - ${m}: [${list.slice(0, 5).join(', ')}${list.length > 5 ? ', ...' : ''}]`,
        );
      }
    }
  }
}

async function cleanupProbe(accessToken) {
  try {
    await httpsJson(
      'DELETE',
      `${FIRESTORE_BASE}/catalog_brands/_auth_probe`,
      undefined,
      accessToken,
    );
  } catch {
    // ignore
  }
}

async function main() {
  console.log(`Project: ${PROJECT_ID}`);
  console.log(`Dry run: ${DRY_RUN}`);
  console.log(`Data dir: ${DATA_DIR}`);

  const tokens = loadFirebaseCliTokens();
  const accessToken = tokens.access_token;

  if (SPOT_CHECK_ONLY) {
    await spotCheck(accessToken);
    return;
  }

  console.log('\nReading CSVs...');
  const brandRows = readCsv('brands.csv');
  const modelRows = readCsv('models.csv');
  const trimRows = readCsv('trims.csv');
  console.log(
    `  CSV rows: brands=${brandRows.length}, models=${modelRows.length}, trims=${trimRows.length}`,
  );

  const brands = brandRows.map(mapBrand);
  const models = modelRows.map(mapModel);
  const trims = trimRows.map(mapTrim);
  const metadataDocs = buildCarMetadataMirror(brands, models, trims);

  const fk = verifyFkIntegrity(brands, models, trims);
  console.log('\nFK verification (pre-write):');
  console.log(`  orphan models (bad brand_id): ${fk.orphanModels}`);
  console.log(`  orphan trims (bad model_id):  ${fk.orphanTrimsByModel}`);
  console.log(`  orphan trims (bad brand_id):  ${fk.orphanTrimsByBrand}`);
  if (fk.orphanModelSamples.length) {
    console.log(`  orphan model samples: ${fk.orphanModelSamples.join(', ')}`);
  }
  if (fk.orphanTrimSamples.length) {
    console.log(`  orphan trim samples: ${fk.orphanTrimSamples.join(', ')}`);
  }

  const writes = [
    ...brands.map((b) => ({
      collection: 'catalog_brands',
      id: b.id,
      data: b.data,
    })),
    ...models.map((m) => ({
      collection: 'catalog_models',
      id: m.id,
      data: m.data,
    })),
    ...trims.map((t) => ({
      collection: 'catalog_trims',
      id: t.id,
      data: t.data,
    })),
    ...metadataDocs.map((d) => ({
      collection: 'car_metadata',
      id: d.id,
      data: d.data,
    })),
  ];

  console.log(
    `\nWriting ${writes.length} docs ` +
      `(${brands.length} brands + ${models.length} models + ` +
      `${trims.length} trims + ${metadataDocs.length} car_metadata)...`,
  );

  const started = Date.now();
  await commitBatches(writes, accessToken);
  const elapsed = ((Date.now() - started) / 1000).toFixed(1);
  console.log(`Done in ${elapsed}s${DRY_RUN ? ' (dry-run, no writes)' : ''}`);

  if (!DRY_RUN) {
    await cleanupProbe(accessToken);

    console.log('\nPost-import counts:');
    const counts = {
      catalog_brands: await listCollectionCount(accessToken, 'catalog_brands'),
      catalog_models: await listCollectionCount(accessToken, 'catalog_models'),
      catalog_trims: await listCollectionCount(accessToken, 'catalog_trims'),
      car_metadata: await listCollectionCount(accessToken, 'car_metadata'),
    };
    console.log(
      `  catalog_brands: ${counts.catalog_brands} (expected ${brands.length})`,
    );
    console.log(
      `  catalog_models: ${counts.catalog_models} (expected ${models.length})`,
    );
    console.log(
      `  catalog_trims:  ${counts.catalog_trims} (expected ${trims.length})`,
    );
    console.log(
      `  car_metadata:   ${counts.car_metadata} (expected >= ${metadataDocs.length})`,
    );

    const ok =
      counts.catalog_brands === brands.length &&
      counts.catalog_models === models.length &&
      counts.catalog_trims === trims.length;
    console.log(ok ? '\nVerification: PASS' : '\nVerification: COUNT MISMATCH');

    await spotCheck(accessToken);
  } else {
    console.log('\nSample brand:', brands[0].data);
    console.log('Sample model:', models[0].data);
    console.log('Sample trim:', trims[0].data);
    console.log(
      'Sample car_metadata slug:',
      metadataDocs[0].id,
      'model count:',
      Object.keys(metadataDocs[0].data.models).length,
    );
  }
}

main().catch((err) => {
  console.error('\nImport failed:', err);
  process.exit(1);
});
