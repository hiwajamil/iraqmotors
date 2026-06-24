import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:iq_motors/core/utils/bid_display.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/car_bid_history_dialog.dart';
import 'package:iq_motors/features/dashboard/presentation/widgets/user_car_list_item.dart';
import 'package:iq_motors/features/dashboard/presentation/widgets/user_inbox_section.dart';
import 'package:iq_motors/features/dashboard/presentation/widgets/wishlist_car_card.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/car_details_screen.dart';
import 'package:iq_motors/features/listings/presentation/add_car_flow_screen.dart';
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
  static const Color _bgMain = Color(0xFFF5F5F7);
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
          backgroundColor: const Color(0xFFFF3B30),
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAdTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.2,
          ),
        ),
        content: Text(
          l10n.deleteAdConfirm,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6E6E73),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancelAction,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.deleteAction,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
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
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.markAsSoldTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.2,
          ),
        ),
        content: Text(
          l10n.markAsSoldConfirm,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6E6E73),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancelAction,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.soldAction,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ),
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
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
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
          backgroundColor: const Color(0xFFFF3B30),
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
          backgroundColor: const Color(0xFFFF3B30),
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
      backgroundColor: _bgMain,
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
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 24),
      child: _buildActiveSection(isMobile: true),
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsetsDirectional.fromSTEB(
        constraintsPadding(context),
        40,
        constraintsPadding(context),
        40,
      ),
      child: Column(
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.navHomeScreen,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.person),
            activeIcon: const Icon(CupertinoIcons.person_fill),
            label: l10n.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.car),
            activeIcon: const Icon(CupertinoIcons.car_fill),
            label: l10n.navMyAds,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.heart),
            activeIcon: const Icon(CupertinoIcons.heart_fill),
            label: l10n.navMyFavorites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chat_bubble),
            activeIcon: const Icon(CupertinoIcons.chat_bubble_fill),
            label: l10n.navMessages,
          ),
        ],
      ),
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
      _DashboardNav.messages => const UserInboxSection(),
      _DashboardNav.settings =>
        _EmptyPlaceholder(message: context.l10n.settingsComingSoon),
    };
  }

  double constraintsPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width * 0.05;
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _bgCard,
        border: Border(
          bottom: BorderSide(color: _borderLight),
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

  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: _bgCard,
        border: BorderDirectional(
          end: BorderSide(color: _borderLight),
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
    final avatar = Container(
      width: isCompact ? 60 : 80,
      height: isCompact ? 60 : 80,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F7),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline,
        size: 30,
        color: Color(0xFF86868B),
      ),
    );

    final textBlock = Column(
      crossAxisAlignment:
          isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          l10n.dummyPublisherHiwa,
          style: TextStyle(
            fontSize: isCompact ? 17 : 19.2,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.userAccountPersonal,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF86868B),
            height: 1.3,
          ),
        ),
      ],
    );

    if (isCompact) {
      return Row(
        children: [
          avatar,
          const SizedBox(width: 15),
          Expanded(child: textBlock),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA)),
        ),
      ),
      child: Column(
        children: [
          avatar,
          const SizedBox(height: 15),
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
    final bg = widget.isActive
        ? const Color(0xFF000000)
        : _hovered
            ? const Color(0xFFF5F5F7)
            : Colors.transparent;
    final fg = widget.isActive
        ? Colors.white
        : _hovered
            ? const Color(0xFF1D1D1F)
            : const Color(0xFF86868B);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, size: 18, color: fg),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 15,
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
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.item.badgeCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFFF3B30).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: Color(0xFFFF3B30)),
              const SizedBox(width: 15),
              Text(
                context.l10n.signOut,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFF3B30),
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
    final title = Text(
      l10n.userDashboardTitle,
      style: TextStyle(
        fontSize: isMobile ? 26 : 32,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1D1D1F),
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
          const SizedBox(height: 15),
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.favoritesSectionTitle,
            style: const TextStyle(
              fontSize: 22.4,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.navMyAds,
                style: const TextStyle(
                  fontSize: 22.4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  l10n.viewAllListings,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ads.isEmpty
                ? _EmptyPlaceholder(message: l10n.myAdsEmpty)
                : Column(
                    children: [
                      for (var i = 0; i < ads.length; i++) ...[
                        Builder(
                          builder: (context) {
                            final ad = ads[i];
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
                        if (i < ads.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE5E5EA),
                          ),
                      ],
                    ],
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
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF86868B),
          ),
        ),
      ),
    );
  }
}
