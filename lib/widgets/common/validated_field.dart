import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Returns an error message for the current text, or null when it is valid.
typedef FieldValidator = String? Function(String value);

/// A text field that validates **while the person types**.
///
/// * The message appears shortly after they pause typing (so it does not
///   shout at the first keystroke) and straight away when they leave the field.
/// * Once an error is showing it re-checks on every keystroke, so it
///   disappears the moment the text is fixed.
/// * A green tick shows when the value is valid.
/// * It is a [FormField], so a surrounding [Form]'s `validate()` (used by Save
///   / Submit buttons) shows the error on every field at once.
/// * [externalError] shows a message that did not come from the rules, such as
///   "Incorrect email or password" after the server answered.
class ValidatedField extends FormField<String> {
  ValidatedField({
    super.key,
    required this.controller,
    required this.fieldValidator,
    this.hintText,
    this.labelText,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.showSuccess = true,
    this.autofocus = false,
    this.focusNode,
    this.externalError,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    super.enabled,
  }) : super(
          initialValue: controller.text,
          validator: (_) => fieldValidator(controller.text),
          builder: (field) => (field as _ValidatedFieldState)._buildField(),
        );

  final TextEditingController controller;
  final FieldValidator fieldValidator;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final Widget? prefixIcon;

  /// Replaces the green tick (for example a show/hide-password button).
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool showSuccess;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? externalError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// For values chosen from a picker (a map address, a date): the person taps
  /// the field instead of typing, and [onTap] opens the picker.
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  FormFieldState<String> createState() => _ValidatedFieldState();
}

class _ValidatedFieldState extends FormFieldState<String> {
  static const Duration _pause = Duration(milliseconds: 450);

  Timer? _timer;
  late final FocusNode _focus;
  late final bool _ownsFocus;
  String _lastText = '';
  bool _checked = false;

  ValidatedField get _w => widget as ValidatedField;

  @override
  void initState() {
    super.initState();
    _ownsFocus = _w.focusNode == null;
    _focus = _w.focusNode ?? FocusNode();
    _lastText = _w.controller.text;
    _focus.addListener(_onFocus);
    _w.controller.addListener(_onText);
  }

  void _onText() {
    final text = _w.controller.text;
    if (text == _lastText) return; // selection change only
    _lastText = text;
    _timer?.cancel();
    if (hasError) {
      _check(); // fix-as-you-type: clear the message the moment it is valid
    } else {
      _timer = Timer(_pause, _check);
    }
  }

  void _onFocus() {
    if (!_focus.hasFocus && (_checked || _w.controller.text.isNotEmpty)) {
      _timer?.cancel();
      _check();
    }
  }

  void _check() {
    if (!mounted) return;
    _checked = true;
    validate();
  }

  @override
  void reset() {
    _timer?.cancel();
    _checked = false;
    super.reset();
  }

  @override
  void didUpdateWidget(covariant FormField<String> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = (oldWidget as ValidatedField).controller;
    if (old != _w.controller) {
      old.removeListener(_onText);
      _w.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.removeListener(_onFocus);
    _w.controller.removeListener(_onText);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  Widget _buildField() {
    final w = _w;
    final error = w.externalError ?? errorText;
    final isValid = w.showSuccess &&
        _checked &&
        error == null &&
        w.controller.text.trim().isNotEmpty;

    return TextField(
      controller: w.controller,
      focusNode: _focus,
      enabled: w.enabled,
      readOnly: w.readOnly,
      onTap: w.onTap,
      autofocus: w.autofocus,
      keyboardType: w.keyboardType,
      textInputAction: w.textInputAction,
      textCapitalization: w.textCapitalization,
      inputFormatters: w.inputFormatters,
      obscureText: w.obscureText,
      maxLength: w.maxLength,
      maxLines: w.obscureText ? 1 : w.maxLines,
      minLines: w.minLines,
      onChanged: w.onChanged,
      onSubmitted: w.onSubmitted,
      decoration: InputDecoration(
        hintText: w.hintText,
        labelText: w.labelText,
        helperText: w.helperText,
        helperMaxLines: 2,
        errorText: error,
        errorMaxLines: 3,
        counterText: '',
        prefixIcon: w.prefixIcon,
        suffixIcon: w.suffix ??
            (isValid ? Icon(Icons.check_circle, size: 20, color: AppColors.success) : null),
      ),
    );
  }
}

/// A live checklist of the password rules: each line turns green as the rule
/// is met while the person types.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final checks = Validators.passwordChecks(value.text);
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in checks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          c.met ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 14,
                          color: c.met ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: c.met ? AppColors.success : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
