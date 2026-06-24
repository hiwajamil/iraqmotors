import 'package:flutter/material.dart';

/// Centered desktop-style picker for filter dropdowns (year, price, etc.).
class FilterOptionPickerDialog {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> optionKeys,
    required String Function(String key) resolveLabel,
    required String? valueKey,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _OptionPickerBody(
            title: title,
            optionKeys: optionKeys,
            resolveLabel: resolveLabel,
            valueKey: valueKey,
          ),
        ),
      ),
    );
  }

  static Future<String?> showSearchable(
    BuildContext context, {
    required String title,
    required String searchHint,
    required List<String> optionKeys,
    required String Function(String key) resolveLabel,
    required String? valueKey,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: _SearchablePickerBody(
            title: title,
            searchHint: searchHint,
            optionKeys: optionKeys,
            resolveLabel: resolveLabel,
            valueKey: valueKey,
          ),
        ),
      ),
    );
  }
}

class _OptionPickerBody extends StatelessWidget {
  const _OptionPickerBody({
    required this.title,
    required this.optionKeys,
    required this.resolveLabel,
    required this.valueKey,
  });

  final String title;
  final List<String> optionKeys;
  final String Function(String key) resolveLabel;
  final String? valueKey;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: FilterOptionPickerDialog._textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 22),
                color: FilterOptionPickerDialog._textSecondary,
                splashRadius: 20,
              ),
            ],
          ),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              itemCount: optionKeys.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final key = optionKeys[index];
                final selected =
                    valueKey == key || (valueKey == null && index == 0);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    resolveLabel(key),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: FilterOptionPickerDialog._textPrimary,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: FilterOptionPickerDialog._textPrimary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, key),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchablePickerBody extends StatefulWidget {
  const _SearchablePickerBody({
    required this.title,
    required this.searchHint,
    required this.optionKeys,
    required this.resolveLabel,
    required this.valueKey,
  });

  final String title;
  final String searchHint;
  final List<String> optionKeys;
  final String Function(String key) resolveLabel;
  final String? valueKey;

  @override
  State<_SearchablePickerBody> createState() => _SearchablePickerBodyState();
}

class _SearchablePickerBodyState extends State<_SearchablePickerBody> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.trim().isEmpty) return widget.optionKeys;
    final q = _query.trim().toLowerCase();
    return widget.optionKeys
        .where((k) => widget.resolveLabel(k).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: FilterOptionPickerDialog._textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 22),
                color: FilterOptionPickerDialog._textSecondary,
                splashRadius: 20,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: TextStyle(
                color: FilterOptionPickerDialog._textSecondary.withValues(
                  alpha: 0.8,
                ),
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            itemBuilder: (context, index) {
              final key = _filtered[index];
              final selected = widget.valueKey == key;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  widget.resolveLabel(key),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    color: FilterOptionPickerDialog._textPrimary,
                  ),
                ),
                trailing: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: FilterOptionPickerDialog._textPrimary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, key),
              );
            },
          ),
        ),
      ],
    );
  }
}
