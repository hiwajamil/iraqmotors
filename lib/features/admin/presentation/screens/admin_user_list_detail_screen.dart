import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/filter_l10n.dart';
import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

/// Lists all users registered in a given governorate.
class AdminUserListDetailScreen extends ConsumerStatefulWidget {
  const AdminUserListDetailScreen({super.key, required this.city});

  final String city;

  @override
  ConsumerState<AdminUserListDetailScreen> createState() =>
      _AdminUserListDetailScreenState();
}

class _AdminUserListDetailScreenState
    extends ConsumerState<AdminUserListDetailScreen> {
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture =
        ref.read(adminDatabaseServiceProvider).fetchUsersByCity(widget.city);
  }

  void _reload() {
    setState(() {
      _usersFuture =
          ref.read(adminDatabaseServiceProvider).fetchUsersByCity(widget.city);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: _textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          IraqLocationL10n.provinceLabel(l10n, widget.city),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
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
                      style: const TextStyle(color: _textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _reload, child: Text(l10n.adminRetry)),
                  ],
                ),
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(
                l10n.adminNoUsersInCity,
                style: const TextStyle(fontSize: 14, color: _textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _UserListTile(user: users[index]);
            },
          );
        },
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.user});

  final Map<String, dynamic> user;

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  String get _name => user['fullName']?.toString() ?? '—';
  String get _phone => user['phoneNumber']?.toString() ?? '—';
  String get _userType => user['userType']?.toString() ?? 'individual';
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
    final isShowroom = _userType == 'showroom';
    final typeLabel = FilterL10n.publisherTypeLabel(l10n, _userType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isShowroom
                      ? const Color(0xFFF3EBFF)
                      : const Color(0xFFE8F2FF),
                  child: Text(
                    _initials(_name),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isShowroom
                          ? const Color(0xFFAF52DE)
                          : const Color(0xFF007AFF),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phone,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.adminActiveAdCountLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
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
