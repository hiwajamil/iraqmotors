import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/marketplace/data/services/car_bid_service.dart';

/// Apple-style bid entry — centered dialog with on-submit Firestore validation.
class BidInputDialog {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _errorColor = Color(0xFFFF3B30);

  /// Returns the accepted bid amount on success, or `null` if dismissed / rejected.
  static Future<int?> show(
    BuildContext context, {
    required String carId,
    Map<String, dynamic>? car,
  }) {
    return showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _BidForm(carId: carId, car: car),
        ),
      ),
    );
  }
}

class _BidForm extends ConsumerStatefulWidget {
  const _BidForm({required this.carId, this.car});

  final String carId;
  final Map<String, dynamic>? car;

  @override
  ConsumerState<_BidForm> createState() => _BidFormState();
}

class _BidFormState extends ConsumerState<_BidForm> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _fieldError;

  /// Seller asking price resolved from listing data (`priceValue` or `price`).
  late final int? _sellerPrice = _resolveSellerPrice(widget.car);

  static int? _resolveSellerPrice(Map<String, dynamic>? car) {
    if (car == null) return null;

    final priceValue = car['priceValue'];
    if (priceValue is num) {
      final amount = priceValue.toInt();
      if (amount > 0) return amount;
    } else if (priceValue != null) {
      final parsed = CarBidService.parseBidAmount(priceValue.toString());
      if (parsed != null && parsed > 0) return parsed;
    }

    final fromPrice = CarBidService.parseBidAmount(car['price']?.toString() ?? '');
    if (fromPrice != null && fromPrice > 0) return fromPrice;

    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onOfferChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onOfferChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onOfferChanged() {
    final error = _validateOffer(_controller.text);
    if (error != _fieldError) {
      setState(() => _fieldError = error);
    }
  }

  /// Returns a localized validation message, or `null` when the amount is OK /
  /// empty (empty is handled on submit separately).
  String? _validateOffer(String raw) {
    final offerAmount = CarBidService.parseBidAmount(raw);
    if (offerAmount == null || offerAmount <= 0) return null;

    final sellerPrice = _sellerPrice;
    if (sellerPrice != null && offerAmount >= sellerPrice) {
      return context.l10n.bidMustBeBelowSellerPrice;
    }
    return null;
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    final offerAmount = CarBidService.parseBidAmount(_controller.text);
    if (offerAmount == null || offerAmount <= 0) return false;
    final sellerPrice = _sellerPrice;
    if (sellerPrice != null && offerAmount >= sellerPrice) return false;
    return true;
  }

  void _showErrorSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: BidInputDialog._errorColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final newBid = CarBidService.parseBidAmount(_controller.text);
    if (newBid == null || newBid <= 0) {
      _showErrorSnackBar(context.l10n.enterBidAmount);
      return;
    }

    final sellerPrice = _sellerPrice;
    if (sellerPrice != null && newBid >= sellerPrice) {
      final message = context.l10n.bidMustBeBelowSellerPrice;
      setState(() => _fieldError = message);
      _showErrorSnackBar(message);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bidService = ref.read(carBidServiceProvider);
      // ignore: avoid_print
      print('Attempting to submit offer for carId: ${widget.carId}');
      await bidService.ensureCarListingForBid(
        carId: widget.carId,
        seedData: widget.car,
      );

      final userId = ref.read(authStateProvider).value?.uid;
      final profile = ref.read(userProfileProvider).value;
      await bidService.submitValidatedBid(
        carId: widget.carId,
        newBid: newBid,
        userId: userId,
        bidderName: profile?.displayName,
        bidderPhone: profile?.phone,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      final successMessage = context.l10n.bidSuccessMessage;
      Navigator.of(context).pop(newBid);
      if (messenger != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF34C759),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on CarBidSoldException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar(context.l10n.carSoldNoBids);
    } on CarBidException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasFieldError = _fieldError != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.placeYourBid,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: BidInputDialog._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.enterBidAmount,
            style: const TextStyle(
              fontSize: 14,
              color: BidInputDialog._textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_isSubmitting,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: BidInputDialog._textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.enterBidAmount,
              hintStyle: TextStyle(
                color: BidInputDialog._textSecondary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasFieldError
                      ? BidInputDialog._errorColor
                      : Colors.transparent,
                  width: hasFieldError ? 1.5 : 0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasFieldError
                      ? BidInputDialog._errorColor
                      : BidInputDialog._textPrimary.withValues(alpha: 0.2),
                  width: hasFieldError ? 1.5 : 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) {
              if (_canSubmit) _submit();
            },
          ),
          if (hasFieldError) ...[
            const SizedBox(height: 8),
            Text(
              _fieldError!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: BidInputDialog._errorColor,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: BidInputDialog._textPrimary,
                disabledBackgroundColor:
                    BidInputDialog._textPrimary.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.submitBid,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
