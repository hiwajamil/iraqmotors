import 'package:flutter/material.dart';

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

  static const Color activeFill = Color(0xFF1D1D1F);
  static const Color inactiveBorder = Color(0xFFE5E5EA);

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
            color: widget.selected ? AddCarSelectChip.activeFill : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected
                  ? AddCarSelectChip.activeFill
                  : AddCarSelectChip.inactiveBorder,
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
                  color: widget.selected ? Colors.white : AddCarSelectChip.activeFill,
                ),
              ),
              if (widget.showDropdownIcon) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: widget.selected ? Colors.white : const Color(0xFF86868B),
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

  static const Color _textPrimary = Color(0xFF1D1D1F);

  bool get _isOtherSelected =>
      selectedKey != null && !chipKeys.contains(selectedKey);

  Future<void> _openOtherSheet(BuildContext context) async {
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
                  label,
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
                          color: _textPrimary,
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
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
  });

  final String label;
  final List<String> chipKeys;
  final String? selectedKey;
  final ValueChanged<String> onSelected;
  final String Function(String key) labelFor;
  final bool fullWidth;
  final bool squareChips;

  static const Color _textPrimary = Color(0xFF1D1D1F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        if (fullWidth)
          Column(
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
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in chipKeys)
                AddCarSelectChip(
                  label: labelFor(key),
                  selected: selectedKey == key,
                  square: squareChips,
                  onTap: () => onSelected(key),
                ),
            ],
          ),
      ],
    );
  }
}
