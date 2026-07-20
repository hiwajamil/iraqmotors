'use strict';
/**
 * Find Firestore catalog docs containing U+FFFD and re-import those rows from CSV.
 */
const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

const PROJECT_ID = 'iqmotors-d588d';
const ROOT = path.resolve(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'Data');
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const BATCH_LIMIT = 400;

function token() {
  return JSON.parse(
    fs.readFileSync(
      path.join(os.homedir(), '.config/configstore/firebase-tools.json'),
      'utf8',
    ),
  ).tokens.access_token;
}

function httpsJson(method, url, body, accessToken) {
  return new Promise((resolve, reject) => {
    const payload =
      body === undefined ? null : Buffer.from(JSON.stringify(body), 'utf8');
    const u = new URL(url);
    const headers = {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (payload) headers['Content-Length'] = payload.length;
    const req = https.request(
      { hostname: u.hostname, path: u.pathname + u.search, method, headers },
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
  // Strip UTF-8 BOM
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

function emptyToNull(v) {
  const s = String(v ?? '').trim();
  return s === '' ? null : s;
}
function toIntOrNull(v) {
  const s = emptyToNull(v);
  if (s === null) return null;
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}
function toBool(v) {
  return ['true', '1', 'yes'].includes(String(v ?? '').trim().toLowerCase());
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

function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === 'object') {
    if (value.__serverTimestamp) {
      return { timestampValue: new Date().toISOString() };
    }
    const fields = {};
    for (const [k, v] of Object.entries(value)) fields[k] = toFirestoreValue(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

function toDoc(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) fields[k] = toFirestoreValue(v);
  return { fields };
}

function fromValue(v) {
  if (!v || typeof v !== 'object') return undefined;
  if ('nullValue' in v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
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

function containsFffd(value) {
  if (typeof value === 'string') return value.includes('\uFFFD');
  if (Array.isArray(value)) return value.some(containsFffd);
  if (value && typeof value === 'object') {
    return Object.values(value).some(containsFffd);
  }
  return false;
}

async function listDocs(accessToken, collection) {
  const docs = [];
  let pageToken = null;
  do {
    let url = `${BASE}/${collection}?pageSize=300`;
    if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;
    const res = await httpsJson('GET', url, undefined, accessToken);
    for (const d of res.documents || []) {
      const id = d.name.split('/').pop();
      const data = {};
      for (const [k, v] of Object.entries(d.fields || {})) data[k] = fromValue(v);
      docs.push({ id, data });
    }
    pageToken = res.nextPageToken || null;
  } while (pageToken);
  return docs;
}

function mapBrand(row) {
  const brandId = toIntOrNull(row.brand_id);
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
      slug: slugify(nameEn || `brand_${brandId}`),
      importedAt: { __serverTimestamp: true },
      source: 'Data/brands.csv',
    },
  };
}

function mapModel(row) {
  const modelId = toIntOrNull(row.model_id);
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
      importedAt: { __serverTimestamp: true },
      source: 'Data/models.csv',
    },
  };
}

function mapTrim(row) {
  const trimId = toIntOrNull(row.trim_id);
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
      importedAt: { __serverTimestamp: true },
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
    for (const m of modelsByBrand.get(b.brand_id) || []) {
      if (m.deleted) continue;
      const modelName = m.model_name_en || `model_${m.model_id}`;
      modelsMap[modelName] = (trimsByModel.get(m.model_id) || [])
        .filter((t) => !t.deleted)
        .map((t) => t.trim_name)
        .filter(Boolean);
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
        importedAt: { __serverTimestamp: true },
      },
    });
  }
  return docs;
}

async function commitBatches(writes, accessToken) {
  for (let i = 0; i < writes.length; i += BATCH_LIMIT) {
    const chunk = writes.slice(i, i + BATCH_LIMIT);
    const writesPayload = chunk.map((w) => ({
      update: {
        name: `projects/${PROJECT_ID}/databases/(default)/documents/${w.collection}/${w.id}`,
        ...toDoc(w.data),
      },
    }));
    await httpsJson(
      'POST',
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:batchWrite`,
      { writes: writesPayload },
      accessToken,
    );
    process.stdout.write(`\r  Wrote ${Math.min(i + chunk.length, writes.length)}/${writes.length}`);
  }
  if (writes.length) process.stdout.write('\n');
}

async function main() {
  const accessToken = token();
  const brandRows = parseCsv(fs.readFileSync(path.join(DATA_DIR, 'brands.csv'), 'utf8'));
  const modelRows = parseCsv(fs.readFileSync(path.join(DATA_DIR, 'models.csv'), 'utf8'));
  const trimRows = parseCsv(fs.readFileSync(path.join(DATA_DIR, 'trims.csv'), 'utf8'));

  console.log('Scanning Firestore for U+FFFD corruption...');
  const [fbBrands, fbModels, fbTrims, fbMeta] = await Promise.all([
    listDocs(accessToken, 'catalog_brands'),
    listDocs(accessToken, 'catalog_models'),
    listDocs(accessToken, 'catalog_trims'),
    listDocs(accessToken, 'car_metadata'),
  ]);

  const badBrands = fbBrands.filter((d) => containsFffd(d.data)).map((d) => d.id);
  const badModels = fbModels.filter((d) => containsFffd(d.data)).map((d) => d.id);
  const badTrims = fbTrims.filter((d) => containsFffd(d.data)).map((d) => d.id);
  const badMeta = fbMeta.filter((d) => containsFffd(d.data)).map((d) => d.id);

  console.log(`corrupted brands: ${badBrands.length}`, badBrands.join(', '));
  console.log(`corrupted models: ${badModels.length}`, badModels.slice(0, 30).join(', '));
  console.log(`corrupted trims:  ${badTrims.length}`, badTrims.slice(0, 30).join(', '));
  console.log(`corrupted car_metadata: ${badMeta.length}`, badMeta.slice(0, 30).join(', '));

  // Full re-write of all catalog docs from CSV (ensures perfect Unicode).
  // Safer than patching only bad ones if corruption came from transport.
  console.log('\nRe-importing ALL brands/models/trims + car_metadata from CSV...');
  const brands = brandRows.map(mapBrand);
  const models = modelRows.map(mapModel);
  const trims = trimRows.map(mapTrim);
  const metadataDocs = buildCarMetadataMirror(brands, models, trims);

  // Verify no FFFD in source-mapped data
  const srcBad = [...brands, ...models, ...trims, ...metadataDocs].filter((d) =>
    containsFffd(d.data),
  );
  console.log(`source-mapped docs with FFFD (should be 0): ${srcBad.length}`);
  if (srcBad.length) {
    console.log(srcBad.slice(0, 5).map((d) => d.id));
    process.exit(1);
  }

  const writes = [
    ...brands.map((b) => ({ collection: 'catalog_brands', id: b.id, data: b.data })),
    ...models.map((m) => ({ collection: 'catalog_models', id: m.id, data: m.data })),
    ...trims.map((t) => ({ collection: 'catalog_trims', id: t.id, data: t.data })),
    ...metadataDocs.map((d) => ({
      collection: 'car_metadata',
      id: d.id,
      data: d.data,
    })),
  ];

  await commitBatches(writes, accessToken);

  console.log('\nRe-scan after rewrite...');
  const [b2, m2, t2, meta2] = await Promise.all([
    listDocs(accessToken, 'catalog_brands'),
    listDocs(accessToken, 'catalog_models'),
    listDocs(accessToken, 'catalog_trims'),
    listDocs(accessToken, 'car_metadata'),
  ]);
  const stillBad = {
    brands: b2.filter((d) => containsFffd(d.data)).map((d) => d.id),
    models: m2.filter((d) => containsFffd(d.data)).map((d) => d.id),
    trims: t2.filter((d) => containsFffd(d.data)).map((d) => d.id),
    meta: meta2.filter((d) => containsFffd(d.data)).map((d) => d.id),
  };
  console.log('still corrupted:', JSON.stringify(stillBad));
  console.log(
    stillBad.brands.length +
      stillBad.models.length +
      stillBad.trims.length +
      stillBad.meta.length ===
      0
      ? 'PASS: Unicode clean'
      : 'FAIL: corruption remains',
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
