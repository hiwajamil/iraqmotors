import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/features/auth/presentation/controllers/auth_controller.dart';
import 'package:iq_motors/core/localization/auth_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/core/utils/phone_auth_email.dart';
import 'package:iq_motors/features/auth/presentation/navigation/post_auth_navigation.dart';
import 'package:iq_motors/core/config/super_admin_config.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/auth/data/services/auth_service.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/home_screen.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';

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
  const AuthScreen({
    super.key,
    this.initialLoginMode = true,
    this.postAuthRoute = PostAuthRoute.dashboard,
  });

  final bool initialLoginMode;
  final PostAuthRoute postAuthRoute;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AccountType { individual, showroom }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _AccountType _accountType = _AccountType.individual;
  late bool _isLoginMode;
  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isCodeSent = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
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
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
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
    _isCodeSent = false;
    _resendCountdown = 0;
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendCountdown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() {
          _resendCountdown = 0;
          _isCodeSent = false;
        });
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      if (!_isLoginMode) {
        final phone = _loginPhoneController.text.trim();
        if (phone.isNotEmpty) {
          _individualPhoneController.text = phone;
          _showroomPhoneController.text = phone;
        }
      }
    });
  }

  Future<void> _showAccountNotFoundPrompt() async {
    final l10n = context.l10n;
    final goToSignUp = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => _AccountNotFoundDialog(
        message: l10n.authAccountNotFoundPrompt,
        createAccountLabel: l10n.authCreateNewAccount,
        cancelLabel: l10n.back,
      ),
    );
    if (goToSignUp == true && mounted) {
      _toggleAuthMode();
    }
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
      if (e.code == AuthErrorCode.userNotFound) {
        await _showAccountNotFoundPrompt();
      } else {
        _showMessage(l10n.messageForAuthError(e.code));
      }
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
    final phone = _activePhoneController.text.trim();
    final password = _accountType == _AccountType.individual
        ? _individualPasswordController.text
        : _showroomPasswordController.text;

    if (_accountType == _AccountType.individual &&
        _fullNameController.text.trim().isEmpty) {
      _showMessage(l10n.fullNameRequired);
      return;
    }
    if (password.isEmpty) {
      _showMessage(l10n.passwordRequired);
      return;
    }
    if (autoCredential == null && smsCode.isEmpty) {
      _showMessage(l10n.otpRequired);
      return;
    }

    final userData = <String, dynamic>{
      'phoneNumber': phone,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
      if (_accountType == _AccountType.individual) ...{
        'fullName': _fullNameController.text.trim(),
        'userType': 'Normal',
      } else ...{
        'fullName': _ownerNameController.text.trim(),
        'userType': 'Showroom',
        'showroomName': _showroomNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'city': _selectedCity,
      },
    };

    setState(() => _isLoading = true);
    try {
      await auth.verifyOtpAndRegister(
        verificationId: verificationId,
        smsCode: smsCode,
        userData: userData,
        autoVerifiedCredential: autoCredential,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
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

  Future<void> _navigateAfterAuth() async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user == null || !mounted) return;

    final profile = await auth.fetchProfile(user.uid);
    if (!mounted) return;

    final email = user.email ?? _resolveAuthEmail();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => screenForPostAuthRoute(
          widget.postAuthRoute,
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
    if (_isSendingCode || (_isCodeSent && _resendCountdown > 0)) return;

    final l10n = context.l10n;
    final auth = ref.read(authServiceProvider);
    final rawPhone = _activePhoneController.text.trim();

    final phone = cleanPhoneInput(rawPhone);
    if (phone.isEmpty) {
      _showErrorSnackBar(l10n.enterPhoneFirst);
      return;
    }
    if (!isValidIraqMobile(phone)) {
      _showErrorSnackBar(l10n.authInvalidPhone);
      return;
    }

    setState(() {
      _verificationId = null;
      _autoVerifiedCredential = null;
      _isCodeSent = false;
      _resendCountdown = 0;
      _resendTimer?.cancel();
      _resendTimer = null;
      _isSendingCode = true;
    });

    await auth.sendOtp(
      phoneNumber: rawPhone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _isCodeSent = true;
          _isSendingCode = false;
        });
        _startResendCountdown();
        _showMessage(
          l10n.verificationCodeSent(formatIraqPhoneE164(phone)),
        );
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isSendingCode = false);
        debugPrint('[AuthScreen] Phone Auth Exception: $error');
        _showErrorSnackBar(AuthController.formatFirebaseAuthError(error));
      },
      onAutoVerified: (credential) {
        if (!mounted) return;
        setState(() {
          _autoVerifiedCredential = credential;
          _isCodeSent = true;
          _isSendingCode = false;
        });
        _startResendCountdown();
        _showMessage(l10n.authPhoneAutoVerified);
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        if (!mounted) return;
        setState(() => _verificationId = verificationId);
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final colorScheme = context.colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        backgroundColor: colorScheme.inverseSurface,
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
      backgroundColor: context.colorScheme.surface,
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
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isNarrow ? 20 : 24,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isNarrow ? 20 : 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthHeader(isLoginMode: _isLoginMode),
                            const SizedBox(height: 32),
                            if (!_isLoginMode) ...[
                              _AccountTypeToggle(
                                accountType: _accountType,
                                onChanged: _switchAccountType,
                              ),
                              const SizedBox(height: 32),
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
                                          isCodeSent: _isCodeSent,
                                          resendCountdown: _resendCountdown,
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
                                          otpController:
                                              _showroomOtpController,
                                          onSendCode: _sendVerificationCode,
                                          isSendingCode: _isSendingCode,
                                          isCodeSent: _isCodeSent,
                                          resendCountdown: _resendCountdown,
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
                            const SizedBox(height: 24),
                            _AuthModeLink(
                              isLoginMode: _isLoginMode,
                              onToggle: _toggleAuthMode,
                            ),
                            if (_isLoading) ...[
                              const SizedBox(height: 16),
                              const AppLoadingCenter(),
                            ],
                          ],
                        ),
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
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: context.colorScheme.onSurface,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: Text(l10n.back),
          ),
          Expanded(
            child: Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Column(
      children: [
        Text(
          isLoginMode ? l10n.signIn : l10n.createAccount,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLoginMode ? l10n.signInSubtitle : l10n.registerSubtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
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
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_AccountType>(
        segments: [
          ButtonSegment(
            value: _AccountType.individual,
            label: Text(l10n.accountIndividual),
          ),
          ButtonSegment(
            value: _AccountType.showroom,
            label: Text(l10n.accountShowroom),
          ),
        ],
        selected: {accountType},
        onSelectionChanged: (next) {
          if (next.isEmpty) return;
          onChanged(next.first);
        },
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.padded,
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
          const SizedBox(height: 8),
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
    required this.isCodeSent,
    required this.resendCountdown,
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
  final bool isCodeSent;
  final int resendCountdown;
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
            isCodeSent: isCodeSent,
            resendCountdown: resendCountdown,
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
          const SizedBox(height: 8),
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
    required this.isCodeSent,
    required this.resendCountdown,
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
  final bool isCodeSent;
  final int resendCountdown;
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
            isCodeSent: isCodeSent,
            resendCountdown: resendCountdown,
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
          const SizedBox(height: 8),
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

/// Apple-style input with a theme-driven focus ring.
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

  Widget _buildTextFormField(BuildContext context, {TextAlign? textAlign}) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textDirection: widget.showIraqCountryCode
          ? TextDirection.ltr
          : widget.textDirection,
      textAlign: textAlign ?? TextAlign.start,
      obscureText: widget.obscureText,
      validator: widget.validator,
      inputFormatters: widget.showIraqCountryCode
          ? [IraqPhoneLocalInputFormatter()]
          : null,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        border: InputBorder.none,
        prefixText: widget.showIraqCountryCode
            ? iraqPhoneCountryCodeDisplay
            : null,
        prefixStyle: widget.showIraqCountryCode
            ? textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.showIraqCountryCode ? 12 : 16,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.includeBottomPadding ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? colorScheme.primary : colorScheme.outlineVariant,
                width: 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
              color: _focused
                  ? colorScheme.surfaceContainerLowest
                  : colorScheme.surfaceContainerHighest,
            ),
            child: widget.showIraqCountryCode
                ? Directionality(
                    textDirection: TextDirection.ltr,
                    child: _buildTextFormField(context, textAlign: TextAlign.left),
                  )
                : _buildTextFormField(context),
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
    required this.isCodeSent,
    required this.resendCountdown,
  });

  final TextEditingController otpController;
  final Future<void> Function() onSendCode;
  final bool isSendingCode;
  final bool isCodeSent;
  final int resendCountdown;

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
                  isCodeSent: isCodeSent,
                  resendCountdown: resendCountdown,
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? colorScheme.primary : colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
        color: _focused
            ? colorScheme.surfaceContainerLowest
            : colorScheme.surfaceContainerHighest,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        maxLength: 6,
        validator: widget.validator,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          letterSpacing: 2,
        ),
        decoration: InputDecoration(
          hintText: l10n.otpPlaceholder,
          counterText: '',
          hintStyle: textTheme.bodyMedium?.copyWith(
            letterSpacing: 0,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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

class _SendCodeButton extends StatelessWidget {
  const _SendCodeButton({
    required this.onPressed,
    this.isLoading = false,
    this.isCodeSent = false,
    this.resendCountdown = 0,
  });

  final Future<void> Function() onPressed;
  final bool isLoading;
  final bool isCodeSent;
  final int resendCountdown;

  bool get _isDisabled =>
      isLoading || (isCodeSent && resendCountdown > 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FilledButton(
      onPressed: _isDisabled ? null : () => onPressed(),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(48, 48),
      ),
      child: isLoading
          ? AppLoadingIndicator.compact(
              color: context.colorScheme.onPrimary,
            )
          : isCodeSent && resendCountdown > 0
              ? Text('${resendCountdown}s')
              : isCodeSent
                  ? const Icon(Icons.check_rounded, size: 20)
                  : Text(l10n.sendCode),
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? colorScheme.primary : colorScheme.outlineVariant,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
              color: _focused
                  ? colorScheme.surfaceContainerLowest
                  : colorScheme.surfaceContainerHighest,
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
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              dropdownColor: colorScheme.surfaceContainerLowest,
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
      child: AnimatedScale(
        scale: _hovered && !widget.isLoading ? 1.02 : 1,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            child: Text(widget.label),
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isLoginMode ? l10n.noAccount : l10n.haveAccount,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onToggle,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: colorScheme.primary,
            textStyle: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(isLoginMode ? l10n.register : l10n.signIn),
        ),
      ],
    );
  }
}

class _AccountNotFoundDialog extends StatelessWidget {
  const _AccountNotFoundDialog({
    required this.message,
    required this.createAccountLabel,
    required this.cancelLabel,
  });

  final String message;
  final String createAccountLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(createAccountLabel),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    );
  }
}
