import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/core/utils/relative_time.dart';
import 'package:iq_motors/features/dashboard/domain/models/user_message.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';

/// Live bid-notification inbox for car owners.
class UserInboxSection extends ConsumerWidget {
  const UserInboxSection({
    super.key,
    this.nestedInScrollView = true,
  });

  /// When `true`, sizes the list to its children for embedding in a parent
  /// [SingleChildScrollView]. When `false`, the list fills the available height.
  final bool nestedInScrollView;

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
          return const AppLoadingCenter(
            padding: EdgeInsets.symmetric(vertical: 80),
            size: AppLoadingSize.large,
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
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
        final colorScheme = dialogContext.colorScheme;
        final textTheme = dialogContext.textTheme;
        return AlertDialog(
          title: Text(
            message.carName,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message.messageBody,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              if (message.senderPhone.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  message.senderPhone,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isUnread = !message.isRead;
    final timeLabel = message.timestamp != null
        ? formatRelativeTime(message.timestamp!, l10n)
        : '';

    return Material(
      color: isUnread
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : colorScheme.outlineVariant,
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
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.gavel_rounded,
                  size: 20,
                  color: isUnread
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
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
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.messageBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        fontWeight:
                            isUnread ? FontWeight.w500 : FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (message.senderName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        message.senderName,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: colorScheme.onSurface,
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
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
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
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
