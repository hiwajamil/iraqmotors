import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/localization/locale_config.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/app/providers/locale_provider.dart';

/// Globe icon that opens an M3 language picker dialog.
class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({super.key, this.iconColor});

  final Color? iconColor;

  static Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      barrierColor: context.colorScheme.scrim.withValues(alpha: 0.4),
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
    return IconButton(
      tooltip: context.l10n.selectLanguage,
      onPressed: () => showLanguageSheet(context, ref),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: iconColor ?? context.colorScheme.onSurface,
      ),
      icon: const Icon(Icons.language_rounded),
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
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final current = ref.watch(localeProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Material(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.selectLanguage,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
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
                    child: isSelected
                        ? FilledButton.tonalIcon(
                            onPressed: () => onSelected(option.locale),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              alignment: AlignmentDirectional.centerStart,
                            ),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: Text(
                              label,
                              textDirection: AppLocaleConfig.isRtl(option.locale)
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => onSelected(option.locale),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              alignment: AlignmentDirectional.centerStart,
                            ),
                            child: Text(
                              label,
                              textDirection: AppLocaleConfig.isRtl(option.locale)
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                          ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _LabelKey { kurdish, arabic, english }
