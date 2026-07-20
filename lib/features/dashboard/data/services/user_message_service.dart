import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:iq_motors/core/utils/bid_display.dart';
import 'package:iq_motors/features/dashboard/domain/models/user_message.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';

class UserMessageException implements Exception {
  UserMessageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// In-app notifications stored in the top-level Firestore `messages` collection.
class UserMessageService {
  UserMessageService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'messages';
  static const String recipientIdField = 'recipientId';
  static const String senderNameField = 'senderName';
  static const String senderPhoneField = 'senderPhone';
  static const String carIdField = 'carId';
  static const String carNameField = 'carName';
  static const String bidAmountField = 'bidAmount';
  static const String messageBodyField = 'messageBody';
  static const String timestampField = 'timestamp';
  static const String isReadField = 'isRead';

  /// Notifies [recipientId] (car owner) that a new bid was placed on their listing.
  Future<void> sendBidNotification({
    required String recipientId,
    required String senderName,
    required String senderPhone,
    required String carId,
    required String carName,
    required int bidAmount,
    String? currencyKey,
  }) async {
    if (recipientId.isEmpty) {
      throw UserMessageException('Recipient is required.');
    }

    final resolvedCurrency =
        currencyKey ?? AddCarFormOptions.defaultCurrencyKey;
    final amountLabel = BidDisplay.formatAmount(
      bidAmount,
      currencyKey: resolvedCurrency,
    );
    final resolvedSenderName =
        senderName.trim().isNotEmpty ? senderName.trim() : 'بەکارهێنەر';
    final messageBody =
        'نرخێکی نوێ دانرا بۆ ئۆتۆمبێلی $carName بە بڕی $amountLabel لەلایەن $resolvedSenderName';

    try {
      await _firestore.collection(collection).add({
        recipientIdField: recipientId,
        senderNameField: resolvedSenderName,
        senderPhoneField: senderPhone.trim(),
        carIdField: carId,
        carNameField: carName,
        bidAmountField: bidAmount,
        messageBodyField: messageBody,
        timestampField: FieldValue.serverTimestamp(),
        isReadField: false,
      });
    } on FirebaseException catch (e) {
      throw UserMessageException(
        e.message ?? 'Failed to send bid notification.',
      );
    }
  }

  /// Live inbox for a user — newest first.
  Stream<List<UserMessage>> watchInbox(String userId) {
    return _firestore
        .collection(collection)
        .where(recipientIdField, isEqualTo: userId)
        .orderBy(timestampField, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserMessage.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Count of unread messages for sidebar / tab badges.
  Stream<int> watchUnreadCount(String userId) {
    if (userId.isEmpty) return Stream.value(0);

    return _firestore
        .collection(collection)
        .where(recipientIdField, isEqualTo: userId)
        .where(isReadField, isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Fast one-time server count for unread messages without streaming document bodies.
  Future<int> fetchUnreadCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where(recipientIdField, isEqualTo: userId)
          .where(isReadField, isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Marks a single message as read when the user opens it.
  Future<void> markAsRead(String messageId) async {
    if (messageId.isEmpty) return;

    try {
      await _firestore.collection(collection).doc(messageId).update({
        isReadField: true,
      });
    } on FirebaseException catch (e) {
      throw UserMessageException(
        e.message ?? 'Failed to mark message as read.',
      );
    }
  }
}
