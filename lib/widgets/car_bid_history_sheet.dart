import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/bid_display.dart';
import '../core/l10n_extensions.dart';
import '../data/add_car_form_options.dart';
import '../models/car_bid_record.dart';
import '../providers/storage_providers.dart';

/// Modal bottom sheet listing every offer placed on a car listing.
class CarBidHistorySheet extends ConsumerStatefulWidget {
  const CarBidHistorySheet({
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CarBidHistorySheet(
        carId: carId,
        carTitle: carTitle,
        currencyKey: currencyKey,
      ),
    );
  }

  @override
  ConsumerState<CarBidHistorySheet> createState() => _CarBidHistorySheetState();
}

class _CarBidHistorySheetState extends ConsumerState<CarBidHistorySheet> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _surface = Color(0xFFF5F5F7);

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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            maxWidth: 560,
          ),
          child: Material(
            color: Colors.white,
            elevation: 24,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.gavel_rounded,
                          size: 20,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.bidHistoryTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.carTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: _textSecondary,
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
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        );
                      }

                      final bids = snapshot.data ?? const <CarBidRecord>[];
                      if (bids.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _surface,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 32,
                                  color: _textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.bidHistoryEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        shrinkWrap: true,
                        itemCount: bids.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final bid = bids[index];
                          return _BidHistoryTile(
                            bid: bid,
                            amountLabel: _formatAmount(bid.amount),
                            timestampLabel: _formatTimestamp(bid.createdAt),
                            nameLabel: l10n.bidHistoryBidderName,
                            phoneLabel: l10n.bidHistoryBidderPhone,
                            amountFieldLabel: l10n.bidHistoryAmount,
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
        ),
      ),
    );
  }
}

class _BidHistoryTile extends StatelessWidget {
  const _BidHistoryTile({
    required this.bid,
    required this.amountLabel,
    required this.timestampLabel,
    required this.nameLabel,
    required this.phoneLabel,
    required this.amountFieldLabel,
    required this.dateFieldLabel,
  });

  final CarBidRecord bid;
  final String amountLabel;
  final String timestampLabel;
  final String nameLabel;
  final String phoneLabel;
  final String amountFieldLabel;
  final String dateFieldLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldBlock(
                  label: nameLabel,
                  value: bid.bidderName.isNotEmpty ? bid.bidderName : '—',
                  emphasized: true,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  amountLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FieldBlock(
            label: phoneLabel,
            value: bid.bidderPhone.isNotEmpty ? bid.bidderPhone : '—',
            monospace: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FieldBlock(
                  label: amountFieldLabel,
                  value: amountLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FieldBlock(
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

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: emphasized ? 15 : 13,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF1D1D1F),
            fontFeatures:
                monospace ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ],
    );
  }
}
