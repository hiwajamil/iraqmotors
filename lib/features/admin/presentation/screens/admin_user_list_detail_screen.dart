import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/filter_l10n.dart';
import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/admin/domain/admin_audit_helper.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';

/// Lists all users registered in a given governorate with search & management controls.
class AdminUserListDetailScreen extends ConsumerStatefulWidget {
  const AdminUserListDetailScreen({super.key, required this.city});

  final String city;

  @override
  ConsumerState<AdminUserListDetailScreen> createState() =>
      _AdminUserListDetailScreenState();
}

class _AdminUserListDetailScreenState
    extends ConsumerState<AdminUserListDetailScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _usersFuture =
        ref.read(adminDatabaseServiceProvider).fetchUsersByCity(widget.city);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _usersFuture =
          ref.read(adminDatabaseServiceProvider).fetchUsersByCity(widget.city);
    });
  }

  void _showUserActionSheet(Map<String, dynamic> user) {
    final scheme = context.colorScheme;
    final uid = user['id']?.toString() ?? '';
    final name = user['fullName']?.toString() ?? '—';
    final phone = user['phoneNumber']?.toString() ?? '—';
    final currentType = user['userType']?.toString() ?? 'individual';
    final isBanned = user['isBanned'] == true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          phone,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isBanned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Banned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: Icon(
                  currentType == 'showroom'
                      ? Icons.person_outlined
                      : Icons.storefront_outlined,
                  color: scheme.primary,
                ),
                title: Text(
                  currentType == 'showroom'
                      ? 'Demote to Individual Account'
                      : 'Promote to Showroom Account',
                ),
                subtitle: Text(
                  'Current role: ${currentType.toUpperCase()}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final nextType =
                      currentType == 'showroom' ? 'individual' : 'showroom';
                  try {
                    await ref
                        .read(adminDatabaseServiceProvider)
                        .updateUserAccountType(
                          userId: uid,
                          newType: nextType,
                          audit: buildAdminAudit(
                            ref,
                            action: 'update_user_role',
                            details: 'Changed role for user $uid to $nextType',
                          ),
                        );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated user role to $nextType'),
                        backgroundColor: AddCarTheme.success(context),
                      ),
                    );
                    _reload();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: scheme.error,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  isBanned ? Icons.check_circle_outline : Icons.block,
                  color: isBanned ? AddCarTheme.success(context) : scheme.error,
                ),
                title: Text(isBanned ? 'Unban Account' : 'Ban Account'),
                subtitle: Text(
                  isBanned
                      ? 'Restore platform access for user'
                      : 'Suspend user access to listing services',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (!isBanned) {
                    final reasonCtrl = TextEditingController();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Ban Account'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Please specify the reason for banning this user account:',
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: reasonCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Reason (e.g. Fraudulent listings)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                            ),
                            child: const Text('Ban User'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    try {
                      await ref
                          .read(adminDatabaseServiceProvider)
                          .toggleUserBanStatus(
                            userId: uid,
                            isBanned: true,
                            reason: reasonCtrl.text.trim(),
                            audit: buildAdminAudit(
                              ref,
                              action: 'ban_user',
                              details: 'Banned user $uid: ${reasonCtrl.text.trim()}',
                            ),
                          );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('User account banned.'),
                          backgroundColor: scheme.error,
                        ),
                      );
                      _reload();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: scheme.error,
                        ),
                      );
                    }
                  } else {
                    try {
                      await ref
                          .read(adminDatabaseServiceProvider)
                          .toggleUserBanStatus(
                            userId: uid,
                            isBanned: false,
                            audit: buildAdminAudit(
                              ref,
                              action: 'unban_user',
                              details: 'Unbanned user $uid',
                            ),
                          );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('User account unbanned.'),
                          backgroundColor: AddCarTheme.success(context),
                        ),
                      );
                      _reload();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: scheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy User ID'),
                subtitle: Text(
                  uid,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: uid));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied User ID to clipboard'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: scheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          IraqLocationL10n.provinceLabel(l10n, widget.city),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingCenter();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _reload,
                            child: Text(l10n.adminRetry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var users = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) {
                    final name = u['fullName']?.toString().toLowerCase() ?? '';
                    final phone = u['phoneNumber']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery) ||
                        phone.contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.adminNoUsersInCity,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return _UserListTile(
                      user: u,
                      onTap: () => _showUserActionSheet(u),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.user, required this.onTap});

  final Map<String, dynamic> user;
  final VoidCallback onTap;

  String get _name => user['fullName']?.toString() ?? '—';
  String get _phone => user['phoneNumber']?.toString() ?? '—';
  String get _userType => user['userType']?.toString() ?? 'individual';
  bool get _isBanned => user['isBanned'] == true;
  int get _adCount => user['activeAdCount'] is int
      ? user['activeAdCount'] as int
      : int.tryParse(user['activeAdCount']?.toString() ?? '') ?? 0;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first == '—') return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final isShowroom = _userType == 'showroom';
    final typeLabel = FilterL10n.publisherTypeLabel(l10n, _userType);
    final accentBg = isShowroom ? scheme.secondaryContainer : scheme.primaryContainer;
    final accentFg = isShowroom ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isBanned ? scheme.error.withAlpha(120) : scheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _isBanned ? scheme.errorContainer : accentBg,
                  child: Text(
                    _initials(_name),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isBanned ? scheme.onErrorContainer : accentFg,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (_isBanned)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Banned',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accentBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_adCount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.adminActiveAdCountLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
