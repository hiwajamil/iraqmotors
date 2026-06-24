import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:iq_motors/features/admin/domain/models/support_ticket.dart';

class SupportTicketException implements Exception {
  SupportTicketException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firestore access for `support_tickets` and their `messages` sub-collection.
class SupportTicketService {
  SupportTicketService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'support_tickets';
  static const String messagesSubcollection = 'messages';

  /// Live ticket list — open tickets first, then most recently updated.
  Stream<List<SupportTicket>> watchTickets() {
    return _firestore
        .collection(collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map((doc) => SupportTicket.fromFirestore(doc.id, doc.data()))
          .toList();
      tickets.sort(_compareTickets);
      return tickets;
    });
  }

  /// Live message thread for [ticketId], oldest first.
  Stream<List<SupportMessage>> watchMessages(String ticketId) {
    return _firestore
        .collection(collection)
        .doc(ticketId)
        .collection(messagesSubcollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportMessage.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Appends a message and updates the parent ticket preview fields.
  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw SupportTicketException('Message cannot be empty.');
    }

    try {
      final ticketRef = _firestore.collection(collection).doc(ticketId);
      final ticketDoc = await ticketRef.get();
      if (!ticketDoc.exists) {
        throw SupportTicketException('Support ticket not found.');
      }

      final userId = ticketDoc.data()?['userId']?.toString() ?? '';
      final isAdmin = senderId != userId;

      await ticketRef.collection(messagesSubcollection).add({
        'senderId': senderId,
        'text': trimmed,
        'isAdmin': isAdmin,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await ticketRef.update({
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on SupportTicketException {
      rethrow;
    } on FirebaseException catch (e) {
      throw SupportTicketException(
        e.message ?? 'Failed to send message.',
      );
    } catch (e) {
      throw SupportTicketException('Failed to send message: $e');
    }
  }

  /// Marks a ticket as open or resolved.
  Future<void> updateTicketStatus({
    required String ticketId,
    required SupportTicketStatus status,
  }) async {
    try {
      await _firestore.collection(collection).doc(ticketId).update({
        'status': status.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw SupportTicketException(
        e.message ?? 'Failed to update ticket status.',
      );
    } catch (e) {
      throw SupportTicketException('Failed to update ticket status: $e');
    }
  }

  /// Creates a new ticket with an initial user message.
  Future<String> createTicket({
    required String userId,
    required String userDisplayName,
    required String initialMessage,
    String? subject,
  }) async {
    final trimmed = initialMessage.trim();
    if (trimmed.isEmpty) {
      throw SupportTicketException('Initial message cannot be empty.');
    }

    try {
      final ticketRef = _firestore.collection(collection).doc();
      await ticketRef.set({
        'userId': userId,
        'userDisplayName': userDisplayName,
        if (subject != null && subject.trim().isNotEmpty)
          'subject': subject.trim(),
        'status': SupportTicketStatus.open.firestoreValue,
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await ticketRef.collection(messagesSubcollection).add({
        'senderId': userId,
        'text': trimmed,
        'isAdmin': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return ticketRef.id;
    } on FirebaseException catch (e) {
      throw SupportTicketException(
        e.message ?? 'Failed to create support ticket.',
      );
    } catch (e) {
      throw SupportTicketException('Failed to create support ticket: $e');
    }
  }

  static int _compareTickets(SupportTicket a, SupportTicket b) {
    if (a.isOpen != b.isOpen) {
      return a.isOpen ? -1 : 1;
    }

    final aTime = a.lastMessageAt ?? a.updatedAt ?? a.createdAt ?? DateTime(1970);
    final bTime = b.lastMessageAt ?? b.updatedAt ?? b.createdAt ?? DateTime(1970);
    return bTime.compareTo(aTime);
  }
}
