import 'package:flutter/material.dart';

import '../core/iraq_location_l10n.dart';
import '../core/l10n_extensions.dart';
import '../data/iraq_locations.dart';
import '../views/add_car/add_car_theme.dart';
import '../views/add_car/widgets/add_car_form_card.dart';

/// Dependent governorate → city pickers backed by [IraqLocations.iraqLocations].
class IraqLocationDropdowns extends StatelessWidget {
  const IraqLocationDropdowns({
    super.key,
    required this.province,
    required this.city,
    required this.onProvinceChanged,
    required this.onCityChanged,
    this.provinceLabel,
    this.cityLabel,
    this.provincePlaceholder,
    this.cityPlaceholder,
  });

  final String? province;
  final String? city;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String> onCityChanged;
  final String? provinceLabel;
  final String? cityLabel;
  final String? provincePlaceholder;
  final String? cityPlaceholder;

  List<String> get _cities =>
      province == null ? const [] : IraqLocations.citiesForProvince(province!);

  Future<void> _openPicker(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
    required String Function(String option) labelForOption,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AddCarTheme.cardBg,
      shape: AddCarTheme.bottomSheetShape,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: AddCarTheme.sectionLabel),
              ),
              const Divider(height: 1, color: AddCarTheme.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return ListTile(
                      title: Text(
                        labelForOption(option),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: AddCarTheme.textPrimary,
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
    final l10n = context.l10n;
    final resolvedProvinceLabel = provinceLabel ?? l10n.addCarProvinceLabel;
    final resolvedCityLabel = cityLabel ?? l10n.addCarAreaLabel;
    final resolvedProvincePlaceholder =
        provincePlaceholder ?? l10n.addCarProvincePlaceholder;
    final resolvedCityPlaceholder =
        cityPlaceholder ?? l10n.addCarAreaPlaceholder;
    final cityEnabled = province != null;

    return AddCarFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocationField(
            label: resolvedProvinceLabel,
            value: province == null
                ? null
                : IraqLocationL10n.provinceLabel(l10n, province!),
            placeholder: resolvedProvincePlaceholder,
            enabled: true,
            onTap: () => _openPicker(
              context,
              title: resolvedProvinceLabel,
              options: IraqLocations.provinceOrder,
              selected: province,
              onSelected: onProvinceChanged,
              labelForOption: (option) =>
                  IraqLocationL10n.provinceLabel(l10n, option),
            ),
          ),
          const SizedBox(height: 16),
          _LocationField(
            label: resolvedCityLabel,
            value: city == null
                ? null
                : IraqLocationL10n.cityLabel(l10n, city!),
            placeholder: resolvedCityPlaceholder,
            enabled: cityEnabled,
            onTap: cityEnabled
                ? () => _openPicker(
                      context,
                      title: resolvedCityLabel,
                      options: _cities,
                      selected: city,
                      onSelected: onCityChanged,
                      labelForOption: (option) => IraqLocationL10n.cityLabel(
                        l10n,
                        option,
                      ),
                    )
                : null,
          ),
        ],
      ),
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
        ? (hasValue ? AddCarTheme.textPrimary : AddCarTheme.textSecondary)
        : AddCarTheme.textSecondary.withValues(alpha: 0.45);

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
          decoration: AddCarTheme.inputDecorationBox(
            focused: _pressed,
            enabled: widget.enabled,
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
                        color: AddCarTheme.textSecondary,
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
