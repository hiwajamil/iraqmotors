import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/filter_l10n.dart';
import '../../core/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';

/// Platform super-admin dashboard — approvals queue, platform stats, sidebar.
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

enum _SuperAdminNav {
  dashboard,
  approvals,
  users,
  showrooms,
  reports,
  settings,
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  static const Color _bgMain = Color(0xFFF5F5F7);
  static const double _mobileBreakpoint = 992;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _SuperAdminNav _activeNav = _SuperAdminNav.dashboard;

  List<_SuperAdminStatData> _buildStats(AppLocalizations l10n) => [
        _SuperAdminStatData(
          value: '١٤',
          label: l10n.statPendingApproval,
          icon: Icons.pending_actions_outlined,
          accentBg: const Color(0xFFFFF4E6),
          accentFg: const Color(0xFFFF9500),
        ),
        _SuperAdminStatData(
          value: '٢,٤٨٠',
          label: l10n.statTotalUsers,
          icon: Icons.people_outline,
          accentBg: const Color(0xFFE8F2FF),
          accentFg: const Color(0xFF007AFF),
        ),
        _SuperAdminStatData(
          value: '٨٩٢',
          label: l10n.statActiveListings,
          icon: Icons.directions_car_outlined,
          accentBg: const Color(0xFFE8F8ED),
          accentFg: const Color(0xFF34C759),
        ),
        _SuperAdminStatData(
          value: '٦٤',
          label: l10n.statRegisteredShowrooms,
          icon: Icons.storefront_outlined,
          accentBg: const Color(0xFFF3EBFF),
          accentFg: const Color(0xFFAF52DE),
        ),
      ];

  List<_PendingApprovalData> _buildPendingApprovals(AppLocalizations l10n) => [
        _PendingApprovalData(
          id: '1',
          title: 'Cadillac Escalade-V 2024',
          price: r'$165,000',
          imageUrl:
              'https://images.unsplash.com/photo-1562911791-c7a97b729ec5?q=80&w=200&auto=format&fit=crop',
          publisherName: l10n.dummyPublisherVipShowroom,
          publisherType: 'showroom',
          publisherPhone: '0750 123 4567',
        ),
        _PendingApprovalData(
          id: '2',
          title: 'Mercedes-Benz S500',
          price: r'$158,000',
          imageUrl:
              'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=200&auto=format&fit=crop',
          publisherName: l10n.dummyPublisherAras,
          publisherType: 'individual',
          publisherPhone: '0770 987 6543',
        ),
        _PendingApprovalData(
          id: '3',
          title: 'Lexus LX 600 VIP',
          price: r'$152,000',
          imageUrl:
              'https://images.unsplash.com/photo-1614200187524-dc4b892acf16?q=80&w=200&auto=format&fit=crop',
          publisherName: l10n.dummyPublisherAlofShowroom,
          publisherType: 'showroom',
          publisherPhone: '0751 222 3344',
        ),
        _PendingApprovalData(
          id: '4',
          title: 'BMW X7 M60i',
          price: r'$142,500',
          imageUrl:
              'https://images.unsplash.com/photo-1555215695-3004980ad54e?q=80&w=200&auto=format&fit=crop',
          publisherName: l10n.dummyPublisherHiwa,
          publisherType: 'individual',
          publisherPhone: '0780 555 1212',
        ),
      ];

  void _onNavTap(_SuperAdminNav nav) {
    setState(() => _activeNav = nav);
    if (MediaQuery.sizeOf(context).width < _mobileBreakpoint) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: _bgMain,
            drawer: Drawer(
              width: 280,
              backgroundColor: Colors.white,
              child: SafeArea(
                child: _SuperAdminSidebar(
                  isCompact: false,
                  activeNav: _activeNav,
                  onNavTap: _onNavTap,
                  onLogout: _logout,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MobileTopBar(
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: _buildMainContent(isMobile: true),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _bgMain,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: _SuperAdminSidebar(
                    isCompact: false,
                    activeNav: _activeNav,
                    onNavTap: _onNavTap,
                    onLogout: _logout,
                  ),
                ),
                Expanded(child: _buildMainContent(isMobile: false)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    final l10n = context.l10n;
    final adminName = l10n.superAdminTitle;

    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        isMobile ? 20 : _horizontalPadding(context),
        isMobile ? 20 : 40,
        isMobile ? 20 : _horizontalPadding(context),
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SuperAdminHeader(isMobile: isMobile, adminName: adminName),
          const SizedBox(height: 32),
          _SuperAdminStatsGrid(
            stats: _buildStats(l10n),
            isMobile: isMobile,
          ),
          const SizedBox(height: 40),
          _PendingApprovalsSection(
            approvals: _buildPendingApprovals(l10n),
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    return MediaQuery.sizeOf(context).width * 0.05;
  }
}

class _SuperAdminStatData {
  const _SuperAdminStatData({
    required this.value,
    required this.label,
    required this.icon,
    required this.accentBg,
    required this.accentFg,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accentBg;
  final Color accentFg;
}

class _PendingApprovalData {
  const _PendingApprovalData({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.publisherName,
    required this.publisherType,
    required this.publisherPhone,
  });

  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final String publisherName;
  final String publisherType;
  final String publisherPhone;
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 20, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu, color: Color(0xFF1D1D1F)),
          ),
          Expanded(
            child: Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SuperAdminSidebar extends StatelessWidget {
  const _SuperAdminSidebar({
    required this.isCompact,
    required this.activeNav,
    required this.onNavTap,
    required this.onLogout,
  });

  final bool isCompact;
  final _SuperAdminNav activeNav;
  final ValueChanged<_SuperAdminNav> onNavTap;
  final VoidCallback onLogout;

  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: isCompact ? double.infinity : 280,
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
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 10),
            child: _BrandBlock(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Text(
              l10n.superAdminTitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF86868B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 36),
          _SuperAdminNavMenu(
            activeNav: activeNav,
            onNavTap: onNavTap,
          ),
          const Spacer(),
          _SuperAdminLogoutButton(onTap: onLogout),
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1F),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.appTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _SuperAdminNavMenu extends StatelessWidget {
  const _SuperAdminNavMenu({
    required this.activeNav,
    required this.onNavTap,
  });

  final _SuperAdminNav activeNav;
  final ValueChanged<_SuperAdminNav> onNavTap;

  static const List<_SuperAdminNavItemConfig> _itemConfigs = [
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.dashboard,
      icon: Icons.dashboard_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.approvals,
      icon: Icons.fact_check_outlined,
      badgeCount: 14,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.users,
      icon: Icons.people_outline,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.showrooms,
      icon: Icons.storefront_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.reports,
      icon: Icons.analytics_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.settings,
      icon: Icons.settings_outlined,
    ),
  ];

  static String _navLabel(AppLocalizations l10n, _SuperAdminNav nav) {
    return switch (nav) {
      _SuperAdminNav.dashboard => l10n.navDashboard,
      _SuperAdminNav.approvals => l10n.navApprovals,
      _SuperAdminNav.users => l10n.navUsers,
      _SuperAdminNav.showrooms => l10n.navShowrooms,
      _SuperAdminNav.reports => l10n.navReports,
      _SuperAdminNav.settings => l10n.navSettings,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        for (final config in _itemConfigs) ...[
          _SuperAdminNavLink(
            label: _navLabel(l10n, config.nav),
            icon: config.icon,
            badgeCount: config.badgeCount,
            isActive: activeNav == config.nav,
            onTap: () => onNavTap(config.nav),
          ),
          if (config != _itemConfigs.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SuperAdminNavItemConfig {
  const _SuperAdminNavItemConfig({
    required this.nav,
    required this.icon,
    this.badgeCount,
  });

  final _SuperAdminNav nav;
  final IconData icon;
  final int? badgeCount;
}

class _SuperAdminNavLink extends StatefulWidget {
  const _SuperAdminNavLink({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final int? badgeCount;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_SuperAdminNavLink> createState() => _SuperAdminNavLinkState();
}

class _SuperAdminNavLinkState extends State<_SuperAdminNavLink> {
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
              Icon(widget.icon, size: 18, color: fg),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              if (widget.badgeCount != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? const Color(0xFFFF9500)
                        : const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.badgeCount}',
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

class _SuperAdminLogoutButton extends StatelessWidget {
  const _SuperAdminLogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, size: 18, color: Color(0xFFFF3B30)),
            const SizedBox(width: 15),
            Text(
              l10n.signOut,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperAdminHeader extends StatelessWidget {
  const _SuperAdminHeader({
    required this.isMobile,
    required this.adminName,
  });

  final bool isMobile;
  final String adminName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final welcome = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeAdmin(adminName),
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF86868B),
          ),
        ),
      ],
    );

    final badge = Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9500).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 16,
            color: Color(0xFFFF9500),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.superAdminBadge,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF9500),
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          welcome,
          const SizedBox(height: 16),
          badge,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: welcome),
        badge,
      ],
    );
  }
}

class _SuperAdminStatsGrid extends StatelessWidget {
  const _SuperAdminStatsGrid({
    required this.stats,
    required this.isMobile,
  });

  final List<_SuperAdminStatData> stats;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (!isMobile) {
      return Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(child: _SuperAdminStatCard(data: stats[i])),
            if (i < stats.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final twoColumns = width >= 480;

    if (!twoColumns) {
      return Column(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            _SuperAdminStatCard(data: stats[i]),
            if (i < stats.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SuperAdminStatCard(data: stats[0])),
            const SizedBox(width: 14),
            Expanded(child: _SuperAdminStatCard(data: stats[1])),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _SuperAdminStatCard(data: stats[2])),
            const SizedBox(width: 14),
            Expanded(child: _SuperAdminStatCard(data: stats[3])),
          ],
        ),
      ],
    );
  }
}

class _SuperAdminStatCard extends StatelessWidget {
  const _SuperAdminStatCard({required this.data});

  final _SuperAdminStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.accentBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 24, color: data.accentFg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF86868B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalsSection extends StatelessWidget {
  const _PendingApprovalsSection({
    required this.approvals,
    required this.isMobile,
  });

  final List<_PendingApprovalData> approvals;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.pendingListingsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.newCount(approvals.length),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pendingListingsSubtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF86868B)),
          ),
          const SizedBox(height: 24),
          if (!isMobile) const _ApprovalsTableHeader(),
          if (!isMobile) const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: approvals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _PendingApprovalRow(
                data: approvals[index],
                isMobile: isMobile,
                onView: () {},
                onReject: () {},
                onApprove: () {},
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ApprovalsTableHeader extends StatelessWidget {
  const _ApprovalsTableHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: _HeaderCell(l10n.tableCar)),
          Expanded(flex: 3, child: _HeaderCell(l10n.tablePublisher)),
          Expanded(flex: 2, child: _HeaderCell(l10n.tablePrice)),
          Expanded(flex: 3, child: _HeaderCell(l10n.tableActions)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF86868B),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _PendingApprovalRow extends StatelessWidget {
  const _PendingApprovalRow({
    required this.data,
    required this.isMobile,
    required this.onView,
    required this.onReject,
    required this.onApprove,
  });

  final _PendingApprovalData data;
  final bool isMobile;
  final VoidCallback onView;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _PendingApprovalCard(
        data: data,
        onView: onView,
        onReject: onReject,
        onApprove: onApprove,
      );
    }

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: _CarCell(data: data)),
          Expanded(flex: 3, child: _PublisherCell(data: data)),
          Expanded(
            flex: 2,
            child: Text(
              data.price,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _ApprovalActions(
              onView: onView,
              onReject: onReject,
              onApprove: onApprove,
              compact: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalCard extends StatelessWidget {
  const _PendingApprovalCard({
    required this.data,
    required this.onView,
    required this.onReject,
    required this.onApprove,
  });

  final _PendingApprovalData data;
  final VoidCallback onView;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CarCell(data: data),
          const SizedBox(height: 14),
          _PublisherCell(data: data),
          const SizedBox(height: 12),
          Text(
            data.price,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 14),
          _ApprovalActions(
            onView: onView,
            onReject: onReject,
            onApprove: onApprove,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _CarCell extends StatelessWidget {
  const _CarCell({required this.data});

  final _PendingApprovalData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            data.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: const Color(0xFFE5E5EA),
              child: const Icon(Icons.directions_car_outlined),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            data.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PublisherCell extends StatelessWidget {
  const _PublisherCell({required this.data});

  final _PendingApprovalData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isShowroom = data.publisherType == 'showroom';
    final typeLabel = FilterL10n.publisherTypeLabel(l10n, data.publisherType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.publisherName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isShowroom
                    ? const Color(0xFFF3EBFF)
                    : const Color(0xFFE8F2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isShowroom
                      ? const Color(0xFFAF52DE)
                      : const Color(0xFF007AFF),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data.publisherPhone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF86868B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ApprovalActions extends StatelessWidget {
  const _ApprovalActions({
    required this.onView,
    required this.onReject,
    required this.onApprove,
    required this.compact,
  });

  final VoidCallback onView;
  final VoidCallback onReject;
  final VoidCallback onApprove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final children = [
      _ActionChip(
        label: l10n.actionView,
        icon: Icons.visibility_outlined,
        fg: const Color(0xFF007AFF),
        bg: const Color(0xFFE8F2FF),
        border: const Color(0xFF007AFF),
        filled: false,
        onTap: onView,
        expand: compact,
      ),
      _ActionChip(
        label: l10n.actionReject,
        icon: Icons.close,
        fg: const Color(0xFFFF3B30),
        bg: Colors.white,
        border: const Color(0xFFFF3B30),
        filled: false,
        onTap: onReject,
        expand: compact,
      ),
      _ActionChip(
        label: l10n.actionApprove,
        icon: Icons.check,
        fg: Colors.white,
        bg: const Color(0xFF000000),
        border: const Color(0xFF000000),
        filled: true,
        onTap: onApprove,
        expand: compact,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 8),
              Expanded(child: children[1]),
            ],
          ),
          const SizedBox(height: 8),
          children[2],
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.border,
    required this.filled,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color border;
  final bool filled;
  final VoidCallback onTap;
  final bool expand;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.filled && _hovered
                ? const Color(0xFF333333)
                : widget.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.border.withValues(
                alpha: widget.filled ? 0 : (_hovered ? 0.6 : 0.25),
              ),
            ),
          ),
          child: Row(
            mainAxisSize:
                widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 14, color: widget.fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.expand) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}
