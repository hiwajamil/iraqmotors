import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging (FCM) subscriptions for car listing alerts.
///
/// Users are subscribed to topics based on their saved filter interests
/// (e.g. `cars_toyota`, `cars_toyota_camry`) so they receive a push
/// notification whenever a new matching listing goes live.
class CarNotificationService {
  CarNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Topic prefix used for all car listing notifications.
  static const _topicPrefix = 'cars';

  /// Requests notification permission and initialises FCM handlers.
  ///
  /// Call once from [main] after Firebase is initialised.
  Future<void> init() async {
    // Request permission (iOS / web — Android grants automatically).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint(
        'FCM permission: ${settings.authorizationStatus}',
      );
    }

    // Print the device token in debug builds (useful for testing).
    if (kDebugMode) {
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
    }

    // Handle notifications that open the app from terminated state.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessage(message);
      }
    });

    // Handle notifications when app is in foreground.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // ---------------------------------------------------------------------------
  // Topic subscriptions
  // ---------------------------------------------------------------------------

  /// Subscribes to new-listing alerts for a specific [brandId].
  ///
  /// Topic: `cars_toyota`
  Future<void> subscribeToBrand(String brandId) async {
    final topic = _topicFor(brandId: brandId);
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) debugPrint('FCM: subscribed to $topic');
  }

  /// Unsubscribes from new-listing alerts for a specific [brandId].
  Future<void> unsubscribeFromBrand(String brandId) async {
    final topic = _topicFor(brandId: brandId);
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) debugPrint('FCM: unsubscribed from $topic');
  }

  /// Subscribes to alerts for a specific brand+model combination.
  ///
  /// Topic: `cars_toyota_camry`
  Future<void> subscribeToModel({
    required String brandId,
    required String modelKey,
  }) async {
    final topic = _topicFor(brandId: brandId, modelKey: modelKey);
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) debugPrint('FCM: subscribed to $topic');
  }

  /// Unsubscribes from a specific brand+model topic.
  Future<void> unsubscribeFromModel({
    required String brandId,
    required String modelKey,
  }) async {
    final topic = _topicFor(brandId: brandId, modelKey: modelKey);
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) debugPrint('FCM: unsubscribed from $topic');
  }

  /// Unsubscribes from all car-listing topics (e.g. on sign-out).
  Future<void> unsubscribeAll(List<String> brandIds) async {
    for (final brandId in brandIds) {
      await _messaging.unsubscribeFromTopic(_topicFor(brandId: brandId));
    }
    if (kDebugMode) debugPrint('FCM: unsubscribed from all brand topics');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Sanitises a raw key into a valid FCM topic name.
  ///
  /// FCM topics allow only `[a-zA-Z0-9-_.~%]` characters.
  static String _topicFor({required String brandId, String? modelKey}) {
    final sanitised = brandId.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '_',
        );
    if (modelKey == null || modelKey.isEmpty) {
      return '${_topicPrefix}_$sanitised';
    }
    final sanitisedModel = modelKey.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '_',
        );
    return '${_topicPrefix}_${sanitised}_$sanitisedModel';
  }

  /// Optional callback invoked when a notification targeting a car ID is clicked.
  static void Function(String carId)? onCarNotificationOpened;

  void _handleMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('FCM message opened: ${message.notification?.title}');
    }
    final carId = message.data['carId']?.toString();
    if (carId != null && carId.isNotEmpty) {
      onCarNotificationOpened?.call(carId);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        'FCM foreground message: ${message.notification?.title}',
      );
    }
    // Foreground messages can be shown as in-app banners using
    // flutter_local_notifications if desired.
  }
}
