import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:iq_motors/core/utils/bid_display.dart';
import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/shared/data/iraq_locations.dart';
import 'package:iq_motors/features/auth/domain/models/user_profile.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/car_bid_history_dialog.dart';
import 'package:iq_motors/features/dashboard/presentation/widgets/user_car_list_item.dart';
import 'package:iq_motors/features/dashboard/presentation/widgets/user_inbox_section.dart';
import 'package:iq_motors/features/dashboard/presentation/widgets/wishlist_car_card.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/car_details_screen.dart';
import 'package:iq_motors/features/listings/presentation/add_car_flow_screen.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/home_screen.dart';

/// User dashboard — sidebar (RTL start) + wishlist grid + my ads list.
class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

enum _DashboardNav {
  dashboard,
  home,
  wishlist,
  myAds,
  messages,
  settings,
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  static const double _mobileBreakpoint = 900;

  static const List<_DashboardNav> _mobileNavOrder = [
    _DashboardNav.home,
    _DashboardNav.dashboard,
    _DashboardNav.myAds,
    _DashboardNav.wishlist,
    _DashboardNav.messages,
  ];

  _DashboardNav _activeNav = _DashboardNav.dashboard;
  late int _currentIndex;

  final _scrollController = ScrollController();
  final _wishlistSectionKey = GlobalKey();
  final _myAdsSectionKey = GlobalKey();

  String? _currentUserId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _wishlistCars = [];
  List<Map<String, dynamic>> _myAds = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _currentIndex = _mobileNavOrder.indexOf(_activeNav);
    _loadSectionData(_activeNav);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const Set<String> _displayOnlyKeys = {
    'title',
    'price',
    'imageUrl',
    'status',
  };

  Future<void> _loadSectionData(_DashboardNav nav) async {
    if (nav != _DashboardNav.wishlist && nav != _DashboardNav.myAds) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _wishlistCars = [];
          _myAds = [];
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final carDb = ref.read(carDatabaseServiceProvider);
      if (nav == _DashboardNav.wishlist) {
        final docs = await carDb.fetchFavoriteAds(userId);
        if (!mounted) return;
        setState(() {
          _wishlistCars = docs.map(_mapToWishlistItem).toList();
          _isLoading = false;
        });
      } else {
        final docs = await carDb.fetchUserAds(userId);
        if (!mounted) return;
        setState(() {
          _myAds = docs.map(_mapToMyAdItem).toList();
          _isLoading = false;
        });
      }
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  Map<String, dynamic> _mapToWishlistItem(Map<String, dynamic> doc) {
    return {
      ...doc,
      'title': _carTitle(doc),
      'price': _formatPrice(doc),
      'imageUrl': _firstImageUrl(doc),
    };
  }

  Map<String, dynamic> _mapToMyAdItem(Map<String, dynamic> doc) {
    final rawStatus =
        doc['status']?.toString() ?? CarDatabaseService.statusActive;
    return {
      ...doc,
      'title': _carTitle(doc),
      'price': _formatPrice(doc),
      'status': rawStatus,
      'imageUrl': _firstImageUrl(doc),
      'photoUrls': _photoUrls(doc),
    };
  }

  Map<String, dynamic> _carDataForEdit(Map<String, dynamic> ad) {
    return Map<String, dynamic>.from(ad)
      ..remove('id')
      ..removeWhere((key, _) => _displayOnlyKeys.contains(key));
  }

  String _carTitle(Map<String, dynamic> data) {
    final brand = data['brandId']?.toString();
    final model = data['modelKey']?.toString();
    final year = data['year']?.toString();
    final parts = [brand, model, year]
        .whereType<String>()
        .where((part) => part.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');

    final make = data['make']?.toString();
    final modelName = data['model']?.toString();
    final demoParts = [make, modelName]
        .whereType<String>()
        .where((part) => part.isNotEmpty);
    if (demoParts.isNotEmpty) return demoParts.join(' ');

    return data['title']?.toString() ?? context.l10n.carFallbackTitle;
  }

  String _formatPrice(Map<String, dynamic> data) {
    final raw = data['priceValue'];
    if (raw == null) {
      final displayPrice = data['price']?.toString();
      if (displayPrice != null && displayPrice.isNotEmpty) {
        return displayPrice;
      }
      return '—';
    }
    final amount = raw is num ? raw.toInt() : int.tryParse(raw.toString());
    if (amount == null) return '—';

    final currencyKey =
        data['currencyKey']?.toString() ?? AddCarFormOptions.defaultCurrencyKey;
    final symbol = AddCarFormOptions.currencySymbol(currencyKey);
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$symbol$formatted';
  }

  String _firstImageUrl(Map<String, dynamic> data) {
    final urls = _photoUrls(data);
    if (urls.isNotEmpty) return urls.first;
    return data['imageUrl']?.toString() ?? '';
  }

  List<String> _photoUrls(Map<String, dynamic> data) {
    final photos = data['photos'];
    if (photos is List && photos.isNotEmpty) {
      return photos
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .take(4)
          .toList();
    }
    final urls = data['imageUrls'];
    if (urls is List && urls.isNotEmpty) {
      return urls
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .take(4)
          .toList();
    }
    final single = data['imageUrl']?.toString();
    if (single != null && single.isNotEmpty) return [single];
    return const [];
  }

  DateTime? _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static const int _adLifetimeDays = 30;

  int? _daysRemaining(DateTime? createdAt) {
    if (createdAt == null) return null;
    final expiresAt = createdAt.add(const Duration(days: _adLifetimeDays));
    final remaining = expiresAt.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  String _formatPostedDate(DateTime? createdAt) {
    if (createdAt == null) return '—';
    return DateFormat.yMMMd().format(createdAt);
  }

  void _onEditAd(Map<String, dynamic> ad) {
    final adId = ad['id']?.toString();
    if (adId == null) return;

    final rawStatus =
        ad['status']?.toString() ?? CarDatabaseService.statusActive;
    final isDraft = rawStatus == CarDatabaseService.statusDraft;
    final initialStep = isDraft
        ? (ad['draftLastStep'] is int
            ? ad['draftLastStep'] as int
            : int.tryParse(ad['draftLastStep']?.toString() ?? '') ?? 0)
        : 0;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddCarFlowScreen(
          existingAdId: adId,
          existingCarData: _carDataForEdit(ad),
          initialStep: initialStep,
          isDraft: isDraft,
        ),
      ),
    ).then((_) {
      if (_activeNav == _DashboardNav.myAds) {
        _loadSectionData(_DashboardNav.myAds);
      }
    });
  }

  Future<void> _onDeleteAd(Map<String, dynamic> ad) async {
    final adId = ad['id']?.toString();
    if (adId == null) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = dialogContext.colorScheme;
        final textTheme = dialogContext.textTheme;
        return AlertDialog(
          title: Text(
            l10n.deleteAdTitle,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            l10n.deleteAdConfirm,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelAction),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(carDatabaseServiceProvider).deleteCarAd(adId: adId);
      if (!mounted) return;

      setState(() {
        _myAds.removeWhere((item) => item['id']?.toString() == adId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.adDeletedSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.tertiary,
        ),
      );
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _onMarkAsSold(Map<String, dynamic> ad) async {
    final adId = ad['id']?.toString();
    if (adId == null) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = dialogContext.colorScheme;
        final textTheme = dialogContext.textTheme;
        return AlertDialog(
          title: Text(
            l10n.markAsSoldTitle,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            l10n.markAsSoldConfirm,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelAction),
            ),
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: colorScheme.tertiary),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.soldAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(carDatabaseServiceProvider).updateAdStatus(
            adId: adId,
            newStatus: CarDatabaseService.statusSold,
          );
      if (!mounted) return;

      setState(() {
        final index = _myAds.indexWhere(
          (item) => item['id']?.toString() == adId,
        );
        if (index >= 0) {
          _myAds[index] = {
            ..._myAds[index],
            'status': CarDatabaseService.statusSold,
          };
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adMarkedSoldSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.tertiary,
        ),
      );
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  void _onNavTap(_DashboardNav nav) {
    if (nav == _DashboardNav.home) {
      _goHome();
      return;
    }
    setState(() {
      _activeNav = nav;
      final mobileIndex = _mobileNavOrder.indexOf(nav);
      if (mobileIndex >= 0) _currentIndex = mobileIndex;
    });
    _loadSectionData(nav);
  }

  void _onBottomNavTap(int index) {
    final nav = _mobileNavOrder[index];
    if (nav == _DashboardNav.home) {
      _goHome();
      return;
    }
    setState(() {
      _currentIndex = index;
      _activeNav = nav;
    });
    _loadSectionData(nav);
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _removeWishlistItem(String id) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await ref.read(carDatabaseServiceProvider).unfavoriteCarAd(
            adId: id,
            userId: userId,
          );
      if (!mounted) return;
      setState(() {
        _wishlistCars.removeWhere((c) => c['id']?.toString() == id);
      });
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  void _onViewOffers(Map<String, dynamic> ad) {
    final adId = ad['id']?.toString();
    if (adId == null) return;

    CarBidHistoryDialog.show(
      context,
      carId: adId,
      carTitle: ad['title']?.toString() ?? '',
      currencyKey: ad['currencyKey']?.toString(),
    );
  }

  Future<void> _onToggleActive(Map<String, dynamic> ad) async {
    final adId = ad['id']?.toString();
    if (adId == null) return;

    final rawStatus =
        ad['status']?.toString() ?? CarDatabaseService.statusActive;
    if (rawStatus != CarDatabaseService.statusActive &&
        rawStatus != CarDatabaseService.statusExpired) {
      return;
    }

    final newStatus = rawStatus == CarDatabaseService.statusActive
        ? CarDatabaseService.statusExpired
        : CarDatabaseService.statusActive;

    try {
      await ref.read(carDatabaseServiceProvider).updateAdStatus(
            adId: adId,
            newStatus: newStatus,
          );
      if (!mounted) return;

      setState(() {
        final index = _myAds.indexWhere(
          (item) => item['id']?.toString() == adId,
        );
        if (index >= 0) {
          _myAds[index] = {
            ..._myAds[index],
            'status': newStatus,
          };
        }
      });
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isMobile) {
              return Column(
                children: [
                  const _MobileTopBar(),
                  Expanded(child: _buildMobileTabBody()),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: _DashboardSidebar(
                    activeNav: _activeNav,
                    onNavTap: _onNavTap,
                    onLogout: _logout,
                  ),
                ),
                Expanded(child: _buildMainContent(isMobile: false)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
    );
  }

  Widget _buildMobileTabBody() {
    if (_activeNav == _DashboardNav.messages) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 24),
        child: _buildActiveSection(isMobile: true),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 24),
      child: _buildActiveSection(isMobile: true),
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      padding: EdgeInsetsDirectional.fromSTEB(
        constraintsPadding(context),
        40,
        constraintsPadding(context),
        40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardHeader(isMobile: isMobile),
          const SizedBox(height: 40),
          _buildActiveSection(isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final l10n = context.l10n;

    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onBottomNavTap,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHomeScreen,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.person),
          selectedIcon: const Icon(CupertinoIcons.person_fill),
          label: l10n.navDashboard,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.car),
          selectedIcon: const Icon(CupertinoIcons.car_fill),
          label: l10n.navMyAds,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.heart),
          selectedIcon: const Icon(CupertinoIcons.heart_fill),
          label: l10n.navMyFavorites,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.chat_bubble),
          selectedIcon: const Icon(CupertinoIcons.chat_bubble_fill),
          label: l10n.navMessages,
        ),
      ],
    );
  }

  Widget _buildActiveSection({required bool isMobile}) {
    if (_isLoading) {
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

    return switch (_activeNav) {
      _DashboardNav.dashboard => isMobile
          ? _DashboardOverview(isMobile: true, onLogout: _logout)
          : const SizedBox.shrink(),
      _DashboardNav.home => const SizedBox.shrink(),
      _DashboardNav.wishlist => _WishlistSection(
          sectionKey: _wishlistSectionKey,
          cars: _wishlistCars,
          onRemove: _removeWishlistItem,
        ),
      _DashboardNav.myAds => _MyAdsSection(
          sectionKey: _myAdsSectionKey,
          ads: _myAds,
          isMobile: isMobile,
          onEdit: _onEditAd,
          onDelete: _onDeleteAd,
          onMarkAsSold: _onMarkAsSold,
          onViewOffers: _onViewOffers,
          onToggleActive: _onToggleActive,
          formatPostedDate: _formatPostedDate,
          daysRemaining: _daysRemaining,
          parseCreatedAt: _parseCreatedAt,
        ),
      _DashboardNav.messages => UserInboxSection(
          nestedInScrollView: !isMobile,
        ),
      _DashboardNav.settings => const _UserSettingsSection(),
    };
  }

  double constraintsPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width * 0.05;
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
      child: const _UserProfileSummary(isCompact: true),
    );
  }
}

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar({
    required this.activeNav,
    required this.onNavTap,
    required this.onLogout,
  });

  final _DashboardNav activeNav;
  final ValueChanged<_DashboardNav> onNavTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: BorderDirectional(
          end: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 30, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _UserProfileSummary(isCompact: false),
          const SizedBox(height: 8),
          _NavMenu(
            activeNav: activeNav,
            onNavTap: onNavTap,
          ),
          const Spacer(),
          _LogoutButton(onTap: onLogout),
        ],
      ),
    );
  }
}

class _UserProfileSummary extends StatelessWidget {
  const _UserProfileSummary({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final avatar = Container(
      width: isCompact ? 60 : 80,
      height: isCompact ? 60 : 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: 30,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    final textBlock = Column(
      crossAxisAlignment:
          isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          l10n.dummyPublisherHiwa,
          style: (isCompact ? textTheme.titleSmall : textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.userAccountPersonal,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );

    if (isCompact) {
      return Row(
        children: [
          avatar,
          const SizedBox(width: 16),
          Expanded(child: textBlock),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          avatar,
          const SizedBox(height: 16),
          textBlock,
        ],
      ),
    );
  }
}

class _NavMenu extends ConsumerWidget {
  const _NavMenu({
    required this.activeNav,
    required this.onNavTap,
  });

  final _DashboardNav activeNav;
  final ValueChanged<_DashboardNav> onNavTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final userId = ref.watch(authStateProvider).value?.uid;
    final unreadCount = userId == null
        ? 0
        : ref.watch(userUnreadMessageCountProvider(userId)).value ?? 0;

    final items = <_NavItemData>[
      _NavItemData(
        nav: _DashboardNav.home,
        label: l10n.navHomeScreen,
        icon: Icons.home_outlined,
      ),
      _NavItemData(
        nav: _DashboardNav.wishlist,
        label: l10n.navMyFavorites,
        icon: Icons.favorite_border,
      ),
      _NavItemData(
        nav: _DashboardNav.myAds,
        label: l10n.navMyAds,
        icon: Icons.directions_car_outlined,
      ),
      _NavItemData(
        nav: _DashboardNav.messages,
        label: l10n.navMessages,
        icon: Icons.mail_outline,
        badgeCount: unreadCount > 0 ? unreadCount : null,
      ),
      _NavItemData(
        nav: _DashboardNav.settings,
        label: l10n.navSettings,
        icon: Icons.settings_outlined,
      ),
    ];

    return Column(
      children: [
        for (final item in items) ...[
          _NavLink(
            item: item,
            isActive: activeNav == item.nav,
            onTap: () => onNavTap(item.nav),
          ),
          if (item != items.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.nav,
    required this.label,
    required this.icon,
    this.badgeCount,
  });

  final _DashboardNav nav;
  final String label;
  final IconData icon;
  final int? badgeCount;
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final bg = widget.isActive
        ? colorScheme.primary
        : _hovered
            ? colorScheme.surfaceContainerHighest
            : Colors.transparent;
    final fg = widget.isActive
        ? colorScheme.onPrimary
        : _hovered
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, size: 18, color: fg),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              if (widget.item.badgeCount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.item.badgeCount}',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onError,
                    ),
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

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.error.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: colorScheme.error),
              const SizedBox(width: 16),
              Text(
                context.l10n.signOut,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({
    required this.isMobile,
    required this.onLogout,
  });

  final bool isMobile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardHeader(isMobile: isMobile),
        if (isMobile) ...[
          const SizedBox(height: 32),
          _LogoutButton(onTap: onLogout),
        ],
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final title = Text(
      l10n.userDashboardTitle,
      style: (isMobile ? textTheme.headlineSmall : textTheme.headlineMedium)
          ?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    );

    final cta = _PrimaryCtaButton(
      label: l10n.sellCarButton,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AddCarFlowScreen(),
          ),
        );
      },
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          cta,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        cta,
      ],
    );
  }
}

class _PrimaryCtaButton extends StatefulWidget {
  const _PrimaryCtaButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryCtaButton> createState() => _PrimaryCtaButtonState();
}

class _PrimaryCtaButtonState extends State<_PrimaryCtaButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1,
        duration: const Duration(milliseconds: 200),
        child: FilledButton.icon(
          onPressed: widget.onTap,
          icon: const Icon(Icons.add, size: 16),
          label: Text(widget.label),
        ),
      ),
    );
  }
}

class _WishlistSection extends StatelessWidget {
  const _WishlistSection({
    required this.sectionKey,
    required this.cars,
    required this.onRemove,
  });

  final GlobalKey sectionKey;
  final List<Map<String, dynamic>> cars;
  final Future<void> Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: sectionKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.favoritesSectionTitle,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          if (cars.isEmpty)
            _EmptyPlaceholder(message: l10n.favoritesEmpty)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const minTileWidth = 280.0;
                const gap = 24.0;
                final columns = (constraints.maxWidth / (minTileWidth + gap))
                    .floor()
                    .clamp(1, 4);
                final tileWidth =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final car in cars)
                      SizedBox(
                        width: tileWidth,
                        child: WishlistCarCard(
                          title: car['title']?.toString() ?? '',
                          price: car['price']?.toString() ?? '—',
                          imageUrl: car['imageUrl']?.toString() ?? '',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CarDetailsScreen(car: car),
                              ),
                            );
                          },
                          onRemove: () => onRemove(car['id']?.toString() ?? ''),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MyAdsSection extends StatelessWidget {
  const _MyAdsSection({
    required this.sectionKey,
    required this.ads,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkAsSold,
    required this.onViewOffers,
    required this.onToggleActive,
    required this.formatPostedDate,
    required this.daysRemaining,
    required this.parseCreatedAt,
  });

  final GlobalKey sectionKey;
  final List<Map<String, dynamic>> ads;
  final bool isMobile;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;
  final ValueChanged<Map<String, dynamic>> onMarkAsSold;
  final ValueChanged<Map<String, dynamic>> onViewOffers;
  final ValueChanged<Map<String, dynamic>> onToggleActive;
  final String Function(DateTime? createdAt) formatPostedDate;
  final int? Function(DateTime? createdAt) daysRemaining;
  final DateTime? Function(dynamic value) parseCreatedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: sectionKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.navMyAds,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(l10n.viewAllListings),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ads.isEmpty
                  ? _EmptyPlaceholder(message: l10n.myAdsEmpty)
                  : ListView.separated(
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ads.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final ad = ads[index];
                        final rawStatus = ad['status']?.toString() ??
                            CarDatabaseService.statusActive;
                        final isDraft =
                            rawStatus == CarDatabaseService.statusDraft;
                        final isSold =
                            rawStatus == CarDatabaseService.statusSold;
                        final isActive =
                            rawStatus == CarDatabaseService.statusActive;
                        final canToggleActive =
                            rawStatus == CarDatabaseService.statusActive ||
                                rawStatus == CarDatabaseService.statusExpired;
                        final createdAt = parseCreatedAt(ad['createdAt']);
                        final remaining = daysRemaining(createdAt);
                        final latestBid = BidDisplay.highestBidLabel(
                          car: ad,
                          firestoreData: ad,
                        );

                        return UserCarListItem(
                          title: _formatCarTitle(
                            ad['title']?.toString() ?? '',
                          ),
                          price: ad['price']?.toString() ?? '—',
                          imageUrl: ad['imageUrl']?.toString() ?? '',
                          isMobile: isMobile,
                          isDraft: isDraft,
                          isSold: isSold,
                          isActive: isActive,
                          canToggleActive: canToggleActive,
                          latestBidLabel: latestBid,
                          postedLabel:
                              l10n.adPostedAt(formatPostedDate(createdAt)),
                          daysRemainingLabel: remaining != null && !isDraft
                              ? l10n.adDaysRemaining(remaining)
                              : null,
                          draftLabel: l10n.adCompleteDraft,
                          onEdit: () => onEdit(ad),
                          onPrices: () => onViewOffers(ad),
                          onMarkAsSold: () => onMarkAsSold(ad),
                          onDelete: () => onDelete(ad),
                          onToggleActive: () => onToggleActive(ad),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCarTitle(String raw) {
  if (raw.isEmpty) return raw;
  return raw
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        if (word.length == 1) return word.toUpperCase();
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
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

class _UserSettingsSection extends ConsumerStatefulWidget {
  const _UserSettingsSection();

  @override
  ConsumerState<_UserSettingsSection> createState() =>
      __UserSettingsSectionState();
}

class __UserSettingsSectionState extends ConsumerState<_UserSettingsSection> {
  final _displayNameCtrl = TextEditingController();
  final _showroomNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();

  String? _selectedCity;
  bool _isSavingProfile = false;
  bool _initialized = false;
  bool _priceAlerts = true;
  bool _newMatchAlerts = true;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _showroomNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile(UserProfile? profile) {
    if (_initialized || profile == null) return;
    _initialized = true;
    _displayNameCtrl.text = profile.displayName;
    _showroomNameCtrl.text = profile.showroomName ?? '';
    _ownerNameCtrl.text = profile.ownerName ?? '';
    _selectedCity = profile.city;
  }

  Future<void> _saveProfile(String uid) async {
    final name = _displayNameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSavingProfile = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
            uid: uid,
            displayName: name,
            city: _selectedCity,
            showroomName: _showroomNameCtrl.text.trim(),
            ownerName: _ownerNameCtrl.text.trim(),
          );
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AddCarTheme.success(context),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (newPasswordCtrl.text.trim() != confirmPasswordCtrl.text.trim()) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Update Password'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authServiceProvider).updatePassword(
            currentPassword: currentPasswordCtrl.text.trim(),
            newPassword: newPasswordCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AddCarTheme.success(context),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          err.toString(),
          style: TextStyle(color: scheme.error),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text('User profile not found.'));
        }

        _initFromProfile(profile);

        final isShowroom = profile.accountType.firestoreValue == 'showroom';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Overview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AddCarTheme.cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.phone,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isShowroom
                              ? scheme.secondaryContainer
                              : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          profile.accountType.firestoreValue.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isShowroom
                                ? scheme.onSecondaryContainer
                                : scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Edit Profile Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AddCarTheme.cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: AddCarTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _displayNameCtrl,
                    decoration: AddCarTheme.textFieldDecoration(
                      context,
                      hintText: 'Display Name / Full Name',
                    ),
                  ),
                  if (isShowroom) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _showroomNameCtrl,
                      decoration: AddCarTheme.textFieldDecoration(
                        context,
                        hintText: 'Showroom Name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ownerNameCtrl,
                      decoration: AddCarTheme.textFieldDecoration(
                        context,
                        hintText: 'Owner Name',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity != null &&
                            IraqLocations.provinceOrder.contains(_selectedCity)
                        ? _selectedCity
                        : null,
                    decoration: AddCarTheme.textFieldDecoration(
                      context,
                      hintText: 'Select Governorate / City',
                    ),
                    items: IraqLocations.provinceOrder.map((city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(
                          IraqLocationL10n.provinceLabel(l10n, city),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCity = val),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      onPressed:
                          _isSavingProfile ? null : () => _saveProfile(profile.uid),
                      icon: _isSavingProfile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Security & Preferences Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AddCarTheme.cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security & Preferences',
                    style: AddCarTheme.sectionTitle(context),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Password & Security'),
                    subtitle: const Text('Update your account password'),
                    trailing: OutlinedButton(
                      onPressed: _showChangePasswordDialog,
                      child: const Text('Change'),
                    ),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _priceAlerts,
                    onChanged: (val) => setState(() => _priceAlerts = val),
                    title: const Text('Price Drop Alerts'),
                    subtitle: const Text(
                      'Receive notifications when prices change on your saved cars',
                    ),
                    secondary: const Icon(Icons.notifications_active_outlined),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _newMatchAlerts,
                    onChanged: (val) => setState(() => _newMatchAlerts = val),
                    title: const Text('New Listing Match Alerts'),
                    subtitle: const Text(
                      'Get notified when new cars matching your preferences are posted',
                    ),
                    secondary: const Icon(Icons.car_rental),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
