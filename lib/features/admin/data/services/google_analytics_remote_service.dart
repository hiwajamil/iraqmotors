import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:iq_motors/features/admin/data/services/ga_city_mapper.dart';
import 'package:iq_motors/features/admin/domain/models/analytics_date_range.dart';

/// GA metrics returned by the `getAdminAnalytics` Cloud Function.
class GaAdminAnalyticsPayload {
  const GaAdminAnalyticsPayload({
    required this.dailyActiveUsers,
    required this.todaysActiveUsers,
    required this.totalAppDownloads,
    required this.cityVisitors,
  });

  final List<int> dailyActiveUsers;
  final int todaysActiveUsers;
  final int totalAppDownloads;
  final Map<String, int> cityVisitors;

  static const empty = GaAdminAnalyticsPayload(
    dailyActiveUsers: [],
    todaysActiveUsers: 0,
    totalAppDownloads: 0,
    cityVisitors: {},
  );
}

/// Fetches Google Analytics metrics via Firebase Callable Functions.
class GoogleAnalyticsRemoteService {
  GoogleAnalyticsRemoteService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<GaAdminAnalyticsPayload> fetch(AnalyticsDateRange range) async {
    final callable = _functions.httpsCallable(
      'getAdminAnalytics',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final response = await callable.call<Map<String, dynamic>>({
      'startDate': _formatGaDate(range.start),
      'endDate': _formatGaDate(range.end),
    });

    final data = Map<String, dynamic>.from(response.data);
    final dauByDate = <String, int>{};
    for (final row in (data['dailyActiveUsers'] as List<dynamic>? ?? [])) {
      final map = Map<String, dynamic>.from(row as Map);
      final date = map['date']?.toString();
      final count = _asInt(map['count']);
      if (date != null) dauByDate[date] = count;
    }

    final rawCityVisitors = <String, int>{};
    for (final row in (data['cityVisitors'] as List<dynamic>? ?? [])) {
      final map = Map<String, dynamic>.from(row as Map);
      final city = map['city']?.toString();
      final count = _asInt(map['count']);
      if (city != null && city.isNotEmpty) rawCityVisitors[city] = count;
    }

    return GaAdminAnalyticsPayload(
      dailyActiveUsers: _alignDauToRange(range, dauByDate),
      todaysActiveUsers: _asInt(data['todaysActiveUsers']),
      totalAppDownloads: _asInt(data['totalAppDownloads']),
      cityVisitors: rollupGaCityVisitors(rawCityVisitors),
    );
  }

  static String _formatGaDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static List<int> _alignDauToRange(
    AnalyticsDateRange range,
    Map<String, int> gaByDate,
  ) {
    return range.days.map((day) {
      final key =
          '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
      return gaByDate[key] ?? 0;
    }).toList();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Logs GA fetch failures without failing the whole analytics request.
Future<GaAdminAnalyticsPayload> fetchGaAnalyticsSafely(
  GoogleAnalyticsRemoteService service,
  AnalyticsDateRange range,
) async {
  try {
    return await service.fetch(range);
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('GA analytics unavailable: $error\n$stackTrace');
    }
    return GaAdminAnalyticsPayload.empty;
  }
}
