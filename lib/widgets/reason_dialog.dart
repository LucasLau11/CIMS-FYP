import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'common/validated_field.dart';

/// Asks the person for a written reason or comment, validated live.
///
/// Used wherever a decision must be explained to someone else: rejecting a
/// report or application, cancelling or rescheduling an interview. When
/// [reasonRequired] is true the reason must be at least [minLength]
/// characters, so "no" or "x" cannot be submitted as an explanation. Returns
/// the trimmed text, or `null` if the dialog was cancelled.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String prompt,
  required String confirmLabel,
  bool reasonRequired = true,
  int minLength = kMinReasonLength,
  int maxLength = 500,
  String? hintText,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ReasonDialog(
      title: title,
      prompt: prompt,
      confirmLabel: confirmLabel,
      reasonRequired: reasonRequired,
      minLength: minLength,
      maxLength: maxLength,
      hintText: hintText,
      destructive: destructive,
    ),
  );
}

class ReasonDialog extends StatefulWidget {
  const ReasonDialog({
    super.key,
    required this.title,
    required this.prompt,
    required this.confirmLabel,
    this.reasonRequired = true,
    this.minLength = kMinReasonLength,
    this.maxLength = 500,
    this.hintText,
    this.destructive = false,
  });

  final String title;
  final String prompt;
  final String confirmLabel;
  final bool reasonRequired;
  final int minLength;
  final int maxLength;
  final String? hintText;
  final bool destructive;

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) => Validators.text(
        value,
        field: 'The reason',
        required: widget.reasonRequired,
        min: widget.reasonRequired ? widget.minLength : 0,
        max: widget.maxLength,
      );

  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirmColor = widget.destructive ? AppColors.error : AppColors.primary;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.title, style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.prompt, style: AppTextStyles.bodySecondary),
              const SizedBox(height: 12),
              ValidatedField(
                controller: _controller,
                fieldValidator: _validate,
                maxLines: 4,
                maxLength: widget.maxLength,
                showSuccess: false,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                hintText: widget.hintText ?? l10n.supTypeYourComment,
                helperText: widget.reasonRequired
                    ? l10n.reasonRequiredHelper(widget.minLength)
                    : l10n.reasonOptionalHelper,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${value.text.trim().length} / ${widget.maxLength}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
