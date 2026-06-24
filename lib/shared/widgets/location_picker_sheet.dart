import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/filter_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';

/// Multi-select location picker — search, checkboxes, Apply.
Future<Set<String>?> showLocationPickerSheet(
  BuildContext context, {
  required Set<String> initialSelection,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LocationPickerSheet(initialSelection: initialSelection),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.initialSelection});

  final Set<String> initialSelection;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _fill = Color(0xFFE8E8ED);
  static const Color _accent = Color(0xFF1D1D1F);

  late Set<String> _draft;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _draft = _normalize(widget.initialSelection);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<String> _normalize(Set<String> keys) {
    if (LocationKeys.isAllCountry(keys)) {
      return {LocationKeys.allCities};
    }
    return Set<String>.from(
      keys.where((k) => k != LocationKeys.allCities),
    );
  }

  bool _isAllSelected() => LocationKeys.isAllCountry(_draft);

  bool _isChecked(String key) {
    if (key == LocationKeys.allCities) {
      return _isAllSelected();
    }
    if (_isAllSelected()) {
      return true;
    }
    return _draft.contains(key);
  }

  void _toggle(String key) {
    setState(() {
      if (key == LocationKeys.allCities) {
        if (_isAllSelected()) {
          _draft = {};
        } else {
          _draft = {LocationKeys.allCities};
        }
        return;
      }

      if (_draft.contains(LocationKeys.allCities)) {
        _draft = Set<String>.from(LocationKeys.governorateKeys)..remove(key);
        return;
      }

      final next = Set<String>.from(_draft);

      if (next.contains(key)) {
        next.remove(key);
      } else {
        next.add(key);
        if (next.length == LocationKeys.governorateKeys.length) {
          _draft = {LocationKeys.allCities};
          return;
        }
      }
      _draft = next;
    });
  }

  List<String> get _visibleKeys {
    final l10n = context.l10n;
    if (_query.isEmpty) return LocationKeys.pickerOrder;

    return LocationKeys.pickerOrder.where((key) {
      final label = FilterL10n.locationLabel(l10n, key).toLowerCase();
      return label.contains(_query);
    }).toList();
  }

  Set<String> _appliedSelection() {
    if (_draft.contains(LocationKeys.allCities) || _draft.isEmpty) {
      return {LocationKeys.allCities};
    }
    return Set<String>.from(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _fill,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      l10n.selectCity,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SearchField(
                      controller: _searchController,
                      hint: l10n.locationSearch,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE5E5EA)),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _visibleKeys.length,
                      itemBuilder: (context, index) {
                        final key = _visibleKeys[index];
                        return _LocationCheckRow(
                          label: FilterL10n.locationLabel(l10n, key),
                          checked: _isChecked(key),
                          onChanged: () => _toggle(key),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E5EA)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, _appliedSelection()),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.locationApply,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF86868B),
          fontSize: 16,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF86868B),
          size: 22,
        ),
        filled: true,
        fillColor: const Color(0xFFE8E8ED),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1D1D1F),
      ),
    );
  }
}

class _LocationCheckRow extends StatelessWidget {
  const _LocationCheckRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: (_) => onChanged(),
              activeColor: const Color(0xFF1D1D1F),
              side: const BorderSide(color: Color(0xFFC7C7CC), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
