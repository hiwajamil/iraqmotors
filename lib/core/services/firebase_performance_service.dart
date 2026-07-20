import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for measuring operation latency and metrics using Firebase Performance Monitoring.
class FirebasePerformanceService {
  FirebasePerformanceService._();

  static final FirebasePerformanceService instance = FirebasePerformanceService._();

  final FirebasePerformance _perf = FirebasePerformance.instance;

  /// Enables or disables performance metrics collection based on app environment.
  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      await _perf.setPerformanceCollectionEnabled(enabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebasePerformance] Failed to set collection enabled: $e');
      }
    }
  }

  /// Traces an asynchronous operation, measuring execution time and recording optional attributes & metrics.
  Future<T> traceAsync<T>(
    String traceName,
    Future<T> Function() action, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    Trace? trace;
    try {
      trace = _perf.newTrace(traceName);
      await trace.start();

      if (attributes != null) {
        attributes.forEach((key, value) {
          try {
            trace?.putAttribute(key, value);
          } catch (_) {}
        });
      }

      if (metrics != null) {
        metrics.forEach((key, value) {
          try {
            trace?.setMetric(key, value);
          } catch (_) {}
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebasePerformance] Start trace "$traceName" error: $e');
      }
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();

      try {
        if (trace != null) {
          trace.setMetric('duration_ms', stopwatch.elapsedMilliseconds);
          await trace.stop();
        }
      } catch (_) {}

      if (kDebugMode) {
        debugPrint('[FirebasePerformance] Trace "$traceName" completed in ${stopwatch.elapsedMilliseconds}ms');
      }

      return result;
    } catch (error) {
      stopwatch.stop();
      try {
        if (trace != null) {
          trace.putAttribute('error', error.toString().substring(0, 100));
          trace.setMetric('failed', 1);
          await trace.stop();
        }
      } catch (_) {}
      rethrow;
    }
  }
}
