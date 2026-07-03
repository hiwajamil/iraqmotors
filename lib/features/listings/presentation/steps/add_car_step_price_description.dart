import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_chip_selector.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_form_card.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_step_header.dart';

/// Step 9 — listing description and selling price.
class AddCarStepPriceDescription extends StatefulWidget {
  const AddCarStepPriceDescription({
    super.key,
    required this.description,
    required this.priceValue,
    required this.currencyKey,
    required this.onDescriptionChanged,
    required this.onPriceChanged,
    required this.onCurrencyChanged,
  });

  final String? description;
  final String? priceValue;
  final String currencyKey;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onCurrencyChanged;

  @override
  State<AddCarStepPriceDescription> createState() =>
      _AddCarStepPriceDescriptionState();
}

class _AddCarStepPriceDescriptionState extends State<AddCarStepPriceDescription> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.description ?? '');
    _priceController = TextEditingController(text: widget.priceValue ?? '');
  }

  @override
  void didUpdateWidget(AddCarStepPriceDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.description != oldWidget.description &&
        widget.description != _descriptionController.text) {
      _descriptionController.text = widget.description ?? '';
    }
    if (widget.priceValue != oldWidget.priceValue &&
        widget.priceValue != _priceController.text) {
      _priceController.text = widget.priceValue ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName.split('_').first;
    final symbol = AddCarFormOptions.currencySymbol(widget.currencyKey);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddCarStepHeader(
            title: switch (locale) {
              'en' => 'About',
              'ar' => 'حول',
              _ => 'دەربارە',
            },
            subtitle: switch (locale) {
              'en' => 'Write your own note',
              'ar' => 'اكتب ملاحظتك',
              _ => 'تێبینی خۆت بنووسە',
            },
          ),
          const SizedBox(height: 20),
          AddCarFormCard(
            padding: EdgeInsets.zero,
            child: TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 8,
              onChanged: widget.onDescriptionChanged,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AddCarTheme.textPrimary,
                height: 1.45,
              ),
              decoration: AddCarTheme.textFieldDecoration(
                hintText: switch (locale) {
                  'en' => 'Add a note if you like',
                  'ar' => 'أضف ملاحظة إن أردت',
                  _ => 'تێبینی زیاد بکە گەر دەتەوێت',
                },
              ).copyWith(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AddCarTheme.focusBlue, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            switch (locale) {
              'en' => 'Selling price',
              'ar' => 'سعر البيع',
              _ => 'نرخی فرۆشتن',
            },
            style: AddCarTheme.sectionTitle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final key in AddCarFormOptions.currencyKeys) ...[
                if (key != AddCarFormOptions.currencyKeys.first)
                  const SizedBox(width: 10),
                Expanded(
                  child: AddCarSelectChip(
                    label: AddCarFormOptions.currencyLabel(l10n, key),
                    selected: widget.currencyKey == key,
                    fullWidth: true,
                    onTap: () => widget.onCurrencyChanged(key),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AddCarFormCard(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: AddCarTheme.textPrimary,
              ),
              decoration: AddCarTheme.textFieldDecoration(
                hintText: '140,000',
                prefixText: '$symbol ',
              ).copyWith(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AddCarTheme.focusBlue, width: 1.5),
                ),
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AddCarTheme.textPrimary.withValues(alpha: 0.2),
                ),
              ),
              onChanged: widget.onPriceChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
