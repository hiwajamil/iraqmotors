import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/admin/domain/models/showroom_listing_status.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/dashboard/presentation/widgets/showroom_car_list_item.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/home_screen.dart';

/// Showroom / dealership dashboard — sidebar (RTL start) + stats + listings.
class ShowroomDashboardScreen extends ConsumerStatefulWidget {
  const ShowroomDashboardScreen({super.key});

  @override
  ConsumerState<ShowroomDashboardScreen> createState() =>
      _ShowroomDashboardScreenState();
}

enum _ShowroomNav {
  dashboard,
  myCars,
  messages,
  stats,
  settings,
}

enum _ListingFilter {
  all,
  active,
  pending,
}

class _ShowroomDashboardScreenState
    extends ConsumerState<ShowroomDashboardScreen> {
  static const double _mobileBreakpoint = 992;

  _ShowroomNav _activeNav = _ShowroomNav.dashboard;
  _ListingFilter _listingFilter = _ListingFilter.all;

  static const String _showroomName = 'پێشانگای ڤی ئای پی';

  static const List<_StatCardData> _stats = [
    _StatCardData(
      value: '١٢',
      label: 'ئۆتۆمبێلی چالاک',
      icon: Icons.directions_car_outlined,
    ),
    _StatCardData(
      value: '١٤.٥K',
      label: 'کۆی بینین لەم مانگەدا',
      icon: Icons.visibility_outlined,
    ),
    _StatCardData(
      value: '٢٨',
      label: 'کلیک بۆ پەیوەندی کردن',
      icon: Icons.phone_outlined,
    ),
  ];

  static const List<_ShowroomListingData> _allListings = [
    _ShowroomListingData(
      id: '1',
      title: 'Cadillac Escalade-V 2024',
      price: r'$165,000',
      latestBid: r'$168,500',
      imageUrl:
          'https://images.unsplash.com/photo-1562911791-c7a97b729ec5?q=80&w=200&auto=format&fit=crop',
      viewsLabel: '١,٢٤٠ بینین',
      savesLabel: '٤٥ سەیڤکراو',
      status: ShowroomListingStatus.active,
    ),
    _ShowroomListingData(
      id: '2',
      title: 'Mercedes-Benz S500',
      price: r'$158,000',
      imageUrl:
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=200&auto=format&fit=crop',
      viewsLabel: '٠ بینین',
      savesLabel: '٠ سەیڤکراو',
      status: ShowroomListingStatus.pending,
    ),
    _ShowroomListingData(
      id: '3',
      title: 'Lexus LX 600 VIP',
      price: r'$152,000',
      latestBid: r'$154,000',
      imageUrl:
          'https://images.unsplash.com/photo-1614200187524-dc4b892acf16?q=80&w=200&auto=format&fit=crop',
      viewsLabel: '٣,٤٥٠ بینین',
      savesLabel: '١٢٠ سەیڤکراو',
      status: ShowroomListingStatus.sold,
    ),
  ];

  List<_ShowroomListingData> get _filteredListings {
    return switch (_listingFilter) {
      _ListingFilter.all => _allListings,
      _ListingFilter.active => _allListings
          .where((l) => l.status == ShowroomListingStatus.active)
          .toList(),
      _ListingFilter.pending => _allListings
          .where((l) => l.status == ShowroomListingStatus.pending)
          .toList(),
    };
  }

  void _onNavTap(_ShowroomNav nav) {
    setState(() => _activeNav = nav);
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < _mobileBreakpoint;
              if (isMobile) {
                return Column(
                  children: [
                    _ShowroomSidebar(
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
                    child: _ShowroomSidebar(
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
      ),
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        isMobile ? 20 : _horizontalPadding(context),
        isMobile ? 24 : 40,
        isMobile ? 20 : _horizontalPadding(context),
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShowroomHeader(isMobile: isMobile, showroomName: _showroomName),
          const SizedBox(height: 40),
          _StatsGrid(stats: _stats, isMobile: isMobile),
          const SizedBox(height: 40),
          _ListingsSection(
            listings: _filteredListings,
            activeFilter: _listingFilter,
            isMobile: isMobile,
            onFilterChanged: (filter) {
              setState(() => _listingFilter = filter);
            },
          ),
        ],
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    return MediaQuery.sizeOf(context).width * 0.05;
  }
}

class _StatCardData {
  const _StatCardData({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _ShowroomListingData {
  const _ShowroomListingData({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.viewsLabel,
    required this.savesLabel,
    required this.status,
    this.latestBid,
  });

  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final String viewsLabel;
  final String savesLabel;
  final ShowroomListingStatus status;
  final String? latestBid;
}

class _ShowroomSidebar extends StatelessWidget {
  const _ShowroomSidebar({
    required this.isCompact,
    required this.activeNav,
    required this.onNavTap,
    required this.onLogout,
  });

  final bool isCompact;
  final _ShowroomNav activeNav;
  final ValueChanged<_ShowroomNav> onNavTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    if (isCompact) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: _BrandTitle()),
            const SizedBox(height: 20),
            _ShowroomNavMenu(
              isHorizontal: true,
              activeNav: activeNav,
              onNavTap: onNavTap,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 280,
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
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 10),
            child: _BrandTitle(),
          ),
          const SizedBox(height: 40),
          _ShowroomNavMenu(
            isHorizontal: false,
            activeNav: activeNav,
            onNavTap: onNavTap,
          ),
          const Spacer(),
          _ShowroomLogoutButton(onTap: onLogout),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'IQ Motors',
      style: context.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _ShowroomNavMenu extends StatelessWidget {
  const _ShowroomNavMenu({
    required this.isHorizontal,
    required this.activeNav,
    required this.onNavTap,
  });

  final bool isHorizontal;
  final _ShowroomNav activeNav;
  final ValueChanged<_ShowroomNav> onNavTap;

  static const List<_ShowroomNavItemData> _items = [
    _ShowroomNavItemData(
      nav: _ShowroomNav.dashboard,
      label: 'داشبۆرد',
      icon: Icons.dashboard_outlined,
    ),
    _ShowroomNavItemData(
      nav: _ShowroomNav.myCars,
      label: 'ئۆتۆمبێلەکانم',
      icon: Icons.directions_car_outlined,
    ),
    _ShowroomNavItemData(
      nav: _ShowroomNav.messages,
      label: 'نامەکان',
      icon: Icons.mail_outline,
      badgeCount: 3,
    ),
    _ShowroomNavItemData(
      nav: _ShowroomNav.stats,
      label: 'ئامارەکان',
      icon: Icons.show_chart_outlined,
    ),
    _ShowroomNavItemData(
      nav: _ShowroomNav.settings,
      label: 'ڕێکخستنی هەژمار',
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in _items) ...[
              _ShowroomNavLink(
                item: item,
                isActive: activeNav == item.nav,
                isHorizontal: true,
                onTap: () => onNavTap(item.nav),
              ),
              if (item != _items.last) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in _items) ...[
          _ShowroomNavLink(
            item: item,
            isActive: activeNav == item.nav,
            isHorizontal: false,
            onTap: () => onNavTap(item.nav),
          ),
          if (item != _items.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ShowroomNavItemData {
  const _ShowroomNavItemData({
    required this.nav,
    required this.label,
    required this.icon,
    this.badgeCount,
  });

  final _ShowroomNav nav;
  final String label;
  final IconData icon;
  final int? badgeCount;
}

class _ShowroomNavLink extends StatefulWidget {
  const _ShowroomNavLink({
    required this.item,
    required this.isActive,
    required this.isHorizontal,
    required this.onTap,
  });

  final _ShowroomNavItemData item;
  final bool isActive;
  final bool isHorizontal;
  final VoidCallback onTap;

  @override
  State<_ShowroomNavLink> createState() => _ShowroomNavLinkState();
}

class _ShowroomNavLinkState extends State<_ShowroomNavLink> {
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
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: widget.isHorizontal ? 12 : 16,
            vertical: widget.isHorizontal ? 8 : 12,
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
              SizedBox(width: widget.isHorizontal ? 8 : 16),
              if (!widget.isHorizontal)
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                )
              else
                Text(
                  widget.item.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              if (widget.item.badgeCount != null && !widget.isHorizontal) ...[
                const Spacer(),
                _NavBadge(count: widget.item.badgeCount!),
              ] else if (widget.item.badgeCount != null &&
                  widget.isHorizontal) ...[
                const SizedBox(width: 6),
                _NavBadge(count: widget.item.badgeCount!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onError,
        ),
      ),
    );
  }
}

class _ShowroomLogoutButton extends StatefulWidget {
  const _ShowroomLogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ShowroomLogoutButton> createState() => _ShowroomLogoutButtonState();
}

class _ShowroomLogoutButtonState extends State<_ShowroomLogoutButton> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(Icons.logout, size: 18, color: colorScheme.error),
            const SizedBox(width: 16),
            Text(
              'چوونەدەرەوە',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowroomHeader extends StatelessWidget {
  const _ShowroomHeader({
    required this.isMobile,
    required this.showroomName,
  });

  final bool isMobile;
  final String showroomName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final welcome = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بەخێربێیت، $showroomName',
          style: (isMobile ? textTheme.headlineSmall : textTheme.headlineMedium)
              ?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ئەمڕۆ ئامارەکانت زۆر باش دەردەکەون.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AddAdButton(onTap: () {}),
        const SizedBox(width: 20),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_outline,
            size: 22,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          welcome,
          const SizedBox(height: 20),
          actions,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: welcome),
        actions,
      ],
    );
  }
}

class _AddAdButton extends StatefulWidget {
  const _AddAdButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AddAdButton> createState() => _AddAdButtonState();
}

class _AddAdButtonState extends State<_AddAdButton> {
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
          label: const Text('ڕیکلامی نوێ'),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stats,
    required this.isMobile,
  });

  final List<_StatCardData> stats;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            _StatCard(data: stats[i]),
            if (i < stats.length - 1) const SizedBox(height: 20),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(child: _StatCard(data: stats[i])),
          if (i < stats.length - 1) const SizedBox(width: 20),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(data.icon, size: 24, color: colorScheme.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingsSection extends StatelessWidget {
  const _ListingsSection({
    required this.listings,
    required this.activeFilter,
    required this.isMobile,
    required this.onFilterChanged,
  });

  final List<_ShowroomListingData> listings;
  final _ListingFilter activeFilter;
  final bool isMobile;
  final ValueChanged<_ListingFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ListingsSectionHeader(
              activeFilter: activeFilter,
              isMobile: isMobile,
              onFilterChanged: onFilterChanged,
            ),
            const SizedBox(height: 24),
            if (listings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'هیچ ڕیکلامێک نییە',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < listings.length; i++) ...[
                    ShowroomCarListItem(
                      title: listings[i].title,
                      price: listings[i].price,
                      imageUrl: listings[i].imageUrl,
                      viewsLabel: listings[i].viewsLabel,
                      savesLabel: listings[i].savesLabel,
                      status: listings[i].status,
                      isMobile: isMobile,
                      latestBid: listings[i].latestBid,
                      onEdit: () {},
                      onPrices: () {},
                      onMarkAsSold: () {},
                      onDelete: () {},
                      onToggleActive: () {},
                    ),
                    if (i < listings.length - 1) const Divider(),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ListingsSectionHeader extends StatelessWidget {
  const _ListingsSectionHeader({
    required this.activeFilter,
    required this.isMobile,
    required this.onFilterChanged,
  });

  final _ListingFilter activeFilter;
  final bool isMobile;
  final ValueChanged<_ListingFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'دواین ڕیکلامەکانت',
      style: context.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colorScheme.onSurface,
      ),
    );

    final tabs = _FilterTabs(
      activeFilter: activeFilter,
      onFilterChanged: onFilterChanged,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 16),
          tabs,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        title,
        tabs,
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final _ListingFilter activeFilter;
  final ValueChanged<_ListingFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilterTab(
          label: 'هەمووی',
          isActive: activeFilter == _ListingFilter.all,
          onTap: () => onFilterChanged(_ListingFilter.all),
        ),
        const SizedBox(width: 16),
        _FilterTab(
          label: 'چالاک',
          isActive: activeFilter == _ListingFilter.active,
          onTap: () => onFilterChanged(_ListingFilter.active),
        ),
        const SizedBox(width: 16),
        _FilterTab(
          label: 'چاوەڕوان',
          isActive: activeFilter == _ListingFilter.pending,
          onTap: () => onFilterChanged(_ListingFilter.pending),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final accent = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: isActive ? 24 : 0,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
