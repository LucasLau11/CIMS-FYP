import '../l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../utils/validators.dart';
import '../widgets/common/shared_widgets.dart';
import '../widgets/common/validated_field.dart';

/// Forgot-password flow, entirely inside the app:
///   1. enter email  ->  2. type the code from the email  ->
///   3. choose a new password.
/// Pops with `true` once the password has been changed.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, code, password }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _resendSeconds = 60;

  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  bool _completed = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _serverError;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    // Leaving after the code was accepted but before saving a password would
    // otherwise leave a live temporary session behind.
    if (_step == _Step.password && !_completed) {
      AuthService.instance.cancelPasswordReset();
    }
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  String _message(Object e) => e is ResetCodeException ? e.message : friendlyError(e);

  Future<void> _sendCode({bool resend = false}) async {
    if (!resend && !(_emailFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _serverError = null;
    });
    try {
      await AuthService.instance.requestPasswordResetCode(_emailController.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = _Step.code;
        _codeController.clear();
      });
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resend ? AppLocalizations.of(context)!.fgCodeRequested : AppLocalizations.of(context)!.fgCheckEmail),
        backgroundColor: AppColors.primary,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = _message(e);
      });
    }
  }

  Future<void> _verifyCode() async {
    if (!(_codeFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _serverError = null;
    });
    try {
      await AuthService.instance.verifyPasswordResetCode(
        email: _emailController.text,
        code: _codeController.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = _Step.password;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = _message(e);
      });
    }
  }

  Future<void> _savePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _serverError = null;
    });
    try {
      await AuthService.instance.completePasswordReset(_passwordController.text);
      _completed = true;
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = _message(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: AppLocalizations.of(context)!.fgTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepHeader(step: _step),
              const SizedBox(height: 24),
              if (_step == _Step.email) _buildEmailStep(),
              if (_step == _Step.code) _buildCodeStep(),
              if (_step == _Step.password) _buildPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serverErrorBanner() {
    if (_serverError == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_serverError!,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _busy ? null : onPressed,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.fgEnterEmail,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _serverErrorBanner(),
          Text(AppLocalizations.of(context)!.fgEmailLabel, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _emailController,
            fieldValidator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            hintText: AppLocalizations.of(context)!.fgEmailHint,
            prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
            onChanged: (_) {
              if (_serverError != null) setState(() => _serverError = null);
            },
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 24),
          _primaryButton(AppLocalizations.of(context)!.fgSendCode, _sendCode),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    final email = _emailController.text.trim();
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.fgSentIntro(email),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _serverErrorBanner(),
          Text(AppLocalizations.of(context)!.ceCodeLabel, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _codeController,
            fieldValidator: Validators.otpCode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 10,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hintText: AppLocalizations.of(context)!.ceCodeHint,
            prefixIcon: Icon(Icons.pin_outlined, size: 20, color: AppColors.textMuted),
            onChanged: (_) {
              if (_serverError != null) setState(() => _serverError = null);
            },
            onSubmitted: (_) => _verifyCode(),
          ),
          const SizedBox(height: 24),
          _primaryButton(AppLocalizations.of(context)!.fgVerifyCode, _verifyCode),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (_busy || _cooldown > 0) ? null : () => _sendCode(resend: true),
            child: Text(_cooldown > 0 ? AppLocalizations.of(context)!.ceResendIn(_cooldown) : AppLocalizations.of(context)!.ceResend),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _step = _Step.email;
                      _serverError = null;
                    }),
            child: Text(AppLocalizations.of(context)!.fgDifferentEmail),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.fgCodeAccepted,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _serverErrorBanner(),
          Text(AppLocalizations.of(context)!.fpNewPassword, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _passwordController,
            fieldValidator: (v) => Validators.password(v),
            obscureText: _obscurePassword,
            showSuccess: false,
            textInputAction: TextInputAction.next,
            hintText: AppLocalizations.of(context)!.fgNewPasswordHint,
            prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
            suffix: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: AppColors.textMuted),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            onChanged: (_) {
              if (_serverError != null) setState(() => _serverError = null);
              // The confirmation field depends on this one.
              if (_confirmController.text.isNotEmpty) {
                _passwordFormKey.currentState?.validate();
              }
            },
          ),
          PasswordChecklist(controller: _passwordController),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.fpConfirmPassword, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _confirmController,
            fieldValidator: (v) => Validators.confirmPassword(v, _passwordController.text),
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            hintText: AppLocalizations.of(context)!.fgConfirmHint,
            prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
            suffix: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: AppColors.textMuted),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            onSubmitted: (_) => _savePassword(),
          ),
          const SizedBox(height: 24),
          _primaryButton(AppLocalizations.of(context)!.fgSaveNew, _savePassword),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Email', 'Code', 'New password'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step.index ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: i == step.index ? FontWeight.w700 : FontWeight.w400,
                    color: i <= step.index ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
