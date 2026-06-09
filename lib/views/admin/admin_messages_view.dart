import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_extensions.dart';
import '../../core/relative_time.dart';
import '../../l10n/app_localizations.dart';
import '../../models/support_ticket.dart';
import '../../providers/auth_providers.dart';
import '../../providers/storage_providers.dart';
import '../add_car/add_car_theme.dart';

enum _TicketFilter { all, open, resolved }

/// Split-pane support inbox for super admins.
class AdminMessagesView extends ConsumerStatefulWidget {
  const AdminMessagesView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminMessagesView> createState() => _AdminMessagesViewState();
}

class _AdminMessagesViewState extends ConsumerState<AdminMessagesView> {
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _adminBubble = Color(0xFF007AFF);
  static const Color _userBubble = Color(0xFFE5E5EA);
  static const Color _divider = Color(0xFFE5E5EA);

  String? _selectedTicketId;
  _TicketFilter _filter = _TicketFilter.all;
  final _messageController = TextEditingController();
  final _threadScrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _threadScrollController.dispose();
    super.dispose();
  }

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets) {
    return switch (_filter) {
      _TicketFilter.all => tickets,
      _TicketFilter.open => tickets.where((t) => t.isOpen).toList(),
      _TicketFilter.resolved =>
        tickets.where((t) => !t.isOpen).toList(),
    };
  }

  void _scrollThreadToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_threadScrollController.hasClients) return;
      _threadScrollController.animateTo(
        _threadScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(SupportTicket ticket) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final senderId = ref.read(authStateProvider).value?.uid;
    if (senderId == null) return;

    setState(() => _isSending = true);
    try {
      await ref.read(supportTicketServiceProvider).sendMessage(
            ticketId: ticket.id,
            senderId: senderId,
            text: text,
          );
      _messageController.clear();
      _scrollThreadToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleTicketStatus(SupportTicket ticket) async {
    final next = ticket.isOpen
        ? SupportTicketStatus.resolved
        : SupportTicketStatus.open;
    try {
      await ref.read(supportTicketServiceProvider).updateTicketStatus(
            ticketId: ticket.id,
            status: next,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.adminMessagesTitle,
          style: TextStyle(
            fontSize: widget.isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminMessagesSubtitle,
          style: const TextStyle(fontSize: 14, color: _textSecondary),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<SupportTicket>>(
            stream: ref.read(supportTicketServiceProvider).watchTickets(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorState(message: snapshot.error.toString());
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final allTickets = snapshot.data ?? const [];
              final tickets = _filterTickets(allTickets);

              SupportTicket? selectedTicket;
              if (_selectedTicketId != null) {
                for (final ticket in allTickets) {
                  if (ticket.id == _selectedTicketId) {
                    selectedTicket = ticket;
                    break;
                  }
                }
              }

              if (widget.isMobile) {
                if (selectedTicket != null) {
                  return _buildMobileThread(selectedTicket, l10n);
                }
                return _buildTicketList(
                  tickets,
                  l10n,
                  selectedId: null,
                );
              }

              return _buildSplitLayout(tickets, selectedTicket, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSplitLayout(
    List<SupportTicket> tickets,
    SupportTicket? selected,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AddCarTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 340,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: _divider),
                ),
              ),
              child: _buildTicketList(tickets, l10n, selectedId: selected?.id),
            ),
          ),
          Expanded(
            child: selected == null
                ? _EmptyThreadPlaceholder(message: l10n.adminMessagesSelectTicket)
                : _buildThread(selected, l10n, showBack: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileThread(SupportTicket ticket, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedTicketId = null),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(l10n.adminMessagesBackToList),
            style: TextButton.styleFrom(foregroundColor: AddCarTheme.focusBlue),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AddCarTheme.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildThread(ticket, l10n, showBack: false),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList(
    List<SupportTicket> tickets,
    AppLocalizations l10n, {
    required String? selectedId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _FilterChips(
            filter: _filter,
            labels: {
              _TicketFilter.all: l10n.adminMessagesFilterAll,
              _TicketFilter.open: l10n.adminMessagesFilterOpen,
              _TicketFilter.resolved: l10n.adminMessagesFilterResolved,
            },
            onChanged: (value) => setState(() => _filter = value),
          ),
        ),
        Expanded(
          child: tickets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.messagesEmpty,
                      style: const TextStyle(color: _textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return _TicketListItem(
                      ticket: ticket,
                      isSelected: ticket.id == selectedId,
                      openLabel: l10n.adminMessagesStatusOpen,
                      resolvedLabel: l10n.adminMessagesStatusResolved,
                      timeLabel: ticket.lastMessageAt != null
                          ? formatRelativeTime(ticket.lastMessageAt!, l10n)
                          : null,
                      onTap: () => setState(() => _selectedTicketId = ticket.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildThread(
    SupportTicket ticket,
    AppLocalizations l10n, {
    required bool showBack,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.userDisplayName.isNotEmpty
                          ? ticket.userDisplayName
                          : ticket.userId,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (ticket.subject != null && ticket.subject!.isNotEmpty)
                      Text(
                        ticket.subject!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _toggleTicketStatus(ticket),
                child: Text(
                  ticket.isOpen
                      ? l10n.adminMessagesResolve
                      : l10n.adminMessagesReopen,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: _bg,
            child: StreamBuilder<List<SupportMessage>>(
              stream: ref
                  .read(supportTicketServiceProvider)
                  .watchMessages(ticket.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final messages = snapshot.data ?? const [];
                _scrollThreadToBottom();

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.messagesEmpty,
                      style: const TextStyle(color: _textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _threadScrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      text: message.text,
                      isAdmin: message.isAdmin,
                      timeLabel: message.timestamp != null
                          ? formatRelativeTime(message.timestamp!, l10n)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ),
        _MessageComposer(
          controller: _messageController,
          hintText: l10n.adminMessagesReplyHint,
          sendLabel: l10n.adminMessagesSend,
          isSending: _isSending,
          onSend: () => _sendMessage(ticket),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filter,
    required this.labels,
    required this.onChanged,
  });

  final _TicketFilter filter;
  final Map<_TicketFilter, String> labels;
  final ValueChanged<_TicketFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _TicketFilter.values.map((value) {
        final selected = filter == value;
        return FilterChip(
          label: Text(labels[value]!),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onChanged(value),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1D1D1F),
          ),
          selectedColor: AddCarTheme.focusBlue,
          backgroundColor: const Color(0xFFF2F2F7),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

class _TicketListItem extends StatelessWidget {
  const _TicketListItem({
    required this.ticket,
    required this.isSelected,
    required this.openLabel,
    required this.resolvedLabel,
    required this.onTap,
    this.timeLabel,
  });

  final SupportTicket ticket;
  final bool isSelected;
  final String openLabel;
  final String resolvedLabel;
  final String? timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOpen = ticket.isOpen;

    return Material(
      color: isSelected ? const Color(0xFFE8F2FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.userDisplayName.isNotEmpty
                                ? ticket.userDisplayName
                                : ticket.userId,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1D1F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.lastMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86868B),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                label: isOpen ? openLabel : resolvedLabel,
                isOpen: isOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isOpen});

  final String label;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final bg = isOpen ? const Color(0xFFE8F8ED) : const Color(0xFFF2F2F7);
    final fg = isOpen ? const Color(0xFF34C759) : const Color(0xFF86868B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.isAdmin,
    this.timeLabel,
  });

  final String text;
  final bool isAdmin;
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isAdmin ? _AdminMessagesViewState._adminBubble : _AdminMessagesViewState._userBubble;
    final textColor =
        isAdmin ? Colors.white : _AdminMessagesViewState._textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isAdmin
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          child: Column(
            crossAxisAlignment: isAdmin
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isAdmin ? 18 : 4),
                    bottomRight: Radius.circular(isAdmin ? 4 : 18),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ),
              if (timeLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  timeLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _AdminMessagesViewState._textSecondary,
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

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.hintText,
    required this.sendLabel,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hintText;
  final String sendLabel;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _AdminMessagesViewState._divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: AddCarTheme.textFieldDecoration(hintText: hintText),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: isSending ? null : onSend,
            style: FilledButton.styleFrom(
              backgroundColor: AddCarTheme.focusBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    sendLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThreadPlaceholder extends StatelessWidget {
  const _EmptyThreadPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: const Color(0xFF86868B).withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF86868B)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
