import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_form_card.dart';

/// M3 selectable chip used in the add-car wizard.
class AddCarSelectChip extends StatelessWidget {
  const AddCarSelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDropdownIcon = false,
    this.fullWidth = false,
    this.square = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDropdownIcon;
  final bool fullWidth;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    final labelChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
          ),
        ),
        if (showDropdownIcon) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ],
      ],
    );

    final chip = FilterChip(
      label: labelChild,
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: scheme.secondaryContainer,
      backgroundColor: scheme.surfaceContainerHighest,
      side: BorderSide(
        color: selected ? scheme.secondaryContainer : scheme.outlineVariant,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: square ? 4 : 8,
        vertical: 4,
      ),
      labelPadding: EdgeInsets.symmetric(
        horizontal: square ? 4 : 4,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: chip);
    }
    if (square) {
      return SizedBox(width: 52, height: 48, child: chip);
    }
    return chip;
  }
}

/// Section label + chip row with optional "Other" bottom-sheet picker.
class AddCarChipSection extends StatelessWidget {
  const AddCarChipSection({
    super.key,
    required this.label,
    required this.chipKeys,
    required this.otherKeys,
    required this.selectedKey,
    required this.onSelected,
    required this.labelFor,
    this.otherLabel,
  });

  final String label;
  final List<String> chipKeys;
  final List<String> otherKeys;
  final String? selectedKey;
  final ValueChanged<String> onSelected;
  final String Function(String key) labelFor;
  final String? otherLabel;

  bool get _isOtherSelected =>
      selectedKey != null && !chipKeys.contains(selectedKey);

  Future<void> _openOtherSheet(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AddCarTheme.cardBg(context),
      shape: AddCarTheme.bottomSheetShape,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(label, style: AddCarTheme.sectionLabel(context)),
              ),
              Divider(height: 1, color: AddCarTheme.border(context)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherKeys.length,
                  itemBuilder: (context, index) {
                    final key = otherKeys[index];
                    final isSelected = key == selectedKey;
                    return ListTile(
                      title: Text(
                        labelFor(key),
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: AddCarTheme.textPrimary(context),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, key),
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
    final resolvedOtherLabel = otherLabel ??
        switch (Localizations.localeOf(context).languageCode) {
          'en' => 'Other',
          'ar' => 'أخرى',
          _ => 'هیتر',
        };

    final otherDisplayLabel = _isOtherSelected && selectedKey != null
        ? labelFor(selectedKey!)
        : resolvedOtherLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AddCarTheme.sectionLabel(context)),
        const SizedBox(height: 12),
        AddCarFormCard(
          padding: const EdgeInsetsDirectional.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in chipKeys)
                AddCarSelectChip(
                  label: labelFor(key),
                  selected: selectedKey == key,
                  onTap: () => onSelected(key),
                ),
              AddCarSelectChip(
                label: otherDisplayLabel,
                selected: _isOtherSelected,
                showDropdownIcon: true,
                onTap: () => _openOtherSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section label + chip row without an "Other" picker.
class AddCarSimpleChipSection extends StatelessWidget {
  const AddCarSimpleChipSection({
    super.key,
    required this.label,
    required this.chipKeys,
    required this.selectedKey,
    required this.onSelected,
    required this.labelFor,
    this.fullWidth = false,
    this.squareChips = false,
    this.cardPadding = const EdgeInsetsDirectional.all(16),
  });

  final String label;
  final List<String> chipKeys;
  final String? selectedKey;
  final ValueChanged<String> onSelected;
  final String Function(String key) labelFor;
  final bool fullWidth;
  final bool squareChips;
  final EdgeInsetsGeometry cardPadding;

  @override
  Widget build(BuildContext context) {
    final chips = fullWidth
        ? Column(
            children: [
              for (var i = 0; i < chipKeys.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AddCarSelectChip(
                    label: labelFor(chipKeys[i]),
                    selected: selectedKey == chipKeys[i],
                    fullWidth: true,
                    onTap: () => onSelected(chipKeys[i]),
                  ),
                ),
              ],
            ],
          )
        : Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final key in chipKeys)
                AddCarSelectChip(
                  label: labelFor(key),
                  selected: selectedKey == key,
                  square: squareChips,
                  onTap: () => onSelected(key),
                ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AddCarTheme.sectionLabel(context)),
        const SizedBox(height: 12),
        AddCarFormCard(
          padding: cardPadding,
          child: chips,
        ),
      ],
    );
  }
}
