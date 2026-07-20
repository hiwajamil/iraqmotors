import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/admin/domain/admin_audit_helper.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

/// Lists all showrooms registered in a given governorate with search and details actions.
class AdminShowroomListDetailScreen extends ConsumerStatefulWidget {
  const AdminShowroomListDetailScreen({super.key, required this.city});

  final String city;

  @override
  ConsumerState<AdminShowroomListDetailScreen> createState() =>
      _AdminShowroomListDetailScreenState();
}

class _AdminShowroomListDetailScreenState
    extends ConsumerState<AdminShowroomListDetailScreen> {
  late Future<List<Map<String, dynamic>>> _showroomsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _showroomsFuture = ref
        .read(adminDatabaseServiceProvider)
        .fetchShowroomsByCity(widget.city);
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
      _showroomsFuture = ref
          .read(adminDatabaseServiceProvider)
          .fetchShowroomsByCity(widget.city);
    });
  }

  void _showShowroomActionSheet(Map<String, dynamic> showroom) {
    final scheme = context.colorScheme;
    final uid = showroom['id']?.toString() ?? '';
    final name = showroom['showroomName']?.toString() ?? '—';
    final phone = showroom['phoneNumber']?.toString() ?? '—';
    final address = showroom['address']?.toString() ?? '—';
    final isBanned = showroom['isBanned'] == true;

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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSecondaryContainer,
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
                          address,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.person_outlined,
                  color: scheme.primary,
                ),
                title: const Text('Demote Showroom to Individual Account'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await ref
                        .read(adminDatabaseServiceProvider)
                        .updateUserAccountType(
                          userId: uid,
                          newType: 'individual',
                          audit: buildAdminAudit(
                            ref,
                            action: 'demote_showroom',
                            details: 'Demoted showroom $name ($uid) to individual',
                          ),
                        );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Demoted showroom to individual account.'),
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
                title: Text(isBanned ? 'Unban Showroom' : 'Ban Showroom'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await ref
                        .read(adminDatabaseServiceProvider)
                        .toggleUserBanStatus(
                          userId: uid,
                          isBanned: !isBanned,
                          audit: buildAdminAudit(
                            ref,
                            action: isBanned ? 'unban_showroom' : 'ban_showroom',
                            details: 'Toggled ban status for showroom $name ($uid)',
                          ),
                        );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBanned
                              ? 'Showroom unbanned successfully.'
                              : 'Showroom account banned.',
                        ),
                        backgroundColor:
                            isBanned ? AddCarTheme.success(context) : scheme.error,
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
                leading: const Icon(Icons.copy),
                title: const Text('Copy Contact Phone'),
                subtitle: Text(phone),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied phone number to clipboard'),
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
                hintText: 'Search showrooms by name or phone...',
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
              future: _showroomsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
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

                var showrooms = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  showrooms = showrooms.where((s) {
                    final name = s['showroomName']?.toString().toLowerCase() ?? '';
                    final phone = s['phoneNumber']?.toString().toLowerCase() ?? '';
                    final addr = s['address']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery) ||
                        phone.contains(_searchQuery) ||
                        addr.contains(_searchQuery);
                  }).toList();
                }

                if (showrooms.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.adminNoShowroomsInCity,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                  itemCount: showrooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = showrooms[index];
                    return _ShowroomListTile(
                      showroom: item,
                      onTap: () => _showShowroomActionSheet(item),
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

class _ShowroomListTile extends StatelessWidget {
  const _ShowroomListTile({required this.showroom, required this.onTap});

  final Map<String, dynamic> showroom;
  final VoidCallback onTap;

  String get _name => showroom['showroomName']?.toString() ?? '—';
  String get _phone => showroom['phoneNumber']?.toString() ?? '—';
  String get _address => showroom['address']?.toString() ?? '—';
  int get _adCount => showroom['adCount'] is int
      ? showroom['adCount'] as int
      : int.tryParse(showroom['adCount']?.toString() ?? '') ?? 0;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(_name),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _phone,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _address,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                      l10n.adminTotalAdCountLabel,
                      textAlign: TextAlign.end,
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
