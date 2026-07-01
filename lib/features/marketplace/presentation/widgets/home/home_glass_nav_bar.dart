import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/auth/presentation/navigation/post_auth_navigation.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/shared/widgets/language_switcher.dart';
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

  static const double _verticalPadding = 20;
  static const double _contentHeight = 44;

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
        _useImmersiveStyle ? Colors.white : HomeScreenColors.textPrimary;

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
                  height: isWide ? 40 : 32,
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

    return AppBar(
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
                    child: _navBarBackground(navContent),
                  ),
                )
              : _navBarBackground(navContent),
    );
  }

  Widget _navBarBackground(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: kIsWeb ? 0.8 : 0.97),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: HomeScreenColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSellButton extends StatefulWidget {
  const _HomeSellButton({
    required this.onTap,
    this.compact = false,
    this.light = false,
  });

  final VoidCallback onTap;
  final bool compact;
  final bool light;

  @override
  State<_HomeSellButton> createState() => _HomeSellButtonState();
}

class _HomeSellButtonState extends State<_HomeSellButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: widget.compact ? 12 : 20,
              vertical: widget.compact ? 8 : 9,
            ),
            decoration: BoxDecoration(
              color: widget.light
                  ? Colors.white.withValues(alpha: _hovered ? 0.22 : 0.12)
                  : _hovered
                      ? const Color(0xFF000000)
                      : HomeScreenColors.textPrimary,
              borderRadius: BorderRadius.circular(12),
              border: widget.light
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    )
                  : null,
              boxShadow: widget.light
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: _hovered ? 0.18 : 0.12),
                        blurRadius: _hovered ? 16 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Text(
              l10n.sell,
              style: TextStyle(
                fontSize: widget.compact ? 13 : 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAccountButton extends StatefulWidget {
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
  State<_HomeAccountButton> createState() => _HomeAccountButtonState();
}

class _HomeAccountButtonState extends State<_HomeAccountButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: widget.compact ? 10 : 24,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: widget.light
                  ? Colors.white.withValues(alpha: _hovered ? 0.22 : 0.12)
                  : _hovered
                      ? Colors.black
                      : HomeScreenColors.textPrimary,
              borderRadius: BorderRadius.circular(30),
              border: widget.light
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    )
                  : null,
            ),
            child: widget.compact
                ? const Icon(Icons.person_outline_rounded,
                    size: 20, color: Colors.white)
                : Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
