const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { BetaAnalyticsDataClient } = require("@google-analytics/data");
const admin = require("firebase-admin");

admin.initializeApp();

const gaPropertyId = defineSecret("GA_PROPERTY_ID");
const gaServiceAccountJson = defineSecret("GA_SERVICE_ACCOUNT_JSON");

const SUPER_ADMIN_EMAILS = new Set([
  "hiwa.constructions@gmail.com",
  "9647500000000@iqmotors.app",
]);

/**
 * Callable: returns GA4 DAU, first opens, and city visitor traffic for super-admins.
 *
 * Request: { startDate: "YYYY-MM-DD", endDate: "YYYY-MM-DD" }
 */
exports.getAdminAnalytics = onCall(
  {
    region: "us-central1",
    secrets: [gaPropertyId, gaServiceAccountJson],
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const email = request.auth.token.email?.toLowerCase();
    if (!email || !SUPER_ADMIN_EMAILS.has(email)) {
      throw new HttpsError("permission-denied", "Super admin access required.");
    }

    const { startDate, endDate } = request.data ?? {};
    if (!isValidGaDate(startDate) || !isValidGaDate(endDate)) {
      throw new HttpsError(
        "invalid-argument",
        "startDate and endDate must be YYYY-MM-DD.",
      );
    }

    let credentials;
    try {
      credentials = JSON.parse(gaServiceAccountJson.value());
    } catch {
      throw new HttpsError(
        "failed-precondition",
        "GA_SERVICE_ACCOUNT_JSON secret is not valid JSON.",
      );
    }

    const propertyId = gaPropertyId.value().trim();
    if (!propertyId) {
      throw new HttpsError(
        "failed-precondition",
        "GA_PROPERTY_ID secret is not configured.",
      );
    }

    const client = new BetaAnalyticsDataClient({ credentials });
    const property = `properties/${propertyId}`;

    const [dauReport, downloadsReport, cityReport] = await Promise.all([
      client.runReport({
        property,
        dateRanges: [{ startDate, endDate }],
        dimensions: [{ name: "date" }],
        metrics: [{ name: "activeUsers" }],
        orderBys: [{ dimension: { dimensionName: "date" } }],
      }),
      client.runReport({
        property,
        dateRanges: [{ startDate, endDate }],
        metrics: [{ name: "eventCount" }],
        dimensionFilter: {
          filter: {
            fieldName: "eventName",
            stringFilter: { matchType: "EXACT", value: "first_open" },
          },
        },
      }),
      client.runReport({
        property,
        dateRanges: [{ startDate, endDate }],
        dimensions: [{ name: "city" }],
        metrics: [{ name: "activeUsers" }],
        orderBys: [{ metric: { metricName: "activeUsers" }, desc: true }],
        limit: 100,
      }),
    ]);

    const dailyActiveUsers = parseDauRows(dauReport[0]);
    const todaysActiveUsers = await fetchTodaysActiveUsers(
      client,
      property,
      endDate,
      dailyActiveUsers,
    );
    const totalAppDownloads = parseMetricTotal(downloadsReport[0]);
    const cityVisitors = parseCityRows(cityReport[0]);

    return {
      dailyActiveUsers,
      todaysActiveUsers,
      totalAppDownloads,
      cityVisitors,
    };
  },
);

function isValidGaDate(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function parseDauRows(report) {
  const rows = report?.rows ?? [];
  return rows.map((row) => ({
    date: row.dimensionValues?.[0]?.value ?? "",
    count: parseInt(row.metricValues?.[0]?.value ?? "0", 10) || 0,
  }));
}

function parseMetricTotal(report) {
  const value = report?.rows?.[0]?.metricValues?.[0]?.value;
  return parseInt(value ?? "0", 10) || 0;
}

function parseCityRows(report) {
  const rows = report?.rows ?? [];
  return rows
    .map((row) => ({
      city: row.dimensionValues?.[0]?.value ?? "",
      count: parseInt(row.metricValues?.[0]?.value ?? "0", 10) || 0,
    }))
    .filter((row) => row.city && row.city !== "(not set)");
}

async function fetchTodaysActiveUsers(
  client,
  property,
  endDate,
  dailyActiveUsers,
) {
  const today = formatTodayGaDate();
  if (endDate !== today) {
    const last = dailyActiveUsers[dailyActiveUsers.length - 1];
    return last?.count ?? 0;
  }

  const [report] = await client.runReport({
    property,
    dateRanges: [{ startDate: today, endDate: today }],
    metrics: [{ name: "activeUsers" }],
  });
  return parseMetricTotal(report);
}

function formatTodayGaDate() {
  const now = new Date();
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, "0");
  const d = String(now.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}
