import 'package:flutter/material.dart';

import '../data/iraq_locations.dart';

/// Dependent governorate → city pickers backed by [IraqLocations.iraqLocations].
class IraqLocationDropdowns extends StatelessWidget {
  const IraqLocationDropdowns({
    super.key,
    required this.province,
    required this.city,
    required this.onProvinceChanged,
    required this.onCityChanged,
    this.provinceLabel = 'پارێزگا',
    this.cityLabel = 'ناوچە / شار',
    this.provincePlaceholder = 'پارێزگا هەڵبژێرە',
    this.cityPlaceholder = 'ناوچە هەڵبژێرە',
  });

  final String? province;
  final String? city;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String> onCityChanged;
  final String provinceLabel;
  final String cityLabel;
  final String provincePlaceholder;
  final String cityPlaceholder;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  List<String> get _cities =>
      province == null ? const [] : IraqLocations.citiesForProvince(province!);

  Future<void> _openPicker(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: _textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, option),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final cityEnabled = province != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LocationField(
          label: provinceLabel,
          value: province,
          placeholder: provincePlaceholder,
          enabled: true,
          onTap: () => _openPicker(
            context,
            title: provinceLabel,
            options: IraqLocations.provinceOrder,
            selected: province,
            onSelected: onProvinceChanged,
          ),
        ),
        const SizedBox(height: 16),
        _LocationField(
          label: cityLabel,
          value: city,
          placeholder: cityPlaceholder,
          enabled: cityEnabled,
          onTap: cityEnabled
              ? () => _openPicker(
                    context,
                    title: cityLabel,
                    options: _cities,
                    selected: city,
                    onSelected: onCityChanged,
                  )
              : null,
        ),
      ],
    );
  }
}

class _LocationField extends StatefulWidget {
  const _LocationField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final textColor = widget.enabled
        ? (hasValue
            ? IraqLocationDropdowns._textPrimary
            : IraqLocationDropdowns._textSecondary)
        : IraqLocationDropdowns._textSecondary.withValues(alpha: 0.45);

    return GestureDetector(
      onTapDown: widget.enabled && widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.enabled && widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onTapCancel: widget.enabled && widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: IraqLocationDropdowns._textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.value ?? widget.placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
