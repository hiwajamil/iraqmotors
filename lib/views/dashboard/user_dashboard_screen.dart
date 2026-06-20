import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n_extensions.dart';
import '../../data/add_car_form_options.dart';
import '../../providers/auth_providers.dart';
import '../../providers/storage_providers.dart';
import '../../services/car_database_service.dart';
import '../../widgets/car_bid_history_sheet.dart';
import '../../widgets/wishlist_car_card.dart';
import '../add_car/add_car_flow_screen.dart';
import '../home/home_screen.dart';

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
    _DashboardNav.dashboard,
    _DashboardNav.myAds,
    _DashboardNav.wishlist,
    _DashboardNav.messages,
  ];

  _DashboardNav _activeNav = _DashboardNav.dashboard;
  int _currentIndex = 0;

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

  String _statusLabel(String rawStatus) {
    final l10n = context.l10n;
    return switch (rawStatus) {
      CarDatabaseService.statusSold => l10n.adStatusSold,
      CarDatabaseService.statusPending => l10n.adminStatPendingReview,
      CarDatabaseService.statusRejected => l10n.adminAdRejectedSuccess,
      CarDatabaseService.statusExpired => l10n.adminStatExpired,
      _ => l10n.adStatusActive,
    };
  }

  void _onEditAd(Map<String, dynamic> ad) {
    final adId = ad['id']?.toString();
    if (adId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddCarFlowScreen(
          existingAdId: adId,
          existingCarData: _carDataForEdit(ad),
        ),
      ),
    );
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

    CarBidHistorySheet.show(
      context,
      carId: adId,
      carTitle: ad['title']?.toString() ?? '',
      currencyKey: ad['currencyKey']?.toString(),
    );
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
          statusLabel: _statusLabel,
          formatPostedDate: _formatPostedDate,
          daysRemaining: _daysRemaining,
          parseCreatedAt: _parseCreatedAt,
        ),
      _DashboardNav.messages =>
        _EmptyPlaceholder(message: context.l10n.messagesEmpty),
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

class _NavMenu extends StatelessWidget {
  const _NavMenu({
    required this.activeNav,
    required this.onNavTap,
  });

  final _DashboardNav activeNav;
  final ValueChanged<_DashboardNav> onNavTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        badgeCount: 2,
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
    required this.statusLabel,
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
  final String Function(String rawStatus) statusLabel;
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
                        _AdListItem(
                          ad: ads[i],
                          isMobile: isMobile,
                          onEdit: () => onEdit(ads[i]),
                          onDelete: () => onDelete(ads[i]),
                          onMarkAsSold: () => onMarkAsSold(ads[i]),
                          onViewOffers: () => onViewOffers(ads[i]),
                          statusLabel: statusLabel,
                          formatPostedDate: formatPostedDate,
                          daysRemaining: daysRemaining,
                          parseCreatedAt: parseCreatedAt,
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

class _AdListItem extends StatelessWidget {
  const _AdListItem({
    required this.ad,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkAsSold,
    required this.onViewOffers,
    required this.statusLabel,
    required this.formatPostedDate,
    required this.daysRemaining,
    required this.parseCreatedAt,
  });

  final Map<String, dynamic> ad;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsSold;
  final VoidCallback onViewOffers;
  final String Function(String rawStatus) statusLabel;
  final String Function(DateTime? createdAt) formatPostedDate;
  final int? Function(DateTime? createdAt) daysRemaining;
  final DateTime? Function(dynamic value) parseCreatedAt;

  static const Color _dateColor = Color(0xFF6E6E73);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rawStatus =
        ad['status']?.toString() ?? CarDatabaseService.statusActive;
    final isSold = rawStatus == CarDatabaseService.statusSold;
    final createdAt = parseCreatedAt(ad['createdAt']);
    final remaining = daysRemaining(createdAt);
    final photoUrls = (ad['photoUrls'] as List?)
            ?.map((e) => e.toString())
            .where((url) => url.isNotEmpty)
            .take(4)
            .toList() ??
        const <String>[];

    final statusColors = isSold
        ? (
            bg: const Color(0xFF1B5E20).withValues(alpha: 0.1),
            fg: const Color(0xFF1B5E20),
          )
        : rawStatus == CarDatabaseService.statusActive
            ? (
                bg: const Color(0xFF34C759).withValues(alpha: 0.1),
                fg: const Color(0xFF34C759),
              )
            : (
                bg: const Color(0xFF86868B).withValues(alpha: 0.1),
                fg: const Color(0xFF86868B),
              );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoThumbnailRow(urls: photoUrls),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adPostedAt(formatPostedDate(createdAt)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _dateColor,
                      height: 1.35,
                    ),
                  ),
                  if (remaining != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.adDaysRemaining(remaining),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _dateColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel(rawStatus),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColors.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final actionButtons = <Widget>[
      _ActionButton(label: l10n.editAction, onTap: onEdit),
      _ActionButton(
        label: l10n.offersAction,
        icon: Icons.gavel_rounded,
        onTap: onViewOffers,
        isOutlined: true,
        accentColor: const Color(0xFF007AFF),
      ),
      if (!isSold)
        _ActionButton(
          label: l10n.soldAction,
          onTap: onMarkAsSold,
          isOutlined: true,
          accentColor: const Color(0xFF1B5E20),
        ),
      _ActionButton(
        label: l10n.deleteAction,
        onTap: onDelete,
        isDestructive: true,
      ),
    ];

    final actions = isMobile
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: actionButtons,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actionButtons.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actionButtons[i],
              ],
            ],
          );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            info,
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: actions,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: info),
          const SizedBox(width: 16),
          actions,
        ],
      ),
    );
  }
}

class _PhotoThumbnailRow extends StatelessWidget {
  const _PhotoThumbnailRow({required this.urls});

  final List<String> urls;

  static const double _size = 55;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final slots = urls.length >= 4
        ? urls.take(4).toList()
        : [
            ...urls,
            for (var i = urls.length; i < 4; i++) null,
          ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          _PhotoThumb(url: slots[i]),
        ],
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _PhotoThumbnailRow._size,
        height: _PhotoThumbnailRow._size,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F5F7),
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_car_outlined,
        size: 22,
        color: Colors.black.withValues(alpha: 0.12),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isDestructive = false,
    this.isOutlined = false,
    this.accentColor,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isDestructive;
  final bool isOutlined;
  final Color? accentColor;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? const Color(0xFF1D1D1F);
    final color = widget.isDestructive
        ? const Color(0xFFFF3B30)
        : widget.isOutlined
            ? accent
            : const Color(0xFF1D1D1F);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? (_hovered
                    ? accent.withValues(alpha: 0.08)
                    : Colors.transparent)
                : (_hovered
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFFF5F5F7)),
            borderRadius: BorderRadius.circular(8),
            border: widget.isOutlined
                ? Border.all(
                    color: accent.withValues(alpha: _hovered ? 0.9 : 0.55),
                    width: 1.2,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: color),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
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
