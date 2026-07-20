import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/auth/presentation/navigation/post_auth_navigation.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/app/providers/theme_provider.dart';
import 'package:iq_motors/shared/widgets/language_switcher.dart';
import 'package:iq_motors/shared/widgets/currency_switcher.dart';
import 'package:iq_motors/features/listings/presentation/add_car_flow_screen.dart';
import 'package:iq_motors/features/detection/presentation/screens/car_detection_screen.dart';
import 'package:iq_motors/features/auth/presentation/screens/auth_screen.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';
import 'package:iq_motors/shared/widgets/iq_motors_logo.dart';

/// Glass / immersive app bar for the home hero layout.
class HomeGlassNavBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeGlassNavBar({
    super.key,
    required this.height,
    required this.isWide,
    required this.immersive,
    required this.navLinks,
    required this.horizontalPadding,
  });

  final double height;
  final bool isWide;
  final bool immersive;
  final List<String> navLinks;
  final double horizontalPadding;

  static const double _verticalPadding = 8;
  static const double _contentHeight = 114;

  static double heightOf(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return topInset + _verticalPadding * 2 + _contentHeight;
  }

  bool get _useImmersiveStyle => immersive && !isWide;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconColor =
        _useImmersiveStyle ? Colors.white : HomeScreenColors.textPrimary(context);

    final navContent = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        _verticalPadding,
        horizontalPadding,
        _verticalPadding,
      ),
      child: SizedBox(
        height: _contentHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: IqMotorsLogo(
                  height: isWide ? 110 : 88,
                  width: isWide ? 240 : 190,
                  light: _useImmersiveStyle,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
            ),
            if (isWide) ...[
              const Spacer(),
              ...navLinks.map(
                (link) => Padding(
                  padding: const EdgeInsetsDirectional.only(start: 32),
                  child: _HomeNavLink(label: link),
                ),
              ),
              const Spacer(),
            ] else
              const SizedBox(width: 8),
            LanguageSwitcherButton(iconColor: iconColor),
            SizedBox(width: isWide ? 8 : 4),
            CurrencySwitcherButton(iconColor: iconColor),
            SizedBox(width: isWide ? 8 : 4),
            _ThemeSwitcherButton(iconColor: iconColor, isWide: isWide),
            SizedBox(width: isWide ? 12 : 6),
            IconButton(
              tooltip: 'Scan car',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CarDetectionScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.document_scanner_outlined,
                color: iconColor,
                size: isWide ? 24 : 22,
              ),
            ),
            SizedBox(width: isWide ? 4 : 2),
            Consumer(
              builder: (context, ref, _) {
                final isSignedIn = ref.watch(authStateProvider).value != null;

                return _HomeSellButton(
                  compact: !isWide,
                  light: _useImmersiveStyle,
                  onTap: () {
                    if (isSignedIn) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AddCarFlowScreen(),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AuthScreen(
                          postAuthRoute: PostAuthRoute.sellCar,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(width: isWide ? 12 : 6),
            Consumer(
              builder: (context, ref, _) {
                final user = ref.watch(authStateProvider).value;
                final profile = ref.watch(userProfileProvider).value;
                final isSignedIn = user != null;
                final label = isSignedIn && profile != null
                    ? profile.displayName
                    : l10n.myAccount;

                return _HomeAccountButton(
                  label: label,
                  compact: !isWide,
                  light: _useImmersiveStyle,
                  onTap: () {
                    if (isSignedIn) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => dashboardForAuthenticatedUser(
                            email: user.email,
                            phone: profile?.phone,
                            accountType: profile?.accountType,
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AuthScreen(
                          initialLoginMode: false,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );

    return RepaintBoundary(
      child: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: height,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: _useImmersiveStyle
            ? SafeArea(
                bottom: false,
                child: navContent,
              )
            : kIsWeb
                ? ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: _navBarBackground(context, navContent),
                    ),
                  )
                : _navBarBackground(context, navContent),
      ),
    );
  }

  Widget _navBarBackground(BuildContext context, Widget child) {
    final colorScheme = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: kIsWeb ? 0.82 : 0.95),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }
}

class _HomeNavLink extends StatefulWidget {
  const _HomeNavLink({required this.label});

  final String label;

  @override
  State<_HomeNavLink> createState() => _HomeNavLinkState();
}

class _HomeNavLinkState extends State<_HomeNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _hovered ? 1 : 0.7,
          child: Text(
            widget.label,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: HomeScreenColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSellButton extends StatelessWidget {
  const _HomeSellButton({
    required this.onTap,
    this.compact = false,
    this.light = false,
  });

  final VoidCallback onTap;
  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;

    // On the hero photo, prefer a high-contrast filled CTA (M3 highest emphasis).
    // Off-hero, use the same filled style so hierarchy stays consistent.
    final style = FilledButton.styleFrom(
      minimumSize: Size(compact ? 48 : 64, 48),
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      backgroundColor: light ? scheme.surface : scheme.primary,
      foregroundColor: light ? scheme.onSurface : scheme.onPrimary,
    );

    return FilledButton(
      onPressed: onTap,
      style: style,
      child: Text(l10n.sell),
    );
  }
}

class _HomeAccountButton extends StatelessWidget {
  const _HomeAccountButton({
    required this.label,
    required this.onTap,
    this.compact = false,
    this.light = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    if (compact) {
      return IconButton.filledTonal(
        onPressed: onTap,
        tooltip: label,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: light ? scheme.surface.withValues(alpha: 0.92) : null,
          foregroundColor: light ? scheme.onSurface : null,
        ),
        icon: const Icon(Icons.person_outline_rounded),
      );
    }

    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: light ? scheme.surface.withValues(alpha: 0.92) : null,
        foregroundColor: light ? scheme.onSurface : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ThemeSwitcherButton extends ConsumerWidget {
  const _ThemeSwitcherButton({
    required this.iconColor,
    required this.isWide,
  });

  final Color iconColor;
  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tooltip = switch (themeMode) {
      ThemeMode.system => 'System theme (${isDark ? 'Dark' : 'Light'})',
      ThemeMode.dark => 'Dark mode',
      ThemeMode.light => 'Light mode',
    };

    final iconData = switch (themeMode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
    };

    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
      icon: Icon(
        iconData,
        color: iconColor,
        size: isWide ? 22 : 20,
      ),
    );
  }
}
