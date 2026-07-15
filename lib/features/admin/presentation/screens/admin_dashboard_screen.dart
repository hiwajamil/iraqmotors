import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/utils/activity_actions.dart';
import 'package:iq_motors/features/admin/domain/admin_audit_helper.dart';
import 'package:iq_motors/core/utils/car_image_urls.dart';
import 'package:iq_motors/core/localization/filter_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/shared/models/account_type.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/auth/domain/models/user_profile.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';
import 'package:iq_motors/features/listings/presentation/add_car_review_summary.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/home_screen.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_activity_logs_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_approvals_by_city_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_car_management_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_flagged_ads_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_messages_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_reports_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_settings_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_showrooms_by_city_view.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_users_by_city_view.dart';

/// Platform super-admin dashboard — approvals queue, platform stats, sidebar.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

enum _SuperAdminNav {
  dashboard,
  approvals,
  users,
  showrooms,
  flagged,
  reports,
  messages,
  activity,
  carManagement,
  settings,
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  static const Color _bgMain = Color(0xFFF5F5F7);
  static const double _mobileBreakpoint = 992;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _SuperAdminNav _activeNav = _SuperAdminNav.dashboard;

  List<Map<String, dynamic>> _pendingAds = [];
  Map<String, UserProfile?> _sellerProfiles = {};
  bool _isLoadingPending = true;
  String? _pendingAdsError;
  final Set<String> _processingAdIds = {};
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchDashboardStats();
    _loadPendingAds();
  }

  Future<Map<String, int>> _fetchDashboardStats() {
    return ref.read(carDatabaseServiceProvider).fetchAdminDashboardStats();
  }

  void _refreshDashboardStats() {
    setState(() {
      _statsFuture = _fetchDashboardStats();
    });
  }

  Future<void> _loadPendingAds() async {
    setState(() {
      _isLoadingPending = true;
      _pendingAdsError = null;
    });
    try {
      final carDb = ref.read(carDatabaseServiceProvider);
      final auth = ref.read(authServiceProvider);
      final ads = await carDb.fetchPendingAds();

      final profiles = <String, UserProfile?>{};
      for (final ad in ads) {
        final sellerId = ad['sellerId']?.toString();
        if (sellerId == null || profiles.containsKey(sellerId)) continue;
        try {
          profiles[sellerId] = await auth.fetchProfile(sellerId);
        } catch (e) {
          debugPrint('Admin Fetch Error: $e');
          profiles[sellerId] = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingAds = ads;
        _sellerProfiles = profiles;
        _isLoadingPending = false;
        _pendingAdsError = null;
      });
    } catch (e) {
      debugPrint('Admin Fetch Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingPending = false;
        _pendingAdsError = e.toString();
      });
    }
  }

  List<_PendingApprovalData> _mapPendingAds(AppLocalizations l10n) {
    return _pendingAds.map((ad) {
      final sellerId = ad['sellerId']?.toString();
      final profile = sellerId != null ? _sellerProfiles[sellerId] : null;
      final isShowroom = profile?.accountType == AccountType.showroom;

      return _PendingApprovalData(
        id: ad['id']?.toString() ?? '',
        adData: ad,
        title: _carTitle(ad, l10n),
        price: _formatPrice(ad),
        imageUrls: _imageUrls(ad),
        publisherName: profile?.displayName ?? '—',
        publisherType: isShowroom ? 'showroom' : 'individual',
        publisherPhone: profile?.phone ?? '—',
        sellerProfile: profile,
      );
    }).toList();
  }

  String _carTitle(Map<String, dynamic> data, AppLocalizations l10n) {
    final languageCode = l10n.localeName.split('_').first;
    final brandId = data['brandId']?.toString();
    final modelKey = data['modelKey']?.toString();
    final year = data['year']?.toString();
    final trim = data['trim']?.toString();

    if (brandId != null) {
      for (final brand in dummyBrands) {
        if (brand.id == brandId) {
          final modelLabel = modelKey != null
              ? CarModelsByBrand.labelForModel(brand, modelKey, languageCode)
              : null;
          final brandName = brand.displayName(languageCode);
          final parts = [
            if (modelLabel != null) '$brandName $modelLabel' else brandName,
            if (year != null && year.isNotEmpty) year,
            if (trim != null && trim.isNotEmpty) trim,
          ];
          if (parts.isNotEmpty) return parts.join(' ');
          break;
        }
      }
    }

    final parts = [brandId, modelKey, year]
        .whereType<String>()
        .where((part) => part.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    return data['title']?.toString() ?? l10n.carFallbackTitle;
  }

  String _formatPrice(Map<String, dynamic> data) {
    final raw = data['priceValue'];
    if (raw == null) return '—';
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

  List<String> _imageUrls(Map<String, dynamic> data) => carImageUrlsFromAd(data);

  String _formatCount(int count) {
    return count.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  Future<bool> _approveAd(_PendingApprovalData data) async {
    if (data.id.isEmpty || _processingAdIds.contains(data.id)) return false;

    setState(() => _processingAdIds.add(data.id));
    try {
      await ref.read(carDatabaseServiceProvider).updateAdStatus(
            adId: data.id,
            newStatus: CarDatabaseService.statusActive,
            audit: buildAdminAudit(
              ref,
              action: ActivityActions.approvedAd,
              details: 'Ad ID: ${data.id}, Title: ${data.title}',
            ),
          );
      if (!mounted) return false;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminAdApprovedSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF34C759),
        ),
      );
      await _loadPendingAds();
      _refreshDashboardStats();
      return true;
    } on CarDatabaseException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _processingAdIds.remove(data.id));
      }
    }
  }

  Future<bool> _rejectAd(_PendingApprovalData data) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.adminRejectAdTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
          ),
        ),
        content: Text(
          l10n.adminRejectAdConfirm,
          style: const TextStyle(color: Color(0xFF86868B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: Text(l10n.actionReject),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;
    if (data.id.isEmpty || _processingAdIds.contains(data.id)) return false;

    setState(() => _processingAdIds.add(data.id));
    try {
      await ref.read(carDatabaseServiceProvider).updateAdStatus(
            adId: data.id,
            newStatus: CarDatabaseService.statusRejected,
            audit: buildAdminAudit(
              ref,
              action: ActivityActions.rejectedAd,
              details: 'Ad ID: ${data.id}, Title: ${data.title}',
            ),
          );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminAdRejectedSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadPendingAds();
      _refreshDashboardStats();
      return true;
    } on CarDatabaseException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _processingAdIds.remove(data.id));
      }
    }
  }

  Future<void> _viewAd(_PendingApprovalData data) async {
    debugPrint('Admin Dialog - Car image URLs: ${data.imageUrls}');
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => _PendingAdDetailDialog(
        data: data,
        onApprove: () => _approveAd(data),
        onReject: () => _rejectAd(data),
      ),
    );
  }

  List<_SuperAdminStatData> _buildStats(
    AppLocalizations l10n, {
    Map<String, int>? counts,
    bool isLoading = false,
  }) =>
      [
        _SuperAdminStatData(
          value: _formatCount(counts?['pendingAds'] ?? 0),
          label: l10n.statPendingApproval,
          icon: Icons.pending_actions_outlined,
          accentBg: const Color(0xFFFFF4E6),
          accentFg: const Color(0xFFFF9500),
          isLoading: isLoading,
        ),
        _SuperAdminStatData(
          value: _formatCount(counts?['totalUsers'] ?? 0),
          label: l10n.statTotalUsers,
          icon: Icons.people_outline,
          accentBg: const Color(0xFFE8F2FF),
          accentFg: const Color(0xFF007AFF),
          isLoading: isLoading,
        ),
        _SuperAdminStatData(
          value: _formatCount(counts?['activeAds'] ?? 0),
          label: l10n.statActiveListings,
          icon: Icons.directions_car_outlined,
          accentBg: const Color(0xFFE8F8ED),
          accentFg: const Color(0xFF34C759),
          isLoading: isLoading,
        ),
        _SuperAdminStatData(
          value: _formatCount(counts?['totalShowrooms'] ?? 0),
          label: l10n.statRegisteredShowrooms,
          icon: Icons.storefront_outlined,
          accentBg: const Color(0xFFF3EBFF),
          accentFg: const Color(0xFFAF52DE),
          isLoading: isLoading,
        ),
      ];

  void _onNavTap(_SuperAdminNav nav) {
    setState(() => _activeNav = nav);
    if (MediaQuery.sizeOf(context).width < _mobileBreakpoint) {
      _scaffoldKey.currentState?.closeDrawer();
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
                  pendingCount: _pendingAds.length,
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
                    pendingCount: _pendingAds.length,
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
    final padding = EdgeInsetsDirectional.fromSTEB(
      isMobile ? 20 : _horizontalPadding(context),
      isMobile ? 20 : 40,
      isMobile ? 20 : _horizontalPadding(context),
      40,
    );

    if (_activeNav == _SuperAdminNav.activity ||
        _activeNav == _SuperAdminNav.messages ||
        _activeNav == _SuperAdminNav.carManagement) {
      return Padding(
        padding: padding,
        child: switch (_activeNav) {
          _SuperAdminNav.activity =>
            AdminActivityLogsView(isMobile: isMobile),
          _SuperAdminNav.messages => AdminMessagesView(isMobile: isMobile),
          _SuperAdminNav.carManagement =>
            AdminCarManagementView(isMobile: isMobile),
          _ => const SizedBox.shrink(),
        },
      );
    }

    return SingleChildScrollView(
      padding: padding,
      child: switch (_activeNav) {
        _SuperAdminNav.dashboard => _buildDashboardHome(isMobile: isMobile),
        _SuperAdminNav.approvals => AdminApprovalsByCityView(
            isMobile: isMobile,
            horizontalPadding: _horizontalPadding(context),
          ),
        _SuperAdminNav.users => AdminUsersByCityView(isMobile: isMobile),
        _SuperAdminNav.showrooms =>
          AdminShowroomsByCityView(isMobile: isMobile),
        _SuperAdminNav.flagged => AdminFlaggedAdsView(isMobile: isMobile),
        _SuperAdminNav.reports => AdminReportsView(isMobile: isMobile),
        _SuperAdminNav.settings => AdminSettingsView(isMobile: isMobile),
        _SuperAdminNav.messages => const SizedBox.shrink(),
        _SuperAdminNav.activity => const SizedBox.shrink(),
        _SuperAdminNav.carManagement => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildDashboardHome({required bool isMobile}) {
    final l10n = context.l10n;
    final adminName = l10n.superAdminTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SuperAdminHeader(isMobile: isMobile, adminName: adminName),
        const SizedBox(height: 32),
        FutureBuilder<Map<String, int>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final counts = snapshot.hasError ? null : snapshot.data;
            final statsError = snapshot.hasError ? snapshot.error.toString() : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SuperAdminStatsGrid(
                  stats: _buildStats(
                    l10n,
                    counts: counts,
                    isLoading: isLoading,
                  ),
                  isMobile: isMobile,
                ),
                if (statsError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    statsError,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 40),
        _PendingApprovalsSection(
          approvals: _mapPendingAds(l10n),
          isLoading: _isLoadingPending,
          errorMessage: _pendingAdsError,
          processingIds: _processingAdIds,
          isMobile: isMobile,
          onView: _viewAd,
          onReject: _rejectAd,
          onApprove: _approveAd,
        ),
      ],
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
    this.isLoading = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accentBg;
  final Color accentFg;
  final bool isLoading;
}

class _PendingApprovalData {
  const _PendingApprovalData({
    required this.id,
    required this.adData,
    required this.title,
    required this.price,
    required this.imageUrls,
    required this.publisherName,
    required this.publisherType,
    required this.publisherPhone,
    this.sellerProfile,
  });

  final String id;
  final Map<String, dynamic> adData;
  final String title;
  final String price;
  final List<String> imageUrls;
  final String publisherName;
  final String publisherType;
  final String publisherPhone;
  final UserProfile? sellerProfile;
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
    required this.pendingCount,
    required this.onNavTap,
    required this.onLogout,
  });

  final bool isCompact;
  final _SuperAdminNav activeNav;
  final int pendingCount;
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
            pendingCount: pendingCount,
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
    required this.pendingCount,
    required this.onNavTap,
  });

  final _SuperAdminNav activeNav;
  final int pendingCount;
  final ValueChanged<_SuperAdminNav> onNavTap;

  static const List<_SuperAdminNavItemConfig> _itemConfigs = [
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.dashboard,
      icon: Icons.dashboard_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.approvals,
      icon: Icons.fact_check_outlined,
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
      nav: _SuperAdminNav.flagged,
      icon: Icons.flag_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.reports,
      icon: Icons.analytics_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.messages,
      icon: Icons.support_agent_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.activity,
      icon: Icons.history_outlined,
    ),
    _SuperAdminNavItemConfig(
      nav: _SuperAdminNav.carManagement,
      icon: Icons.directions_car_outlined,
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
      _SuperAdminNav.flagged => l10n.navFlaggedAds,
      _SuperAdminNav.reports => l10n.navReports,
      _SuperAdminNav.messages => l10n.adminMessagesTitle,
      _SuperAdminNav.activity => l10n.navActivity,
      _SuperAdminNav.carManagement => l10n.navCarManagement,
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
            badgeCount: config.nav == _SuperAdminNav.approvals && pendingCount > 0
                ? pendingCount
                : null,
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
  });

  final _SuperAdminNav nav;
  final IconData icon;
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
                if (data.isLoading)
                  const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
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
    required this.isLoading,
    this.errorMessage,
    required this.processingIds,
    required this.isMobile,
    required this.onView,
    required this.onReject,
    required this.onApprove,
  });

  final List<_PendingApprovalData> approvals;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> processingIds;
  final bool isMobile;
  final ValueChanged<_PendingApprovalData> onView;
  final ValueChanged<_PendingApprovalData> onReject;
  final ValueChanged<_PendingApprovalData> onApprove;

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
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF3B30),
                ),
              ),
            )
          else if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (approvals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                l10n.adminNoPendingListings,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                ),
              ),
            )
          else ...[
            if (!isMobile) const _ApprovalsTableHeader(),
            if (!isMobile) const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: approvals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = approvals[index];
                final isProcessing = processingIds.contains(item.id);
                return _PendingApprovalRow(
                  data: item,
                  isMobile: isMobile,
                  isProcessing: isProcessing,
                  onView: () => onView(item),
                  onReject: () => onReject(item),
                  onApprove: () => onApprove(item),
                );
              },
            ),
          ],
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

    return _ApprovalsRowLayout(
      isHeader: true,
      car: _HeaderCell(l10n.tableCar),
      publisher: _HeaderCell(l10n.tablePublisher),
      price: _HeaderCell(l10n.tablePrice),
      actions: _HeaderCell(l10n.tableActions),
    );
  }
}

class _ApprovalsRowLayout extends StatelessWidget {
  const _ApprovalsRowLayout({
    required this.car,
    required this.publisher,
    required this.price,
    required this.actions,
    this.isHeader = false,
  });

  final Widget car;
  final Widget publisher;
  final Widget price;
  final Widget actions;
  final bool isHeader;

  static const double _horizontalPadding = 12;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        _horizontalPadding,
        isHeader ? 0 : 14,
        _horizontalPadding,
        isHeader ? 4 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: car),
          Expanded(flex: 3, child: publisher),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: price,
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: actions,
            ),
          ),
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
    required this.isProcessing,
    required this.onView,
    required this.onReject,
    required this.onApprove,
  });

  final _PendingApprovalData data;
  final bool isMobile;
  final bool isProcessing;
  final VoidCallback onView;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _PendingApprovalCard(
        data: data,
        isProcessing: isProcessing,
        onView: onView,
        onReject: onReject,
        onApprove: onApprove,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: _ApprovalsRowLayout(
        car: _CarCell(data: data),
        publisher: _PublisherCell(data: data),
        price: Text(
          data.price,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        actions: _ApprovalActions(
          onView: onView,
          onReject: onReject,
          onApprove: onApprove,
          isProcessing: isProcessing,
          compact: false,
        ),
      ),
    );
  }
}

class _PendingApprovalCard extends StatelessWidget {
  const _PendingApprovalCard({
    required this.data,
    required this.isProcessing,
    required this.onView,
    required this.onReject,
    required this.onApprove,
  });

  final _PendingApprovalData data;
  final bool isProcessing;
  final VoidCallback onView;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
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
            isProcessing: isProcessing,
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
        _CarThumbnailRow(urls: data.imageUrls),
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

class _CarThumbnailRow extends StatelessWidget {
  const _CarThumbnailRow({required this.urls});

  final List<String> urls;

  static const double _size = 45;
  static const double _radius = 10;

  @override
  Widget build(BuildContext context) {
    final previews = urls.take(4).toList();
    if (previews.isEmpty) {
      return _placeholder();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < previews.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: SizedBox(
              width: _size,
              height: _size,
              child: CarNetworkImage(
                imageUrl: previews[i],
                fit: BoxFit.cover,
                cacheLogicalWidth: _size,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        width: _size,
        height: _size,
        color: const Color(0xFFE5E5EA),
        child: const Icon(
          Icons.directions_car_outlined,
          size: 20,
          color: Color(0xFF86868B),
        ),
      ),
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
    this.isProcessing = false,
  });

  final VoidCallback onView;
  final VoidCallback onReject;
  final VoidCallback onApprove;
  final bool compact;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final children = [
      _ActionChip(
        label: l10n.actionView,
        icon: Icons.visibility_outlined,
        fg: const Color(0xFF007AFF),
        bg: const Color(0xFFE6F0FF),
        border: const Color(0xFF007AFF),
        filled: false,
        onTap: isProcessing ? null : onView,
        expand: compact,
      ),
      _ActionChip(
        label: l10n.actionReject,
        icon: Icons.close,
        fg: const Color(0xFFFF3B30),
        bg: Colors.white,
        border: const Color(0xFFFF3B30),
        filled: false,
        onTap: isProcessing ? null : onReject,
        expand: compact,
      ),
      _ActionChip(
        label: l10n.actionApprove,
        icon: Icons.check,
        fg: Colors.white,
        bg: const Color(0xFF1D1D1F),
        border: const Color(0xFF1D1D1F),
        filled: true,
        isLoading: isProcessing,
        onTap: isProcessing ? null : onApprove,
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
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color border;
  final bool filled;
  final VoidCallback? onTap;
  final bool expand;
  final bool isLoading;

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
              if (widget.isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.fg,
                  ),
                )
              else ...[
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

class _PendingAdDetailDialog extends StatefulWidget {
  const _PendingAdDetailDialog({
    required this.data,
    required this.onApprove,
    required this.onReject,
  });

  final _PendingApprovalData data;
  final Future<bool> Function() onApprove;
  final Future<bool> Function() onReject;

  @override
  State<_PendingAdDetailDialog> createState() => _PendingAdDetailDialogState();
}

class _PendingAdDetailDialogState extends State<_PendingAdDetailDialog> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _divider = Color(0xFFE5E5EA);

  late final PageController _pageController;
  int _currentPage = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  AddCarDraft get _draft => AddCarDraft.fromFirestoreMap(widget.data.adData);

  Future<void> _handleApprove() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final success = await widget.onApprove();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (success) Navigator.of(context).pop();
  }

  Future<void> _handleReject() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final success = await widget.onReject();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final sections = AddCarReviewSummary.build(l10n, _draft);
    final profile = widget.data.sellerProfile;
    final imageUrls = carImageUrlsFromAd(widget.data.adData);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.actionView,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DetailImageCarousel(
                          urls: imageUrls,
                          pageController: _pageController,
                          currentPage: _currentPage,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.data.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.data.price,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        if (profile != null) ...[
                          const SizedBox(height: 16),
                          _DetailPublisherRow(
                            name: profile.displayName,
                            phone: profile.phone,
                            isShowroom:
                                profile.accountType == AccountType.showroom,
                          ),
                        ],
                        const SizedBox(height: 16),
                        for (final section in sections) ...[
                          _DetailSectionBlock(section: section),
                          const SizedBox(height: 10),
                        ],
                        if (_draft.description != null &&
                            _draft.description!.trim().isNotEmpty) ...[
                          _DetailDescriptionBlock(
                            label: l10n.adminDescriptionLabel,
                            text: _draft.description!,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DetailActionButton(
                          label: l10n.actionReject,
                          fg: const Color(0xFFFF3B30),
                          bg: Colors.white,
                          border: const Color(0xFFFF3B30),
                          isLoading: _isProcessing,
                          onTap: _handleReject,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailActionButton(
                          label: l10n.actionApprove,
                          fg: Colors.white,
                          bg: const Color(0xFF1D1D1F),
                          border: const Color(0xFF1D1D1F),
                          filled: true,
                          isLoading: _isProcessing,
                          onTap: _handleApprove,
                        ),
                      ),
                    ],
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

class _DetailImageCarousel extends StatelessWidget {
  const _DetailImageCarousel({
    required this.urls,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<String> urls;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return _emptyImagePlaceholder();
    }

    const pageAnimationDuration = Duration(milliseconds: 300);
    final showLeftArrow = urls.length > 1 && currentPage > 0;
    final showRightArrow = urls.length > 1 && currentPage < urls.length - 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: urls.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    final url = urls[index];
                    return SizedBox.expand(
                      child: CarNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: _PendingAdDetailDialogState._divider,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: _PendingAdDetailDialogState._divider,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: _PendingAdDetailDialogState._textSecondary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (showLeftArrow)
                  PositionedDirectional(
                    start: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselNavButton(
                        icon: Icons.chevron_left,
                        onPressed: () => pageController.previousPage(
                          duration: pageAnimationDuration,
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                if (showRightArrow)
                  PositionedDirectional(
                    end: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselNavButton(
                        icon: Icons.chevron_right,
                        onPressed: () => pageController.nextPage(
                          duration: pageAnimationDuration,
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < urls.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentPage == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: currentPage == i
                        ? _PendingAdDetailDialogState._textPrimary
                        : _PendingAdDetailDialogState._divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _emptyImagePlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          color: _PendingAdDetailDialogState._divider,
          alignment: Alignment.center,
          child: const Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: _PendingAdDetailDialogState._textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CarouselNavButton extends StatelessWidget {
  const _CarouselNavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 32, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(44, 44),
        ),
        tooltip: '',
      ),
    );
  }
}

class _DetailPublisherRow extends StatelessWidget {
  const _DetailPublisherRow({
    required this.name,
    required this.phone,
    required this.isShowroom,
  });

  final String name;
  final String phone;
  final bool isShowroom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isShowroom
                  ? const Color(0xFFF3EBFF)
                  : const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isShowroom ? Icons.storefront_outlined : Icons.person_outline,
              size: 20,
              color: isShowroom
                  ? const Color(0xFFAF52DE)
                  : const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _PendingAdDetailDialogState._textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _PendingAdDetailDialogState._textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionBlock extends StatelessWidget {
  const _DetailSectionBlock({required this.section});

  final AddCarReviewSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _PendingAdDetailDialogState._textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < section.rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    section.rows[i].label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _PendingAdDetailDialogState._textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    section.rows[i].value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _PendingAdDetailDialogState._textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailDescriptionBlock extends StatelessWidget {
  const _DetailDescriptionBlock({
    required this.label,
    required this.text,
  });

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _PendingAdDetailDialogState._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _PendingAdDetailDialogState._textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
    required this.onTap,
    this.filled = false,
    this.isLoading = false,
  });

  final String label;
  final Color fg;
  final Color bg;
  final Color border;
  final bool filled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: filled ? Colors.white : fg,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
      ),
    );
  }
}
