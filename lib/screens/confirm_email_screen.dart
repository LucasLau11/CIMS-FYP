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

/// Confirms a new account by typing the code emailed at sign-up (no link to
/// open, so it works on any phone). Pops with the account's [UserRole] once the
/// email is confirmed, or with null if the person backs out.
///
/// [sendCodeOnOpen] is used when someone who never confirmed tries to log in:
/// the earlier email may be long gone, so a fresh code is sent straight away.
class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key, required this.email, this.sendCodeOnOpen = false});

  final String email;
  final bool sendCodeOnOpen;

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  static const int _resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.sendCodeOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resend());
    } else {
      _startCooldown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
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

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final role = await AuthService.instance.confirmSignupCode(email: widget.email, code: _codeController.text);
      if (!mounted) return;
      Navigator.of(context).pop(role);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _message(e);
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthService.instance.resendSignupCode(widget.email);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _info = AppLocalizations.of(context)!.ceNewCodeSent(widget.email);
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _message(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: AppLocalizations.of(context)!.ceTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primaryText),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.ceIntro(widget.email),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 22),
                if (_error != null) _banner(_error!, error: true),
                if (_info != null) _banner(_info!, error: false),
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
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _confirm(),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _busy ? null : _confirm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.ceConfirm, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: (_busy || _cooldown > 0) ? null : _resend,
                  child: Text(_cooldown > 0 ? AppLocalizations.of(context)!.ceResendIn(_cooldown) : AppLocalizations.of(context)!.ceResend, textAlign: TextAlign.center),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.ceBackToLogin, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner(String text, {required bool error}) {
    final color = error ? AppColors.error : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? AppColors.errorBg : AppColors.successBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: color))),
        ],
      ),
    );
  }
}
