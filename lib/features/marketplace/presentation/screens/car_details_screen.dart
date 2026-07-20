import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/utils/car_image_urls.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/localized_dummy_data.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/user_interest_provider.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/auth/presentation/screens/auth_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/car_details/car_details_gallery.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/car_details/car_details_specs_grid.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/car_details/car_details_seller_bar.dart';

/// Refactored M3 Car details screen.
/// Layout orchestration using modular widgets for gallery, specs matrix, and contact CTA.
class CarDetailsScreen extends ConsumerStatefulWidget {
  const CarDetailsScreen({
    super.key,
    this.car,
  });

  final Map<String, dynamic>? car;

  @override
  ConsumerState<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends ConsumerState<CarDetailsScreen> {
  static const double _desktopBreakpoint = 992;

  bool _prototypeSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final car = widget.car;
      if (car != null) {
        ref.read(userInterestRevisionProvider.notifier).recordFromCar(car);
      }
    });
  }

  Map<String, dynamic> _data(AppLocalizations l10n) {
    final prototype = LocalizedDummyData.prototypeCar(l10n);
    if (widget.car == null) return prototype;
    return {...prototype, ...widget.car!};
  }

  List<String> _images(AppLocalizations l10n) {
    final data = _data(l10n);
    final fromListing = carImageUrlsFromAd(data);
    if (fromListing.isNotEmpty) return fromListing;

    final prototype = LocalizedDummyData.prototypeCar(l10n);
    if (data['images'] is List) {
      return List<String>.from(data['images'] as List);
    }
    return List<String>.from(prototype['images'] as List);
  }

  double _horizontalPadding(double width) {
    if (width >= _desktopBreakpoint) return width * 0.08;
    return 20;
  }

  bool _isSaved() {
    final carId = widget.car?['id']?.toString();
    if (carId == null || carId.isEmpty) return _prototypeSaved;
    return ref.watch(favoritesProvider).contains(carId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _data(l10n);
    final images = _images(l10n);
    final isSaved = _isSaved();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > _desktopBreakpoint;
        final hPad = _horizontalPadding(constraints.maxWidth);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottomNavigationBar: isWide
              ? null
              : MobileSellerBar(
                  data: data,
                  isSaved: isSaved,
                  onSaveToggle: _toggleSave,
                ),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailsAppBar(horizontalPadding: hPad),
                Expanded(
                  child: isWide
                      ? _WideLayout(
                          data: data,
                          images: images,
                          horizontalPadding: hPad,
                          isSaved: isSaved,
                          onSaveToggle: _toggleSave,
                        )
                      : _MobileScrollBody(
                          data: data,
                          images: images,
                          horizontalPadding: hPad,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleSave() async {
    final car = widget.car;
    if (car == null) {
      setState(() => _prototypeSaved = !_prototypeSaved);
      return;
    }

    try {
      await ref.read(favoritesProvider.notifier).toggle(car);
    } on FavoritesAuthRequired {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      );
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _DetailsAppBar extends StatelessWidget {
  const _DetailsAppBar({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        12,
        horizontalPadding,
        12,
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.carDetailsTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.data,
    required this.images,
    required this.horizontalPadding,
    required this.isSaved,
    required this.onSaveToggle,
  });

  final Map<String, dynamic> data;
  final List<String> images;
  final double horizontalPadding;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        0,
        horizontalPadding,
        32,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _CarDetailsContent(
                data: data,
                images: images,
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: SellerContactCard(
              data: data,
              isSaved: isSaved,
              onSaveToggle: onSaveToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileScrollBody extends StatelessWidget {
  const _MobileScrollBody({
    required this.data,
    required this.images,
    required this.horizontalPadding,
  });

  final Map<String, dynamic> data;
  final List<String> images;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        0,
        horizontalPadding,
        24,
      ),
      child: _CarDetailsContent(
        data: data,
        images: images,
      ),
    );
  }
}

class _CarDetailsContent extends StatelessWidget {
  const _CarDetailsContent({
    required this.data,
    required this.images,
  });

  final Map<String, dynamic> data;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final make = data['make'] as String? ?? '';
    final model = data['model'] as String? ?? '';
    final price = data['price'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final features =
        List<String>.from(data['features'] as List? ?? const <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImageGalleryCarousel(images: images),
        const SizedBox(height: 24),
        Text(
          make.toUpperCase(),
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          model,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          price,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        QuickSpecsGrid(data: data),
        const SizedBox(height: 24),
        if (description.isNotEmpty) ...[
          Text(
            context.l10n.description,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (features.isNotEmpty) FeaturesSection(features: features),
        const SizedBox(height: 16),
        FullSpecsCard(data: data),
      ],
    );
  }
}
