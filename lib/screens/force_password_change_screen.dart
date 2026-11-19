import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../utils/validators.dart';
import '../widgets/common/validated_field.dart';
import 'login_screen.dart';

/// Wraps the screen a person is about to enter after logging in. If their
/// account was created by an administrator with a temporary password
/// (`profiles.must_change_password`), the app shows [ForcedPasswordChangeScreen]
/// first and only reveals [child] once a new password is saved. The child is not
/// even built until then, so none of its data is loaded early.
class PasswordChangeGate extends StatefulWidget {
  const PasswordChangeGate({super.key, required this.child});

  final Widget child;

  @override
  State<PasswordChangeGate> createState() => _PasswordChangeGateState();
}

class _PasswordChangeGateState extends State<PasswordChangeGate> {
  bool _checking = true;
  bool _mustChange = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final must = await AuthService.instance.mustChangePassword();
    if (!mounted) return;
    setState(() {
      _mustChange = must;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_mustChange) {
      return ForcedPasswordChangeScreen(onDone: () => setState(() => _mustChange = false));
    }
    return widget.child;
  }
}

/// First login with a temporary password: the person must choose their own
/// password before they can use the app. There is no way back except logging out.
class ForcedPasswordChangeScreen extends StatefulWidget {
  const ForcedPasswordChangeScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ForcedPasswordChangeScreen> createState() => _ForcedPasswordChangeScreenState();
}

class _ForcedPasswordChangeScreenState extends State<ForcedPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.completeFirstPasswordChange(_password.text);
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ResetCodeException ? e.message : friendlyError(e);
      });
    }
  }

  Future<void> _logOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          title: const Text('Choose a new password', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset, size: 48, color: AppColors.primaryText),
                  const SizedBox(height: 14),
                  Text(
                    AppLocalizations.of(context)!.fpIntro,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  Text(AppLocalizations.of(context)!.fpNewPassword, style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  ValidatedField(
                    controller: _password,
                    fieldValidator: (v) => Validators.password(v),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    showSuccess: false,
                    prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  PasswordChecklist(controller: _password),
                  const SizedBox(height: 14),
                  Text(AppLocalizations.of(context)!.fpConfirmPassword, style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  ValidatedField(
                    controller: _confirm,
                    fieldValidator: (v) => Validators.confirmPassword(v, _password.text),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    showSuccess: false,
                    prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
                    onSubmitted: (_) => _save(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                  ],
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _busy ? null : _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppLocalizations.of(context)!.fpSaveContinue, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _busy ? null : _logOut, child: Text(AppLocalizations.of(context)!.fpLogOut, textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
