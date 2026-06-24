import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportTicketStatus { open, resolved }

extension SupportTicketStatusX on SupportTicketStatus {
  String get firestoreValue => switch (this) {
        SupportTicketStatus.open => 'open',
        SupportTicketStatus.resolved => 'resolved',
      };

  static SupportTicketStatus fromFirestore(String? value) {
    return switch (value) {
      'resolved' => SupportTicketStatus.resolved,
      _ => SupportTicketStatus.open,
    };
  }
}

/// A user support request stored in Firestore `support_tickets`.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.status,
    required this.lastMessage,
    this.subject,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String userDisplayName;
  final String? subject;
  final SupportTicketStatus status;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == SupportTicketStatus.open;

  factory SupportTicket.fromFirestore(String id, Map<String, dynamic> data) {
    return SupportTicket(
      id: id,
      userId: data['userId']?.toString() ?? '',
      userDisplayName: data['userDisplayName']?.toString() ?? '',
      subject: data['subject']?.toString(),
      status: SupportTicketStatusX.fromFirestore(data['status']?.toString()),
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageAt: _dateFromField(data['lastMessageAt']),
      createdAt: _dateFromField(data['createdAt']),
      updatedAt: _dateFromField(data['updatedAt']),
    );
  }

  static DateTime? _dateFromField(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// A single message in a ticket thread (`support_tickets/{id}/messages`).
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.isAdmin,
    this.timestamp,
  });

  final String id;
  final String senderId;
  final String text;
  final bool isAdmin;
  final DateTime? timestamp;

  factory SupportMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    }

    return SupportMessage(
      id: id,
      senderId: data['senderId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      isAdmin: data['isAdmin'] == true,
      timestamp: timestamp,
    );
  }
}
