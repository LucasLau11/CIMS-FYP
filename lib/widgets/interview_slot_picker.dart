import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/interview_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../utils/interview_format.dart';
import '../utils/responsive.dart';
import '../utils/validators.dart';
import 'common/validated_field.dart';

/// Lets the person pick one free interview time: a row of days that still have
/// free slots, then the times on the chosen day. Only real free slots are
/// offered, so an unavailable or already booked time cannot be picked.
class InterviewSlotPicker extends StatefulWidget {
  const InterviewSlotPicker({
    super.key,
    required this.loadSlots,
    required this.onChanged,
    this.emptyAction,
    this.days = 28,
  });

  final Future<List<InterviewSlot>> Function(DateTime from, DateTime to) loadSlots;
  final ValueChanged<InterviewSlot?> onChanged;

  /// Shown under the "no free slots" message, e.g. a button to set availability.
  final Widget? emptyAction;
  final int days;

  @override
  State<InterviewSlotPicker> createState() => _InterviewSlotPickerState();
}

class _InterviewSlotPickerState extends State<InterviewSlotPicker> {
  bool _loading = true;
  String? _error;
  final Map<DateTime, List<InterviewSlot>> _byDay = {};
  DateTime? _day;
  InterviewSlot? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = DateTime.now();
      final slots = await widget.loadSlots(today, today.add(Duration(days: widget.days)));
      final grouped = <DateTime, List<InterviewSlot>>{};
      for (final s in slots) {
        grouped.putIfAbsent(DateTime(s.start.year, s.start.month, s.start.day), () => []).add(s);
      }
      if (!mounted) return;
      setState(() {
        _byDay
          ..clear()
          ..addAll(grouped);
        _day = grouped.isEmpty ? null : (grouped.keys.toList()..sort()).first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)!.ivTryAgain)),
        ],
      );
    }
    if (_byDay.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.ivNoFreeTimes(widget.days),
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.ivNoFreeTimesHint,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.warning)),
            if (widget.emptyAction != null) ...[const SizedBox(height: 8), widget.emptyAction!],
          ],
        ),
      );
    }

    final days = _byDay.keys.toList()..sort();
    final times = _byDay[_day] ?? const <InterviewSlot>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.ivChooseDay, style: AppTextStyles.label),
        const SizedBox(height: 8),
        SizedBox(
          height: scaledExtent(context, 84, textShare: 1.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = days[i];
              final selected = d == _day;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _day = d;
                    _selected = null;
                  });
                  widget.onChanged(null);
                },
                child: Container(
                  width: 78,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(formatInterviewWeekdayShort(d),
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: selected ? kOnBannerSoft : AppColors.textMuted)),
                      Text(formatInterviewDayMonth(d),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textPrimary)),
                      Text(AppLocalizations.of(context)!.ivSlotsFree(_byDay[d]!.length),
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: selected ? kOnBannerSoft : AppColors.textMuted)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(AppLocalizations.of(context)!.ivChooseTime, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in times)
              ChoiceChip(
                label: Text(formatInterviewTime(s.start)),
                selected: _selected?.start == s.start,
                onSelected: (_) {
                  setState(() => _selected = s);
                  widget.onChanged(s);
                },
              ),
          ],
        ),
        if (_selected != null) ...[
          const SizedBox(height: 8),
          Text('${formatInterviewDateTime(_selected!.start)} · ${_selected!.minutes} minutes',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
        ],
      ],
    );
  }
}

/// Bottom sheet for moving an interview: pick a new free time and give the
/// reason, which the other side will see. Returns true once the change is made.
Future<bool> showRescheduleSheet(
  BuildContext context, {
  required Future<List<InterviewSlot>> Function(DateTime from, DateTime to) loadSlots,
  required Future<void> Function(InterviewSlot slot, String reason) onSubmit,
  required String otherParty,
  Widget? emptyAction,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _RescheduleSheet(loadSlots: loadSlots, onSubmit: onSubmit, otherParty: otherParty, emptyAction: emptyAction),
  );
  return done == true;
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.loadSlots, required this.onSubmit, required this.otherParty, this.emptyAction});

  final Future<List<InterviewSlot>> Function(DateTime from, DateTime to) loadSlots;
  final Future<void> Function(InterviewSlot slot, String reason) onSubmit;
  final String otherParty;
  final Widget? emptyAction;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  InterviewSlot? _slot;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_slot == null) {
      setState(() => _error = AppLocalizations.of(context)!.ivPickFirst);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_slot!, _reason.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: Text(AppLocalizations.of(context)!.ivRequestNewTime, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: _busy ? null : () => Navigator.pop(context, false)),
              ],
            ),
            const SizedBox(height: 12),
            InterviewSlotPicker(loadSlots: widget.loadSlots, emptyAction: widget.emptyAction, onChanged: (s) => setState(() => _slot = s)),
            const SizedBox(height: 18),
            Text(AppLocalizations.of(context)!.ivReasonForChange, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.ivWillSeeReason(widget.otherParty), style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: ValidatedField(
                controller: _reason,
                fieldValidator: (v) => Validators.text(v, field: 'The reason', min: kMinReasonLength, max: 500),
                maxLines: 3,
                maxLength: 500,
                showSuccess: false,
                hintText: AppLocalizations.of(context)!.ivReasonHint,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(AppLocalizations.of(context)!.ivSendRequest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
