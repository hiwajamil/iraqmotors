import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_extensions.dart';
import '../../data/add_car_form_options.dart';
import '../../providers/auth_providers.dart';
import '../../providers/storage_providers.dart';
import '../../services/car_database_service.dart';
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
  home,
  wishlist,
  myAds,
  messages,
  settings,
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  static const Color _bgMain = Color(0xFFF5F5F7);
  static const double _mobileBreakpoint = 900;

  _DashboardNav _activeNav = _DashboardNav.wishlist;

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
    final l10n = context.l10n;
    return {
      ...doc,
      'title': _carTitle(doc),
      'status': doc['status']?.toString() ?? l10n.adStatusActive,
      'imageUrl': _firstImageUrl(doc),
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
    final urls = data['imageUrls'];
    if (urls is List && urls.isNotEmpty) {
      return urls.first.toString();
    }
    return data['imageUrl']?.toString() ?? '';
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

  void _onNavTap(_DashboardNav nav) {
    if (nav == _DashboardNav.home) {
      _goHome();
      return;
    }
    setState(() => _activeNav = nav);
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
    return Scaffold(
      backgroundColor: _bgMain,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < _mobileBreakpoint;
            if (isMobile) {
              return Column(
                children: [
                  _DashboardSidebar(
                    isCompact: true,
                    activeNav: _activeNav,
                    onNavTap: _onNavTap,
                    onLogout: _logout,
                  ),
                  Expanded(child: _buildMainContent(isMobile: true)),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: _DashboardSidebar(
                    isCompact: false,
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
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsetsDirectional.fromSTEB(
        isMobile ? 20 : constraintsPadding(context),
        isMobile ? 24 : 40,
        isMobile ? 20 : constraintsPadding(context),
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

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar({
    required this.isCompact,
    required this.activeNav,
    required this.onNavTap,
    required this.onLogout,
  });

  final bool isCompact;
  final _DashboardNav activeNav;
  final ValueChanged<_DashboardNav> onNavTap;
  final VoidCallback onLogout;

  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: _bgCard,
          border: Border(
            bottom: BorderSide(color: _borderLight),
          ),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _UserProfileSummary(isCompact: true),
            const SizedBox(height: 16),
            _NavMenu(
              isHorizontal: true,
              activeNav: activeNav,
              onNavTap: onNavTap,
            ),
          ],
        ),
      );
    }

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
            isHorizontal: false,
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
    required this.isHorizontal,
    required this.activeNav,
    required this.onNavTap,
  });

  final bool isHorizontal;
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

    if (isHorizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items) ...[
              _NavLink(
                item: item,
                isActive: activeNav == item.nav,
                isHorizontal: true,
                onTap: () => onNavTap(item.nav),
              ),
              if (item != items.last) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          _NavLink(
            item: item,
            isActive: activeNav == item.nav,
            isHorizontal: false,
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
    required this.isHorizontal,
    required this.onTap,
  });

  final _NavItemData item;
  final bool isActive;
  final bool isHorizontal;
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
            mainAxisSize:
                widget.isHorizontal ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(widget.item.icon, size: 18, color: fg),
              SizedBox(width: widget.isHorizontal ? 8 : 15),
              if (!widget.isHorizontal)
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                )
              else
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fg,
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
  });

  final GlobalKey sectionKey;
  final List<Map<String, dynamic>> ads;
  final bool isMobile;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

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
  });

  final Map<String, dynamic> ad;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            ad['imageUrl']?.toString() ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 60,
              color: const Color(0xFFF5F5F7),
              child: const Icon(Icons.directions_car_outlined),
            ),
          ),
        ),
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
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ad['status']?.toString() ?? l10n.adStatusActive,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF34C759),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(label: l10n.editAction, onTap: onEdit),
        const SizedBox(width: 10),
        _ActionButton(
          label: l10n.deleteAction,
          onTap: onDelete,
          isDestructive: true,
        ),
      ],
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: info),
                actions,
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(child: info),
          actions,
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? const Color(0xFFFF3B30)
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
            color: _hovered
                ? const Color(0xFFE5E5EA)
                : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
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
