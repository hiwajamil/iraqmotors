import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app bid notification stored in the top-level Firestore `messages` collection.
class UserMessage {
  const UserMessage({
    required this.id,
    required this.recipientId,
    required this.senderName,
    required this.senderPhone,
    required this.carId,
    required this.carName,
    required this.bidAmount,
    required this.messageBody,
    required this.timestamp,
    required this.isRead,
  });

  final String id;
  final String recipientId;
  final String senderName;
  final String senderPhone;
  final String carId;
  final String carName;
  final int bidAmount;
  final String messageBody;
  final DateTime? timestamp;
  final bool isRead;

  factory UserMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    }

    final rawAmount = data['bidAmount'];
    final bidAmount = rawAmount is num
        ? rawAmount.toInt()
        : int.tryParse(rawAmount?.toString() ?? '') ?? 0;

    return UserMessage(
      id: id,
      recipientId: data['recipientId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      senderPhone: data['senderPhone']?.toString() ?? '',
      carId: data['carId']?.toString() ?? '',
      carName: data['carName']?.toString() ?? '',
      bidAmount: bidAmount,
      messageBody: data['messageBody']?.toString() ?? '',
      timestamp: timestamp,
      isRead: data['isRead'] == true,
    );
  }
}
