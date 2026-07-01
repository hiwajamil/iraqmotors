import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/utils/relative_time.dart';
import 'package:iq_motors/features/dashboard/domain/models/user_message.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

/// Live bid-notification inbox for car owners.
class UserInboxSection extends ConsumerWidget {
  const UserInboxSection({
    super.key,
    this.nestedInScrollView = true,
  });

  /// When `true`, sizes the list to its children for embedding in a parent
  /// [SingleChildScrollView]. When `false`, the list fills the available height.
  final bool nestedInScrollView;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _unreadBg = Color(0xFFF0F4FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return _EmptyPlaceholder(message: l10n.messagesEmpty);
    }

    final messageService = ref.watch(userMessageServiceProvider);

    return StreamBuilder<List<UserMessage>>(
      stream: messageService.watchInbox(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _EmptyPlaceholder(
            message: snapshot.error.toString(),
          );
        }

        final messages = snapshot.data ?? const [];
        if (messages.isEmpty) {
          return _EmptyPlaceholder(message: l10n.messagesEmpty);
        }

        return ListView.separated(
          shrinkWrap: nestedInScrollView,
          primary: false,
          physics: nestedInScrollView
              ? const NeverScrollableScrollPhysics()
              : null,
          itemCount: messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final message = messages[index];
            return _MessageTile(
              message: message,
              onTap: () => _openMessage(context, ref, message),
            );
          },
        );
      },
    );
  }

  Future<void> _openMessage(
    BuildContext context,
    WidgetRef ref,
    UserMessage message,
  ) async {
    if (!message.isRead) {
      try {
        await ref.read(userMessageServiceProvider).markAsRead(message.id);
      } catch (_) {
        // Opening the message should still work even if the write fails.
      }
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            message.carName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message.messageBody,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: _textPrimary,
                ),
              ),
              if (message.senderPhone.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  message.senderPhone,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancelAction),
            ),
          ],
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.onTap,
  });

  final UserMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isUnread = !message.isRead;
    final timeLabel = message.timestamp != null
        ? formatRelativeTime(message.timestamp!, l10n)
        : '';

    return Material(
      color: isUnread ? UserInboxSection._unreadBg : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFF007AFF).withValues(alpha: 0.2)
                  : const Color(0xFFE5E5EA),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnread
                      ? const Color(0xFF007AFF).withValues(alpha: 0.12)
                      : const Color(0xFFF5F5F7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.gavel_rounded,
                  size: 20,
                  color: isUnread
                      ? const Color(0xFF007AFF)
                      : UserInboxSection._textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.carName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: UserInboxSection._textPrimary,
                            ),
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: UserInboxSection._textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.messageBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight:
                            isUnread ? FontWeight.w500 : FontWeight.w400,
                        color: UserInboxSection._textSecondary,
                      ),
                    ),
                    if (message.senderName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: UserInboxSection._textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF86868B),
          ),
        ),
      ),
    );
  }
}
