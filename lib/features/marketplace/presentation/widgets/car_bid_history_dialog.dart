import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:iq_motors/core/utils/bid_display.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/features/marketplace/domain/models/car_bid_record.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

/// Centered dialog listing every offer placed on a car listing.
class CarBidHistoryDialog extends ConsumerStatefulWidget {
  const CarBidHistoryDialog({
    super.key,
    required this.carId,
    required this.carTitle,
    this.currencyKey,
  });

  final String carId;
  final String carTitle;
  final String? currencyKey;

  static Future<void> show(
    BuildContext context, {
    required String carId,
    required String carTitle,
    String? currencyKey,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: context.colorScheme.scrim.withValues(alpha: 0.35),
      builder: (_) => CarBidHistoryDialog(
        carId: carId,
        carTitle: carTitle,
        currencyKey: currencyKey,
      ),
    );
  }

  @override
  ConsumerState<CarBidHistoryDialog> createState() =>
      _CarBidHistoryDialogState();
}

class _CarBidHistoryDialogState extends ConsumerState<CarBidHistoryDialog> {
  Future<List<CarBidRecord>>? _bidsFuture;

  Future<List<CarBidRecord>> _loadBids(WidgetRef ref) {
    return _bidsFuture ??=
        ref.read(carBidServiceProvider).fetchBidHistory(widget.carId);
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '—';
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  String _formatAmount(int amount) {
    return BidDisplay.formatAmount(
      amount,
      currencyKey:
          widget.currencyKey ?? AddCarFormOptions.defaultCurrencyKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      elevation: 24,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.gavel_rounded,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.bidHistoryTitle,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.carTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: FutureBuilder<List<CarBidRecord>>(
                future: _loadBids(ref),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: colorScheme.error,
                        ),
                      ),
                    );
                  }

                  final bids = snapshot.data ?? const <CarBidRecord>[];
                  if (bids.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 32,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.bidHistoryEmpty,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    shrinkWrap: true,
                    itemCount: bids.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bid = bids[index];
                      return _BidHistoryTile(
                        rank: index + 1,
                        isTopBid: index == 0,
                        bid: bid,
                        amountLabel: _formatAmount(bid.amount),
                        timestampLabel: _formatTimestamp(bid.createdAt),
                        nameLabel: l10n.bidHistoryBidderName,
                        phoneLabel: l10n.bidHistoryBidderPhone,
                        dateFieldLabel: l10n.bidHistoryDate,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BidHistoryTile extends StatelessWidget {
  const _BidHistoryTile({
    required this.rank,
    required this.isTopBid,
    required this.bid,
    required this.amountLabel,
    required this.timestampLabel,
    required this.nameLabel,
    required this.phoneLabel,
    required this.dateFieldLabel,
  });

  final int rank;
  final bool isTopBid;
  final CarBidRecord bid;
  final String amountLabel;
  final String timestampLabel;
  final String nameLabel;
  final String phoneLabel;
  final String dateFieldLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopBid
            ? colorScheme.onSurface.withValues(alpha: 0.04)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopBid
              ? colorScheme.onSurface.withValues(alpha: 0.12)
              : colorScheme.shadow.withValues(alpha: 0.04),
        ),
        boxShadow: isTopBid
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTopBid
                      ? colorScheme.inverseSurface
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTopBid
                        ? Colors.transparent
                        : colorScheme.shadow.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  '$rank',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isTopBid
                        ? colorScheme.onInverseSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameLabel,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bid.bidderName.isNotEmpty ? bid.bidderName : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  amountLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onInverseSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineField(
                  label: phoneLabel,
                  value: bid.bidderPhone.isNotEmpty ? bid.bidderPhone : '—',
                  monospace: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InlineField(
                  label: dateFieldLabel,
                  value: timestampLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
            fontFeatures:
                monospace ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ],
    );
  }
}
