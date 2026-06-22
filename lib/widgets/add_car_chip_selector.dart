import 'package:flutter/material.dart';

import '../views/add_car/add_car_theme.dart';
import '../views/add_car/widgets/add_car_form_card.dart';

/// Apple-style selectable chip used in the add-car wizard.
class AddCarSelectChip extends StatefulWidget {
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
  State<AddCarSelectChip> createState() => _AddCarSelectChipState();
}

class _AddCarSelectChipState extends State<AddCarSelectChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.square ? 52 : null,
          height: widget.square ? 44 : null,
          alignment: widget.fullWidth || widget.square
              ? Alignment.center
              : null,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: widget.square ? 0 : 14,
            vertical: widget.square ? 0 : 10,
          ),
          decoration: BoxDecoration(
            color: widget.selected ? AddCarTheme.textPrimary : AddCarTheme.inputFill,
            borderRadius: BorderRadius.circular(AddCarTheme.inputRadius),
            border: Border.all(
              color: widget.selected
                  ? AddCarTheme.textPrimary
                  : (_pressed ? AddCarTheme.focusBlue : AddCarTheme.border),
              width: _pressed && !widget.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize:
                widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.fullWidth
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.selected
                      ? Colors.white
                      : AddCarTheme.textPrimary,
                ),
              ),
              if (widget.showDropdownIcon) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: widget.selected
                      ? Colors.white
                      : AddCarTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
      backgroundColor: AddCarTheme.cardBg,
      shape: AddCarTheme.bottomSheetShape,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(label, style: AddCarTheme.sectionLabel),
              ),
              const Divider(height: 1, color: AddCarTheme.border),
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
        Text(label, style: AddCarTheme.sectionLabel),
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
        Text(label, style: AddCarTheme.sectionLabel),
        const SizedBox(height: 12),
        AddCarFormCard(
          padding: cardPadding,
          child: chips,
        ),
      ],
    );
  }
}
