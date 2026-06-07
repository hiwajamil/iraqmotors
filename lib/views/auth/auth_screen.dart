import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';
import '../../core/auth_l10n.dart';
import '../../core/l10n_extensions.dart';
import '../../core/phone_auth_email.dart';
import '../../core/post_auth_navigation.dart';
import '../../core/super_admin_config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../services/auth_service.dart';

String _cityLabel(AppLocalizations l10n, String key) {
  return switch (key) {
    'erbil' => l10n.cityErbil,
    'sulaymaniyah' => l10n.citySulaymaniyah,
    'baghdad' => l10n.cityBaghdad,
    'dohuk' => l10n.cityDohuk,
    'kirkuk' => l10n.cityKirkuk,
    _ => key,
  };
}

/// Registration / sign-in — individual vs showroom toggle forms.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialLoginMode = false});

  final bool initialLoginMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AccountType { individual, showroom }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static const Color _background = Color(0xFFF5F5F7);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _toggleTrack = Color(0xFFF2F2F7);
  static const Color _accentBlue = Color(0xFF007AFF);
  static const Color _accentBlack = Color(0xFF000000);

  _AccountType _accountType = _AccountType.individual;
  late bool _isLoginMode;
  bool _isLoading = false;
  bool _isSendingCode = false;
  late final AuthController _authController;
  String? _verificationId;
  PhoneAuthCredential? _autoVerifiedCredential;

  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPhoneController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _individualFormKey = GlobalKey<FormState>();
  final _showroomFormKey = GlobalKey<FormState>();

  // Individual fields
  final _fullNameController = TextEditingController();
  final _individualPhoneController = TextEditingController();
  final _individualOtpController = TextEditingController();
  final _individualPasswordController = TextEditingController();

  // Showroom fields
  final _showroomNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _showroomPhoneController = TextEditingController();
  final _showroomOtpController = TextEditingController();
  final _showroomPasswordController = TextEditingController();
  String? _selectedCity;

  static const _cityKeys = [
    'erbil',
    'sulaymaniyah',
    'baghdad',
    'dohuk',
    'kirkuk',
  ];

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.initialLoginMode;
    _authController = AuthController(ref.read(authServiceProvider));
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _fullNameController.dispose();
    _individualPhoneController.dispose();
    _individualOtpController.dispose();
    _individualPasswordController.dispose();
    _showroomNameController.dispose();
    _ownerNameController.dispose();
    _showroomPhoneController.dispose();
    _showroomOtpController.dispose();
    _showroomPasswordController.dispose();
    super.dispose();
  }

  void _switchAccountType(_AccountType type) {
    if (_accountType == type) return;
    setState(() {
      _accountType = type;
      _clearPhoneVerification();
    });
  }

  void _clearPhoneVerification() {
    _verificationId = null;
    _autoVerifiedCredential = null;
  }

  void _toggleAuthMode() {
    setState(() => _isLoginMode = !_isLoginMode);
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;

    if (_isLoginMode) {
      if (!(_loginFormKey.currentState?.validate() ?? false)) return;
      await _submitLogin();
      return;
    }

    final formKey = _accountType == _AccountType.individual
        ? _individualFormKey
        : _showroomFormKey;
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (_accountType == _AccountType.showroom && _selectedCity == null) {
      _showMessage(context.l10n.selectCityLocation);
      return;
    }

    if (_autoVerifiedCredential == null &&
        (_verificationId == null || _verificationId!.isEmpty)) {
      _showMessage(context.l10n.authSendCodeFirst);
      return;
    }

    await _submitRegistration();
  }

  Future<void> _submitLogin() async {
    final l10n = context.l10n;
    final auth = ref.read(authServiceProvider);
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    setState(() => _isLoading = true);
    try {
      if (isSuperAdminUser(email: email, phone: _loginPhoneController.text)) {
        await auth.signInAsSuperAdmin(
          email: email,
          phone: _loginPhoneController.text.trim(),
          password: password,
        );
      } else {
        await auth.signIn(
          phone: _loginPhoneController.text.trim(),
          password: password,
        );
      }
      if (!mounted) return;
      await _navigateAfterAuth();
    } on AuthException catch (e) {
      _showMessage(l10n.messageForAuthError(e.code));
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(l10n.messageForFirebaseAuthException(e));
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRegistration() async {
    final l10n = context.l10n;
    final auth = ref.read(authServiceProvider);
    final verificationId = _verificationId ?? '';
    final smsCode = _activeOtpController.text.trim();
    final autoCredential = _autoVerifiedCredential;

    setState(() => _isLoading = true);
    try {
      if (_accountType == _AccountType.individual) {
        await auth.registerIndividual(
          fullName: _fullNameController.text,
          phone: _individualPhoneController.text.trim(),
          password: _individualPasswordController.text,
          verificationId: verificationId,
          smsCode: smsCode,
          autoVerifiedCredential: autoCredential,
        );
      } else {
        await auth.registerShowroom(
          showroomName: _showroomNameController.text,
          ownerName: _ownerNameController.text,
          phone: _showroomPhoneController.text.trim(),
          password: _showroomPasswordController.text,
          city: _selectedCity!,
          verificationId: verificationId,
          smsCode: smsCode,
          autoVerifiedCredential: autoCredential,
        );
      }
      if (!mounted) return;
      await _navigateAfterAuth();
    } on AuthException catch (e) {
      _showMessage(l10n.messageForAuthError(e.code));
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(AuthController.formatFirebaseAuthError(e));
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateAfterAuth() async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user == null || !mounted) return;

    final profile = await auth.fetchProfile(user.uid);
    if (!mounted) return;

    final email = user.email ?? _resolveAuthEmail();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => dashboardForAuthenticatedUser(
          email: email,
          phone: profile?.phone ?? _loginPhoneController.text.trim(),
          accountType: profile?.accountType,
        ),
      ),
    );
  }

  TextEditingController get _activeOtpController =>
      _accountType == _AccountType.individual
          ? _individualOtpController
          : _showroomOtpController;

  TextEditingController get _activePhoneController =>
      _accountType == _AccountType.individual
          ? _individualPhoneController
          : _showroomPhoneController;

  /// Prefer Firebase user email after sign-in; fall back to login form email.
  String? _resolveAuthEmail() {
    final firebaseEmail = ref.read(authServiceProvider).currentUser?.email;
    if (firebaseEmail != null && firebaseEmail.isNotEmpty) {
      return firebaseEmail;
    }
    if (_isLoginMode) {
      final formEmail = _loginEmailController.text.trim();
      return formEmail.isEmpty ? null : formEmail;
    }
    return null;
  }

  Future<void> _sendVerificationCode() async {
    if (_isSendingCode) return;

    final l10n = context.l10n;
    setState(_clearPhoneVerification);

    final result = await _authController.sendVerificationCode(
      rawPhone: _activePhoneController.text,
      onSendingChanged: (sending) {
        if (!mounted) return;
        setState(() => _isSendingCode = sending);
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        if (!mounted) return;
        setState(() => _verificationId = verificationId);
      },
      onError: (message) {
        if (!mounted) return;
        final display = switch (message) {
          'enter_phone_first' => l10n.enterPhoneFirst,
          'invalid_phone' => l10n.authInvalidPhone,
          'invalidPhone' => l10n.authInvalidPhone,
          _ => message,
        };
        _showErrorSnackBar(display);
      },
      onSuccess: (verificationResult) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationResult.verificationId;
          _autoVerifiedCredential = verificationResult.autoVerifiedCredential;
        });
        final phone = cleanPhoneInput(_activePhoneController.text.trim());
        if (verificationResult.isAutoVerified) {
          _showMessage(l10n.authPhoneAutoVerified);
        } else {
          _showMessage(l10n.verificationCodeSent(formatIraqPhoneE164(phone)));
        }
      },
    );

    if (result == null || !mounted) return;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _textPrimary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width <= 480;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            const _AuthTopNav(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isNarrow ? 20 : 40),
                      decoration: BoxDecoration(
                        color: _cardWhite,
                        borderRadius: BorderRadius.circular(
                          isNarrow ? 20 : 24,
                        ),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.02),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AuthHeader(isLoginMode: _isLoginMode),
                          const SizedBox(height: 30),
                          if (!_isLoginMode) ...[
                            _AccountTypeToggle(
                              accountType: _accountType,
                              onChanged: _switchAccountType,
                            ),
                            const SizedBox(height: 30),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _isLoginMode
                                ? _LoginForm(
                                    key: const ValueKey('login'),
                                    formKey: _loginFormKey,
                                    emailController: _loginEmailController,
                                    phoneController: _loginPhoneController,
                                    passwordController:
                                        _loginPasswordController,
                                    isLoading: _isLoading,
                                    onSubmit: _onSubmit,
                                  )
                                : _accountType == _AccountType.individual
                                    ? _IndividualForm(
                                        key: const ValueKey('individual'),
                                        formKey: _individualFormKey,
                                        fullNameController:
                                            _fullNameController,
                                        phoneController:
                                            _individualPhoneController,
                                        otpController:
                                            _individualOtpController,
                                        onSendCode: _sendVerificationCode,
                                        isSendingCode: _isSendingCode,
                                        passwordController:
                                            _individualPasswordController,
                                        isLoading: _isLoading,
                                        onSubmit: _onSubmit,
                                      )
                                    : _ShowroomForm(
                                        key: const ValueKey('showroom'),
                                        formKey: _showroomFormKey,
                                        showroomNameController:
                                            _showroomNameController,
                                        ownerNameController:
                                            _ownerNameController,
                                        phoneController:
                                            _showroomPhoneController,
                                        otpController: _showroomOtpController,
                                        onSendCode: _sendVerificationCode,
                                        isSendingCode: _isSendingCode,
                                        passwordController:
                                            _showroomPasswordController,
                                        selectedCity: _selectedCity,
                                        cityKeys: _cityKeys,
                                        isLoading: _isLoading,
                                        onCityChanged: (city) {
                                          setState(
                                            () => _selectedCity = city,
                                          );
                                        },
                                        onSubmit: _onSubmit,
                                      ),
                          ),
                          const SizedBox(height: 25),
                          _AuthModeLink(
                            isLoginMode: _isLoginMode,
                            onToggle: _toggleAuthMode,
                          ),
                          if (_isLoading) ...[
                            const SizedBox(height: 16),
                            const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTopNav extends StatelessWidget {
  const _AuthTopNav();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
      child: Row(
        children: [
          _BackButton(onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: _AuthScreenState._textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _hovered ? 0.7 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _AuthScreenState._textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.back,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _AuthScreenState._textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.isLoginMode});

  final bool isLoginMode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Text(
          isLoginMode ? l10n.signIn : l10n.createAccount,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28.8,
            fontWeight: FontWeight.w700,
            color: _AuthScreenState._textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isLoginMode ? l10n.signInSubtitle : l10n.registerSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: _AuthScreenState._textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _AccountTypeToggle extends StatelessWidget {
  const _AccountTypeToggle({
    required this.accountType,
    required this.onChanged,
  });

  final _AccountType accountType;
  final ValueChanged<_AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _AuthScreenState._toggleTrack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: l10n.accountIndividual,
              isActive: accountType == _AccountType.individual,
              onTap: () => onChanged(_AccountType.individual),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: l10n.accountShowroom,
              isActive: accountType == _AccountType.showroom,
              onTap: () => onChanged(_AccountType.showroom),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _AuthScreenState._cardWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive
                ? _AuthScreenState._textPrimary
                : _AuthScreenState._textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PremiumFormField(
            label: l10n.emailSuperAdmin,
            controller: emailController,
            placeholder: l10n.emailPlaceholder,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            validator: (v) {
              final trimmed = v?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              if (!trimmed.contains('@')) {
                return l10n.invalidEmail;
              }
              return null;
            },
          ),
          _PremiumFormField(
            label: l10n.phoneLabel,
            controller: phoneController,
            placeholder: l10n.phonePlaceholder,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            showIraqCountryCode: true,
            validator: (v) {
              if (isSuperAdminUser(
                email: emailController.text,
                phone: v,
              )) {
                return null;
              }
              return (v == null || v.trim().isEmpty)
                  ? l10n.phoneRequired
                  : null;
            },
          ),
          _PremiumFormField(
            label: l10n.passwordLabel,
            controller: passwordController,
            placeholder: l10n.passwordPlaceholder,
            obscureText: true,
            validator: (v) =>
                (v == null || v.isEmpty) ? l10n.passwordRequired : null,
          ),
          const SizedBox(height: 10),
          _SubmitButton(
            label: l10n.signIn,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _IndividualForm extends StatelessWidget {
  const _IndividualForm({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.otpController,
    required this.onSendCode,
    required this.isSendingCode,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final Future<void> Function() onSendCode;
  final bool isSendingCode;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PremiumFormField(
            label: l10n.fullName,
            controller: fullNameController,
            placeholder: l10n.fullNamePlaceholder,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.fullNameRequired : null,
          ),
          _PremiumFormField(
            label: l10n.phoneLabel,
            controller: phoneController,
            placeholder: l10n.phonePlaceholder,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            showIraqCountryCode: true,
            includeBottomPadding: false,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.phoneRequired : null,
          ),
          _OtpVerificationRow(
            otpController: otpController,
            onSendCode: onSendCode,
            isSendingCode: isSendingCode,
          ),
          _PremiumFormField(
            label: l10n.passwordLabel,
            controller: passwordController,
            placeholder: l10n.passwordSetPlaceholder,
            obscureText: true,
            validator: (v) => (v == null || v.length < 6)
                ? l10n.passwordMinLength
                : null,
          ),
          const SizedBox(height: 10),
          _SubmitButton(
            label: l10n.register,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ShowroomForm extends StatelessWidget {
  const _ShowroomForm({
    super.key,
    required this.formKey,
    required this.showroomNameController,
    required this.ownerNameController,
    required this.phoneController,
    required this.otpController,
    required this.onSendCode,
    required this.isSendingCode,
    required this.passwordController,
    required this.selectedCity,
    required this.cityKeys,
    required this.isLoading,
    required this.onCityChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController showroomNameController;
  final TextEditingController ownerNameController;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final Future<void> Function() onSendCode;
  final bool isSendingCode;
  final TextEditingController passwordController;
  final String? selectedCity;
  final List<String> cityKeys;
  final bool isLoading;
  final ValueChanged<String?> onCityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PremiumFormField(
            label: l10n.showroomName,
            controller: showroomNameController,
            placeholder: l10n.showroomNamePlaceholder,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.showroomNameRequired
                : null,
          ),
          _PremiumFormField(
            label: l10n.ownerName,
            controller: ownerNameController,
            placeholder: l10n.ownerPlaceholder,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.ownerRequired : null,
          ),
          _PremiumFormField(
            label: l10n.workPhoneLabel,
            controller: phoneController,
            placeholder: l10n.workPhonePlaceholder,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            showIraqCountryCode: true,
            includeBottomPadding: false,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.phoneRequired : null,
          ),
          _OtpVerificationRow(
            otpController: otpController,
            onSendCode: onSendCode,
            isSendingCode: isSendingCode,
          ),
          _PremiumCityDropdown(
            label: l10n.cityLocation,
            value: selectedCity,
            cityKeys: cityKeys,
            onChanged: onCityChanged,
          ),
          _PremiumFormField(
            label: l10n.passwordLabel,
            controller: passwordController,
            placeholder: l10n.passwordSetPlaceholder,
            obscureText: true,
            validator: (v) => (v == null || v.length < 6)
                ? l10n.passwordMinLength
                : null,
          ),
          const SizedBox(height: 10),
          _SubmitButton(
            label: l10n.submitShowroomRequest,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

/// Apple-style input with blue focus ring.
class _PremiumFormField extends StatefulWidget {
  const _PremiumFormField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.textDirection,
    this.obscureText = false,
    this.includeBottomPadding = true,
    this.showIraqCountryCode = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final bool obscureText;
  final bool includeBottomPadding;
  final bool showIraqCountryCode;
  final String? Function(String?)? validator;

  @override
  State<_PremiumFormField> createState() => _PremiumFormFieldState();
}

class _PremiumFormFieldState extends State<_PremiumFormField> {
  static const Color _borderLight = Color(0xFFE5E5EA);
  static const Color _fillIdle = Color(0xFFFAFAFA);

  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.includeBottomPadding ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _AuthScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? _AuthScreenState._accentBlue
                    : _borderLight,
                width: 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: _AuthScreenState._accentBlue
                            .withValues(alpha: 0.1),
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
              color: _focused
                  ? _AuthScreenState._cardWhite
                  : _fillIdle,
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textDirection: widget.textDirection,
              obscureText: widget.obscureText,
              validator: widget.validator,
              style: const TextStyle(
                fontSize: 15,
                color: _AuthScreenState._textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: _AuthScreenState._textSecondary.withValues(alpha: 0.8),
                ),
                border: InputBorder.none,
                prefix: widget.showIraqCountryCode
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Text(
                          iraqPhoneCountryCodeDisplay,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _AuthScreenState._textPrimary,
                          ),
                        ),
                      )
                    : null,
                contentPadding: EdgeInsetsDirectional.symmetric(
                  horizontal: widget.showIraqCountryCode ? 8 : 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// OTP input + send-code button row, placed directly under the phone field.
class _OtpVerificationRow extends StatelessWidget {
  const _OtpVerificationRow({
    required this.otpController,
    required this.onSendCode,
    required this.isSendingCode,
  });

  final TextEditingController otpController;
  final Future<void> Function() onSendCode;
  final bool isSendingCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PremiumOtpField(
                    controller: otpController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.otpRequired;
                      }
                      if (value.trim().length < 4) {
                        return l10n.otpInvalid;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _SendCodeButton(
                  onPressed: onSendCode,
                  isLoading: isSendingCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline OTP field (no label) — matches [_PremiumFormField] styling.
class _PremiumOtpField extends StatefulWidget {
  const _PremiumOtpField({
    required this.controller,
    this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  State<_PremiumOtpField> createState() => _PremiumOtpFieldState();
}

class _PremiumOtpFieldState extends State<_PremiumOtpField> {
  static const Color _borderLight = Color(0xFFE5E5EA);
  static const Color _fillIdle = Color(0xFFFAFAFA);

  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? _AuthScreenState._accentBlue : _borderLight,
          width: 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: _AuthScreenState._accentBlue.withValues(alpha: 0.1),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
        color: _focused ? _AuthScreenState._cardWhite : _fillIdle,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        maxLength: 6,
        validator: widget.validator,
        style: const TextStyle(
          fontSize: 15,
          color: _AuthScreenState._textPrimary,
          letterSpacing: 2,
        ),
        decoration: InputDecoration(
          hintText: l10n.otpPlaceholder,
          counterText: '',
          hintStyle: TextStyle(
            fontSize: 15,
            letterSpacing: 0,
            color: _AuthScreenState._textSecondary.withValues(alpha: 0.8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _SendCodeButton extends StatefulWidget {
  const _SendCodeButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final Future<void> Function() onPressed;
  final bool isLoading;

  @override
  State<_SendCodeButton> createState() => _SendCodeButtonState();
}

class _SendCodeButtonState extends State<_SendCodeButton> {
  static const Color _buttonDark = Color(0xFF1D1D1F);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _hovered ? 0.88 : 1,
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : () => widget.onPressed(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonDark,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _buttonDark.withValues(alpha: 0.7),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.sendCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PremiumCityDropdown extends StatefulWidget {
  const _PremiumCityDropdown({
    required this.label,
    required this.value,
    required this.cityKeys,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> cityKeys;
  final ValueChanged<String?> onChanged;

  @override
  State<_PremiumCityDropdown> createState() => _PremiumCityDropdownState();
}

class _PremiumCityDropdownState extends State<_PremiumCityDropdown> {
  static const Color _borderLight = Color(0xFFE5E5EA);
  static const Color _fillIdle = Color(0xFFFAFAFA);

  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _AuthScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? _AuthScreenState._accentBlue
                    : _borderLight,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: _AuthScreenState._accentBlue
                            .withValues(alpha: 0.1),
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
              color: _focused
                  ? _AuthScreenState._cardWhite
                  : _fillIdle,
            ),
            child: DropdownButtonFormField<String>(
              key: ValueKey(widget.value ?? 'none'),
              initialValue: widget.value,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
              hint: Text(
                l10n.selectCityHint,
                style: TextStyle(
                  fontSize: 15,
                  color: _AuthScreenState._textSecondary.withValues(alpha: 0.8),
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _AuthScreenState._textSecondary,
              ),
              style: const TextStyle(
                fontSize: 15,
                color: _AuthScreenState._textPrimary,
              ),
              dropdownColor: _AuthScreenState._cardWhite,
              borderRadius: BorderRadius.circular(12),
              items: widget.cityKeys
                  .map(
                    (key) => DropdownMenuItem<String>(
                      value: key,
                      child: Text(_cityLabel(l10n, key)),
                    ),
                  )
                  .toList(),
              onChanged: widget.onChanged,
              validator: (v) => v == null ? l10n.selectCityRequired : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _hovered && !widget.isLoading ? 1.02 : 1,
          duration: const Duration(milliseconds: 200),
          child: AnimatedOpacity(
            opacity: widget.isLoading ? 0.6 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _AuthScreenState._accentBlack,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthModeLink extends StatelessWidget {
  const _AuthModeLink({
    required this.isLoginMode,
    required this.onToggle,
  });

  final bool isLoginMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isLoginMode ? l10n.noAccount : l10n.haveAccount,
          style: const TextStyle(
            fontSize: 14,
            color: _AuthScreenState._textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Text(
            isLoginMode ? l10n.register : l10n.signIn,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _AuthScreenState._accentBlue,
            ),
          ),
        ),
      ],
    );
  }
}
