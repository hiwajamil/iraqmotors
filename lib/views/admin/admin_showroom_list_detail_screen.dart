import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/iraq_location_l10n.dart';
import '../../core/l10n_extensions.dart';
import '../../providers/storage_providers.dart';

/// Lists all showrooms registered in a given governorate.
class AdminShowroomListDetailScreen extends ConsumerStatefulWidget {
  const AdminShowroomListDetailScreen({super.key, required this.city});

  final String city;

  @override
  ConsumerState<AdminShowroomListDetailScreen> createState() =>
      _AdminShowroomListDetailScreenState();
}

class _AdminShowroomListDetailScreenState
    extends ConsumerState<AdminShowroomListDetailScreen> {
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  late Future<List<Map<String, dynamic>>> _showroomsFuture;

  @override
  void initState() {
    super.initState();
    _showroomsFuture = ref
        .read(adminDatabaseServiceProvider)
        .fetchShowroomsByCity(widget.city);
  }

  void _reload() {
    setState(() {
      _showroomsFuture = ref
          .read(adminDatabaseServiceProvider)
          .fetchShowroomsByCity(widget.city);
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
                      style: const TextStyle(color: _textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _reload, child: Text(l10n.adminRetry)),
                  ],
                ),
              ),
            );
          }

          final showrooms = snapshot.data ?? [];

          if (showrooms.isEmpty) {
            return Center(
              child: Text(
                l10n.adminNoShowroomsInCity,
                style: const TextStyle(fontSize: 14, color: _textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
            itemCount: showrooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _ShowroomListTile(showroom: showrooms[index]);
            },
          );
        },
      ),
    );
  }
}

class _ShowroomListTile extends StatelessWidget {
  const _ShowroomListTile({required this.showroom});

  final Map<String, dynamic> showroom;

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _accentPurple = Color(0xFFAF52DE);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(_name),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _accentPurple,
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _phone,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.adminTotalAdCountLabel,
                      textAlign: TextAlign.end,
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
