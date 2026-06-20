import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_extensions.dart';
import '../core/locale_config.dart';
import '../providers/locale_provider.dart';

/// Minimal globe icon that opens an Apple-style language picker sheet.
class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({super.key, this.iconColor});

  final Color? iconColor;

  static const Color _iconColor = Color(0xFF1D1D1F);

  static Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _LanguagePickerSheet(
            onSelected: (locale) {
              ref.read(localeProvider.notifier).setLocale(locale);
              Navigator.pop(dialogContext);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LanguageIconButton(
      onTap: () => showLanguageSheet(context, ref),
      iconColor: iconColor ?? _iconColor,
    );
  }
}

class _LanguageIconButton extends StatefulWidget {
  const _LanguageIconButton({
    required this.onTap,
    required this.iconColor,
  });

  final VoidCallback onTap;
  final Color iconColor;

  @override
  State<_LanguageIconButton> createState() => _LanguageIconButtonState();
}

class _LanguageIconButtonState extends State<_LanguageIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.06 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFFE8E8ED)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.language_rounded,
              size: 22,
              color: widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet({required this.onSelected});

  final ValueChanged<Locale> onSelected;

  static const _options = [
    (locale: Locale('ku'), labelKey: _LabelKey.kurdish),
    (locale: Locale('ar'), labelKey: _LabelKey.arabic),
    (locale: Locale('en'), labelKey: _LabelKey.english),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              ..._options.map((option) {
                final isSelected =
                    current.languageCode == option.locale.languageCode;
                final label = switch (option.labelKey) {
                  _LabelKey.kurdish => l10n.languageKurdish,
                  _LabelKey.arabic => l10n.languageArabic,
                  _LabelKey.english => l10n.languageEnglish,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LanguageOptionTile(
                    label: label,
                    isSelected: isSelected,
                    isRtl: AppLocaleConfig.isRtl(option.locale),
                    onTap: () => onSelected(option.locale),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LabelKey { kurdish, arabic, english }

class _LanguageOptionTile extends StatefulWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.isSelected,
    required this.isRtl,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  State<_LanguageOptionTile> createState() => _LanguageOptionTileState();
}

class _LanguageOptionTileState extends State<_LanguageOptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF1D1D1F)
                : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  textDirection:
                      widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isSelected
                        ? Colors.white
                        : const Color(0xFF1D1D1F),
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
