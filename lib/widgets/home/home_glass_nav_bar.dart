import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_extensions.dart';
import '../../core/post_auth_navigation.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/language_switcher.dart';
import '../../views/add_car/add_car_flow_screen.dart';
import '../../views/auth/auth_screen.dart';
import 'home_theme.dart';

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
    final titleColor =
        _useImmersiveStyle ? Colors.white : HomeScreenColors.textPrimary;
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
              child: Text(
                l10n.appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isWide ? 24 : 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.0,
                  color: titleColor,
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
                        builder: (_) => const AuthScreen(),
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
          : ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: navContent,
                  ),
                ),
              ),
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
